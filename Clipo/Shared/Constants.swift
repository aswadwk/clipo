import Foundation

enum Constants {
    static let appName = "Clipo"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    enum UI {
        static let popoverWidth: CGFloat = 360
        static let popoverHeight: CGFloat = 500
        static let rowSpacing: CGFloat = 3
        static let cornerRadius: CGFloat = 10
    }

    enum Monitor {
        static let pollInterval: TimeInterval = 0.5
    }
}
