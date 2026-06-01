import Foundation

struct SpeechAnalyzer {
    private let fillerExpressions = [
        "um",
        "uh",
        "erm",
        "ah",
        "like",
        "basically",
        "actually",
        "literally",
        "you know",
        "i mean",
        "sort of",
        "kind of"
    ]

    func analyze(
        transcript: String,
        focus: PracticeFocus,
        duration: TimeInterval,
        segments: [TranscriptSegment],
        volumeSamples: [Double],
        acousticMetrics: AcousticMetrics?
    ) -> (metrics: SessionMetrics, recommendations: [String]) {
        let words = words(in: transcript)
        let wordCount = words.count
        let minutes = max(duration / 60, 0.1)
        let wordsPerMinute = Double(wordCount) / minutes
        let fillerCount = countFillers(in: transcript)
        let fillerWordsPerMinute = Double(fillerCount) / minutes
        let pauses = pauseDurations(from: segments)
        let averagePause = pauses.isEmpty ? 0 : pauses.reduce(0, +) / Double(pauses.count)
        let longestPause = pauses.max() ?? 0
        let uniqueWordRatio = uniqueRatio(words)
        let volumeStats = volumeStatistics(volumeSamples)
        let acousticVolumeConsistency = acousticMetrics.map {
            max(0, min(100, 100 - $0.energyVariation * 120))
        }
        let effectiveVolumeConsistency = acousticVolumeConsistency ?? volumeStats.consistency
        let effectiveEnergyVariation = acousticMetrics?.energyVariation ?? volumeStats.variation

        let paceScore = scoreAroundTarget(wordsPerMinute, target: 145, tolerance: 45)
        let fillerScore = clamp(100 - Int((fillerWordsPerMinute * 13).rounded()))
        let pauseScore = pauseScore(average: averagePause, longest: longestPause)
        let volumeScore = Int(effectiveVolumeConsistency.rounded())
        let lexicalScore = clamp(Int((uniqueWordRatio * 100).rounded()))

        let clarity = weightedScore([
            (paceScore, 0.32),
            (fillerScore, 0.32),
            (pauseScore, 0.18),
            (lexicalScore, 0.18)
        ])

        let confidence = weightedScore([
            (paceScore, 0.25),
            (volumeScore, 0.30),
            (fillerScore, 0.25),
            (speechDensityScore(wordCount: wordCount, duration: duration), 0.20)
        ])

        let executivePresence = executivePresenceScore(transcript: transcript, focus: focus, fillerScore: fillerScore)
        let storytelling = storytellingScore(transcript: transcript, focus: focus)

        let overall = weightedScore([
            (confidence, 0.28),
            (clarity, 0.30),
            (executivePresence, 0.25),
            (storytelling, 0.17)
        ])

        let metrics = SessionMetrics(
            overallScore: overall,
            confidenceScore: confidence,
            clarityScore: clarity,
            executivePresenceScore: executivePresence,
            storytellingScore: storytelling,
            wordsPerMinute: wordsPerMinute,
            fillerWordCount: fillerCount,
            fillerWordsPerMinute: fillerWordsPerMinute,
            averagePause: averagePause,
            longestPause: longestPause,
            volumeConsistency: effectiveVolumeConsistency,
            energyVariation: effectiveEnergyVariation,
            wordCount: wordCount,
            uniqueWordRatio: uniqueWordRatio
        )

        return (metrics, recommendations(for: metrics, focus: focus, transcript: transcript))
    }

    private func words(in transcript: String) -> [String] {
        let pattern = #"[A-Za-z']+"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsRange = NSRange(transcript.startIndex..<transcript.endIndex, in: transcript)
        return regex.matches(in: transcript, range: nsRange).compactMap { match in
            guard let range = Range(match.range, in: transcript) else { return nil }
            return String(transcript[range]).lowercased()
        }
    }

    private func countFillers(in transcript: String) -> Int {
        let normalized = " " + transcript.lowercased()
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: ".", with: " ")
            .replacingOccurrences(of: ",", with: " ")
            .replacingOccurrences(of: "?", with: " ")
            .replacingOccurrences(of: "!", with: " ")
            + " "

        return fillerExpressions.reduce(0) { total, expression in
            let needle = " " + expression + " "
            return total + normalized.components(separatedBy: needle).count - 1
        }
    }

    private func pauseDurations(from segments: [TranscriptSegment]) -> [Double] {
        guard segments.count > 1 else { return [] }
        let sorted = segments.sorted { $0.timestamp < $1.timestamp }
        return zip(sorted, sorted.dropFirst()).compactMap { current, next in
            let gap = next.timestamp - (current.timestamp + current.duration)
            return gap > 0.2 ? gap : nil
        }
    }

    private func uniqueRatio(_ words: [String]) -> Double {
        guard !words.isEmpty else { return 0 }
        return Double(Set(words).count) / Double(words.count)
    }

    private func volumeStatistics(_ samples: [Double]) -> (consistency: Double, variation: Double) {
        guard samples.count > 4 else { return (72, 0.24) }
        let mean = samples.reduce(0, +) / Double(samples.count)
        guard mean > 0 else { return (60, 0.4) }
        let variance = samples.reduce(0) { $0 + pow($1 - mean, 2) } / Double(samples.count)
        let standardDeviation = sqrt(variance)
        let variation = standardDeviation / mean
        let consistency = max(0, min(100, 100 - variation * 120))
        return (consistency, variation)
    }

    private func scoreAroundTarget(_ value: Double, target: Double, tolerance: Double) -> Int {
        let distance = abs(value - target)
        let score = 100 - (distance / tolerance * 100)
        return clamp(Int(score.rounded()))
    }

    private func pauseScore(average: Double, longest: Double) -> Int {
        if average == 0 && longest == 0 {
            return 70
        }
        let averagePenalty: Double
        if average < 0.25 {
            averagePenalty = 12
        } else if average > 1.25 {
            averagePenalty = min(35, (average - 1.25) * 20)
        } else {
            averagePenalty = 0
        }
        let longestPenalty = max(0, min(30, (longest - 2.5) * 10))
        return clamp(Int((100 - averagePenalty - longestPenalty).rounded()))
    }

    private func speechDensityScore(wordCount: Int, duration: TimeInterval) -> Int {
        guard duration > 10 else { return 65 }
        let wordsPerSecond = Double(wordCount) / duration
        return clamp(Int(min(100, wordsPerSecond / 2.4 * 100).rounded()))
    }

    private func executivePresenceScore(transcript: String, focus: PracticeFocus, fillerScore: Int) -> Int {
        let lowercased = transcript.lowercased()
        let firstSentence = lowercased.components(separatedBy: CharacterSet(charactersIn: ".?!")).first ?? lowercased
        let conclusionMarkers = ["main", "key", "because", "there are", "my recommendation", "the answer", "in short"]
        let structureMarkers = ["first", "second", "third", "three", "two", "reason", "therefore", "so the takeaway"]

        var score = 48
        if conclusionMarkers.contains(where: { firstSentence.contains($0) }) {
            score += 18
        }
        score += min(18, structureMarkers.filter { lowercased.contains($0) }.count * 6)
        score += min(8, max(0, transcript.count / 160))
        score += focus == .leadershipDiscussion || focus == .startupPitch ? 4 : 0
        score += Int(Double(fillerScore) * 0.12)
        return clamp(score)
    }

    private func storytellingScore(transcript: String, focus: PracticeFocus) -> Int {
        let lowercased = transcript.lowercased()
        let exampleMarkers = ["for example", "for instance", "imagine", "when", "then", "before", "after", "customer", "user", "team"]
        let contrastMarkers = ["but", "however", "instead", "because", "therefore"]

        var score = 45
        score += min(24, exampleMarkers.filter { lowercased.contains($0) }.count * 6)
        score += min(16, contrastMarkers.filter { lowercased.contains($0) }.count * 4)
        score += lowercased.count > 350 ? 10 : 0
        score += focus == .researchPresentation || focus == .socialConversation ? 4 : 0
        return clamp(score)
    }

    private func recommendations(for metrics: SessionMetrics, focus: PracticeFocus, transcript: String) -> [String] {
        var output: [String] = []

        if metrics.wordsPerMinute > 170 {
            output.append("Slow the pace by 10 to 15 percent, especially around technical claims.")
        } else if metrics.wordsPerMinute < 105 && metrics.wordCount > 20 {
            output.append("Add more forward momentum. Aim for 125 to 155 words per minute.")
        }

        if metrics.fillerWordsPerMinute > 2.5 {
            output.append("Replace filler words with short silent pauses.")
        }

        if metrics.longestPause > 3 {
            output.append("Use a signpost phrase before long transitions so the pause feels intentional.")
        }

        if metrics.volumeConsistency < 68 {
            output.append("Keep your distance from the microphone steady and finish sentences with the same vocal energy.")
        }

        if metrics.executivePresenceScore < 70 {
            output.append("Start with the conclusion, then give two or three supporting points.")
        }

        if metrics.storytellingScore < 68 {
            switch focus {
            case .technicalInterview:
                output.append("Add a concrete tradeoff or example after the core technical answer.")
            case .researchPresentation:
                output.append("Anchor the explanation in the research question before moving into details.")
            case .startupPitch:
                output.append("Name the user pain, then show the outcome in one specific scenario.")
            case .leadershipDiscussion:
                output.append("Frame the decision, the constraint, and the next action.")
            case .socialConversation:
                output.append("Add one vivid personal detail so the answer feels less abstract.")
            }
        }

        if transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            output.append("Transcription was empty. Check speech permission and try a quieter environment.")
        }

        if output.isEmpty {
            output.append("Strong session. Keep the same pace and make the opening sentence even more decisive.")
        }

        return Array(output.prefix(4))
    }

    private func weightedScore(_ parts: [(Int, Double)]) -> Int {
        let totalWeight = parts.reduce(0) { $0 + $1.1 }
        guard totalWeight > 0 else { return 0 }
        let score = parts.reduce(0) { $0 + Double($1.0) * $1.1 } / totalWeight
        return clamp(Int(score.rounded()))
    }

    private func clamp(_ value: Int) -> Int {
        min(100, max(0, value))
    }
}
