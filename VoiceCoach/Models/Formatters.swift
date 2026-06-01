import Foundation

extension TimeInterval {
    var compactDuration: String {
        let totalSeconds = Int(self.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }

    var shortPracticeTime: String {
        let minutes = Int((self / 60).rounded())
        if minutes < 60 {
            return "\(minutes)m"
        }
        let hours = minutes / 60
        let remainder = minutes % 60
        return remainder == 0 ? "\(hours)h" : "\(hours)h \(remainder)m"
    }
}

extension Double {
    var oneDecimal: String {
        String(format: "%.1f", self)
    }

    var wholeNumber: String {
        String(format: "%.0f", self)
    }
}

extension Date {
    var sessionLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    var shortDayLabel: String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        return formatter.string(from: self)
    }
}
