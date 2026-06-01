import AVFoundation
import Combine
import Foundation
import Speech

@MainActor
final class RecordingManager: ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var transcript = ""
    @Published private(set) var elapsedTime: TimeInterval = 0
    @Published private(set) var audioLevel: Double = 0
    @Published var errorMessage: String?

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en_US"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioFile: AVAudioFile?
    private var recordingStartDate: Date?
    private var timer: Timer?
    private var latestSegments: [TranscriptSegment] = []
    private var volumeSamples: [Double] = []
    private var audioURL: URL?
    private let analyzer = SpeechAnalyzer()
    private enum RecordingError: LocalizedError {
        case speechUnavailable

        var errorDescription: String? {
            "Speech recognition is not available right now."
        }
    }

    func requestPermissions() async -> Bool {
        async let speechAllowed = requestSpeechPermission()
        async let microphoneAllowed = requestMicrophonePermission()
        let allowed = await speechAllowed && microphoneAllowed
        if !allowed {
            errorMessage = "Microphone and speech recognition permissions are required."
        }
        return allowed
    }

    func startRecording() async {
        guard !isRecording else { return }
        guard await requestPermissions() else { return }

        resetSessionState()

        do {
            try configureAudioSession()
            try configureRecognition()
            try startAudioEngine()
            startTimer()
            isRecording = true
        } catch {
            errorMessage = error.localizedDescription
            stopAudio()
        }
    }

    func stopRecording(focus: PracticeFocus) -> SpeechSession? {
        guard isRecording else { return nil }

        recognitionRequest?.endAudio()
        stopAudio()
        isRecording = false

        let duration = max(elapsedTime, Date().timeIntervalSince(recordingStartDate ?? .now))
        let analysis = analyzer.analyze(
            transcript: transcript,
            focus: focus,
            duration: duration,
            segments: latestSegments,
            volumeSamples: volumeSamples
        )

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        let date = Date()
        let session = SpeechSession(
            title: "\(focus.rawValue) - \(formatter.string(from: date))",
            focus: focus,
            date: date,
            duration: duration,
            transcript: transcript.trimmingCharacters(in: .whitespacesAndNewlines),
            segments: latestSegments,
            metrics: analysis.metrics,
            recommendations: analysis.recommendations,
            audioFileName: audioURL?.lastPathComponent
        )

        return session
    }

    private func resetSessionState() {
        transcript = ""
        elapsedTime = 0
        audioLevel = 0
        errorMessage = nil
        latestSegments = []
        volumeSamples = []
        recordingStartDate = Date()
        audioURL = recordingURL()
    }

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try session.setActive(true)
    }

    private func configureRecognition() throws {
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            throw RecordingError.speechUnavailable
        }

        recognitionTask?.cancel()
        recognitionTask = nil

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if speechRecognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        recognitionRequest = request

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                    self.latestSegments = result.bestTranscription.segments.map {
                        TranscriptSegment(
                            text: $0.substring,
                            timestamp: $0.timestamp,
                            duration: $0.duration
                        )
                    }
                }

                if let error {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func startAudioEngine() throws {
        guard let recognitionRequest else { return }
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        if let audioURL {
            audioFile = try? AVAudioFile(forWriting: audioURL, settings: format.settings)
        }

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            recognitionRequest.append(buffer)
            try? self?.audioFile?.write(from: buffer)

            let level = Self.normalizedAudioLevel(from: buffer)
            Task { @MainActor in
                self?.audioLevel = level
                self?.volumeSamples.append(level)
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let start = self.recordingStartDate else { return }
                self.elapsedTime = Date().timeIntervalSince(start)
            }
        }
    }

    private func stopAudio() {
        timer?.invalidate()
        timer = nil

        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        recognitionTask?.finish()
        recognitionTask = nil
        recognitionRequest = nil
        audioFile = nil

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func requestSpeechPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                continuation.resume(returning: allowed)
            }
        }
    }

    private func recordingURL() -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "session-\(UUID().uuidString).caf"
        return documents.appendingPathComponent(fileName)
    }

    nonisolated private static func normalizedAudioLevel(from buffer: AVAudioPCMBuffer) -> Double {
        guard let channel = buffer.floatChannelData?[0] else { return 0 }
        let count = Int(buffer.frameLength)
        guard count > 0 else { return 0 }

        let samples = UnsafeBufferPointer(start: channel, count: count)
        let sumSquares = samples.reduce(0) { $0 + Double($1 * $1) }
        let rms = sqrt(sumSquares / Double(count))
        let decibels = 20 * log10(max(rms, 0.000_001))
        return max(0, min(1, (decibels + 60) / 60))
    }
}
