import AppKit
import Carbon
import Foundation

struct OffWorkShortcut: Equatable {
    var key: String      // lowercased character for display
    var modifiers: UInt  // NSEvent.ModifierFlags.rawValue
    var keyCode: UInt16  // virtual key code (same in NSEvent and Carbon)

    init(key: String, modifiers: UInt, keyCode: UInt16 = 0) {
        self.key = key
        self.modifiers = modifiers
        self.keyCode = keyCode
    }

    // MARK: - Display

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

    // MARK: - NSEvent matching (used for local monitor fallback)

    func matches(_ event: NSEvent) -> Bool {
        let relevant: NSEvent.ModifierFlags = [.command, .shift, .option, .control]
        let eventMods = event.modifierFlags.intersection(relevant)
        let ourMods   = NSEvent.ModifierFlags(rawValue: modifiers).intersection(relevant)
        guard eventMods == ourMods else { return false }
        // Prefer keyCode comparison when available
        if keyCode != 0 { return event.keyCode == keyCode }
        let char = event.charactersIgnoringModifiers?.lowercased() ?? ""
        return char == key.lowercased()
    }

    // MARK: - Carbon hot key

    var carbonModifiers: UInt32 {
        var mods: UInt32 = 0
        let flags = NSEvent.ModifierFlags(rawValue: modifiers)
        if flags.contains(.command) { mods |= UInt32(cmdKey) }
        if flags.contains(.shift)   { mods |= UInt32(shiftKey) }
        if flags.contains(.option)  { mods |= UInt32(optionKey) }
        if flags.contains(.control) { mods |= UInt32(controlKey) }
        return mods
    }

    /// True when Carbon registration is possible (has keyCode + at least one modifier).
    var hasCarbonSupport: Bool { keyCode != 0 && carbonModifiers != 0 }
}

// MARK: - Codable (manual, for backward-compatible keyCode field)

extension OffWorkShortcut: Codable {
    enum CodingKeys: String, CodingKey {
        case key, modifiers, keyCode
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        key      = try c.decode(String.self,  forKey: .key)
        modifiers = try c.decode(UInt.self,   forKey: .modifiers)
        keyCode  = (try? c.decodeIfPresent(UInt16.self, forKey: .keyCode)) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(key,       forKey: .key)
        try c.encode(modifiers, forKey: .modifiers)
        try c.encode(keyCode,   forKey: .keyCode)
    }
}
