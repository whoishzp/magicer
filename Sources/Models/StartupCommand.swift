import Foundation

struct StartupCommand: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var label: String
    var command: String
    var isEnabled: Bool = true
}
