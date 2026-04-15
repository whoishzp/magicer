import AppKit
import Foundation

struct OffWorkShortcut: Codable, Equatable {
    var key: String   // lowercased key character, e.g. "d"
    var modifiers: UInt  // NSEvent.ModifierFlags.rawValue

    var displayString: String {
        var s = ""
        let flags = NSEvent.ModifierFlags(rawValue: modifiers)
        if flags.contains(.control) { s += "⌃" }
        if flags.contains(.option)  { s += "⌥" }
        if flags.contains(.shift)   { s += "⇧" }
        if flags.contains(.command) { s += "⌘" }
        s += key.uppercased()
        return s
    }

    func matches(_ event: NSEvent) -> Bool {
        let relevant: NSEvent.ModifierFlags = [.command, .shift, .option, .control]
        let eventMods = event.modifierFlags.intersection(relevant)
        let ourMods   = NSEvent.ModifierFlags(rawValue: modifiers).intersection(relevant)
        guard eventMods == ourMods else { return false }
        let char = event.charactersIgnoringModifiers?.lowercased() ?? ""
        return char == key.lowercased()
    }
}
