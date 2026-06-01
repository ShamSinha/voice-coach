import AVFoundation
import Foundation

struct AudioFeatureExtractor {
    private let frameDuration = 0.03
    private let hopDuration = 0.01
    private let silenceThresholdDB = -45.0
    private let minimumPitchHz = 75.0
    private let maximumPitchHz = 350.0

    func extract(from url: URL) throws -> AcousticMetrics {
        let file = try AVAudioFile(forReading: url)
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: file.processingFormat,
            frameCapacity: AVAudioFrameCount(file.length)
        ) else {
            throw AudioFeatureError.unreadableBuffer
        }

        try file.read(into: buffer)
        let samples = monoSamples(from: buffer)
        guard !samples.isEmpty else {
            throw AudioFeatureError.emptyAudio
        }

        let sampleRate = file.processingFormat.sampleRate
        let frameLength = max(1, Int(frameDuration * sampleRate))
        let hopLength = max(1, Int(hopDuration * sampleRate))
        let minLag = max(1, Int(sampleRate / maximumPitchHz))
        let maxLag = max(minLag + 1, Int(sampleRate / minimumPitchHz))

        var energies: [Double] = []
        var voicedEnergies: [Double] = []
        var pitchValues: [Double] = []
        var silentFrames = 0
        var totalFrames = 0

        var start = 0
        while start + frameLength < samples.count {
            let frame = Array(samples[start..<start + frameLength])
            let rms = rootMeanSquare(frame)
            let decibels = 20 * log10(max(rms, 0.000_001))
            let isSilent = decibels < silenceThresholdDB
            energies.append(rms)
            totalFrames += 1

            if isSilent {
                silentFrames += 1
            } else if let pitch = pitchHz(in: frame, sampleRate: sampleRate, minLag: minLag, maxLag: maxLag) {
                pitchValues.append(pitch)
                voicedEnergies.append(rms)
            }

            start += hopLength
        }

        let meanEnergy = mean(energies) ?? 0
        let energyVariation = coefficientOfVariation(energies)
        let silenceDuration = Double(silentFrames) * hopDuration
        let silenceRatio = totalFrames == 0 ? 0 : Double(silentFrames) / Double(totalFrames)

        return AcousticMetrics(
            meanPitchHz: mean(pitchValues),
            minPitchHz: pitchValues.min(),
            maxPitchHz: pitchValues.max(),
            jitterPercent: jitterPercent(from: pitchValues),
            shimmerPercent: shimmerPercent(from: voicedEnergies),
            silenceDuration: silenceDuration,
            silenceRatio: silenceRatio,
            meanEnergy: meanEnergy,
            energyVariation: energyVariation,
            voicedFrameCount: pitchValues.count,
            totalFrameCount: totalFrames
        )
    }

    private func monoSamples(from buffer: AVAudioPCMBuffer) -> [Float] {
        guard let channelData = buffer.floatChannelData else { return [] }
        let frameCount = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)
        guard frameCount > 0, channelCount > 0 else { return [] }

        if channelCount == 1 {
            return Array(UnsafeBufferPointer(start: channelData[0], count: frameCount))
        }

        var samples = [Float](repeating: 0, count: frameCount)
        for channelIndex in 0..<channelCount {
            let channel = UnsafeBufferPointer(start: channelData[channelIndex], count: frameCount)
            for frameIndex in 0..<frameCount {
                samples[frameIndex] += channel[frameIndex] / Float(channelCount)
            }
        }
        return samples
    }

    private func pitchHz(in frame: [Float], sampleRate: Double, minLag: Int, maxLag: Int) -> Double? {
        guard frame.count > maxLag + 2 else { return nil }

        var bestLag = 0
        var bestCorrelation = 0.0
        let upperLag = min(maxLag, frame.count - 2)

        for lag in minLag...upperLag {
            var correlation = 0.0
            var firstEnergy = 0.0
            var shiftedEnergy = 0.0

            for index in 0..<(frame.count - lag) {
                let first = Double(frame[index])
                let shifted = Double(frame[index + lag])
                correlation += first * shifted
                firstEnergy += first * first
                shiftedEnergy += shifted * shifted
            }

            let denominator = sqrt(firstEnergy * shiftedEnergy)
            guard denominator > 0 else { continue }
            let normalizedCorrelation = correlation / denominator
            if normalizedCorrelation > bestCorrelation {
                bestCorrelation = normalizedCorrelation
                bestLag = lag
            }
        }

        guard bestLag > 0, bestCorrelation > 0.35 else { return nil }
        return sampleRate / Double(bestLag)
    }

    private func rootMeanSquare(_ samples: [Float]) -> Double {
        guard !samples.isEmpty else { return 0 }
        let sumSquares = samples.reduce(0.0) { $0 + Double($1 * $1) }
        return sqrt(sumSquares / Double(samples.count))
    }

    private func jitterPercent(from pitchValues: [Double]) -> Double? {
        let periods = pitchValues.compactMap { pitch -> Double? in
            guard pitch > 0 else { return nil }
            return 1 / pitch
        }
        guard periods.count > 1 else { return nil }

        let absoluteDifferences = zip(periods, periods.dropFirst()).map { pair in
            abs(pair.0 - pair.1)
        }
        let averageDifference = mean(absoluteDifferences)
        let averagePeriod = mean(periods)
        guard let averageDifference, let averagePeriod, averagePeriod > 0 else { return nil }
        return averageDifference / averagePeriod * 100
    }

    private func shimmerPercent(from energies: [Double]) -> Double? {
        guard energies.count > 1 else { return nil }
        let absoluteDifferences = zip(energies, energies.dropFirst()).map { pair in
            abs(pair.0 - pair.1)
        }
        let averageDifference = mean(absoluteDifferences)
        let averageEnergy = mean(energies)
        guard let averageDifference, let averageEnergy, averageEnergy > 0 else { return nil }
        return averageDifference / averageEnergy * 100
    }

    private func mean(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private func coefficientOfVariation(_ values: [Double]) -> Double {
        guard let average = mean(values), average > 0 else { return 0 }
        let variance = values.reduce(0) { $0 + pow($1 - average, 2) } / Double(values.count)
        return sqrt(variance) / average
    }
}

private enum AudioFeatureError: LocalizedError {
    case emptyAudio
    case unreadableBuffer

    var errorDescription: String? {
        switch self {
        case .emptyAudio:
            return "The recording did not contain readable audio samples."
        case .unreadableBuffer:
            return "The recording could not be converted into an audio buffer."
        }
    }
}
