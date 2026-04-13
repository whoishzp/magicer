import Foundation
import Combine

/// App-level settings (password protection for off-work black screen, etc.)
class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let kPassword = "ws_offwork_password"

    /// Password required to exit off-work black screen. Empty = no password.
    @Published var offWorkPassword: String {
        didSet { UserDefaults.standard.set(offWorkPassword, forKey: kPassword) }
    }

    private init() {
        offWorkPassword = UserDefaults.standard.string(forKey: "ws_offwork_password") ?? ""
    }

    var hasPassword: Bool { !offWorkPassword.trimmingCharacters(in: .whitespaces).isEmpty }
}
