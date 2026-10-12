import Foundation

/// An opaque sRGB color, portable between the app, widgets, and preferences.
public struct ThemeColor: Codable, Equatable, Sendable {
    public let hex: UInt32
    public init(_ hex: UInt32) { self.hex = hex & 0xFFFFFF }
    public var red: Double { Double((hex >> 16) & 255) / 255 }
    public var green: Double { Double((hex >> 8) & 255) / 255 }
    public var blue: Double { Double(hex & 255) / 255 }
    public var hexString: String { String(format: "#%06X", hex) }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(UInt32.self)
        guard value <= 0xFFFFFF else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid RGB color")
        }
        hex = value
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(hex)
    }

    public func mixed(with other: Self, amount: Double) -> Self {
        let fraction = min(max(amount, 0), 1)
        func channel(_ a: Double, _ b: Double) -> UInt32 {
            UInt32(((a + (b - a) * fraction) * 255).rounded())
        }
        return Self(channel(red, other.red) << 16 | channel(green, other.green) << 8 | channel(blue, other.blue))
    }

    public var luminance: Double {
        func linear(_ value: Double) -> Double {
            value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    public func contrast(with other: Self) -> Double {
        (max(luminance, other.luminance) + 0.05) / (min(luminance, other.luminance) + 0.05)
    }

    /// Text and glyphs on opaque accent buttons always get the more legible ink.
    public var contrastingInk: Self {
        contrast(with: Self(0xFFFFFF)) >= contrast(with: Self(0)) ? Self(0xFFFFFF) : Self(0)
    }

    /// Keep the chosen hue for decoration; adjust only small text on neutral surfaces.
    public func legible(on background: Self) -> Self {
        guard contrast(with: background) < 4.5 else { return self }
        let target = background.contrastingInk
        var lower = 0.0
        var upper = 1.0
        for _ in 0..<12 {
            let mid = (lower + upper) / 2
            if mixed(with: target, amount: mid).contrast(with: background) >= 4.5 { upper = mid }
            else { lower = mid }
        }
        return mixed(with: target, amount: upper)
    }
}

public struct PhaseColors: Codable, Equatable, Sendable {
    public var tint: ThemeColor
    public var highlight: ThemeColor
    public init(_ tint: UInt32, _ highlight: UInt32) {
        self.tint = ThemeColor(tint)
        self.highlight = ThemeColor(highlight)
    }
    public init(tint: ThemeColor) {
        self.tint = tint
        let white = ThemeColor(0xFFFFFF)
        var amount = 0.28
        // When white ink is needed, keep both ends of the gradient readable.
        if tint.contrastingInk == white {
            while amount > 0 && tint.mixed(with: white, amount: amount).contrast(with: white) < 4.5 {
                amount = max(0, amount - 0.01)
            }
        }
        highlight = tint.mixed(with: white, amount: amount)
    }
}

public struct ThemePalette: Codable, Equatable, Sendable {
    public var focus: PhaseColors
    public var shortBreak: PhaseColors
    public var longBreak: PhaseColors
    /// nil uses the current phase color, preserving the original app's glass wash.
    public var surface: ThemeColor?

    public init(focus: PhaseColors, shortBreak: PhaseColors, longBreak: PhaseColors, surface: ThemeColor? = nil) {
        self.focus = focus
        self.shortBreak = shortBreak
        self.longBreak = longBreak
        self.surface = surface
    }

    public subscript(phase: Phase) -> PhaseColors {
        get {
            switch phase {
            case .focus: focus
            case .shortBreak: shortBreak
            case .longBreak: longBreak
            }
        }
        set {
            switch phase {
            case .focus: focus = newValue
            case .shortBreak: shortBreak = newValue
            case .longBreak: longBreak = newValue
            }
        }
    }
}

public enum ThemePreset: String, Codable, CaseIterable, Identifiable, Sendable {
    case classic, samurai, ninja, rabbit, power, general, hancock, nel, custom
    public var id: String { rawValue }
    public var name: String {
        switch self {
        case .classic: "Original"
        case .samurai: "Samurai"
        case .ninja: "Ninja"
        case .rabbit: "Rabbit Suit Guy"
        case .power: "Power"
        case .general: "The General"
        case .hancock: "Boa Hancock"
        case .nel: "Nel"
        case .custom: "Custom"
        }
    }
    public var detail: String {
        switch self {
        case .classic: "The familiar palette"
        case .samurai: "Vermilion · gold · steel"
        case .ninja: "Indigo · jade · silver"
        case .rabbit: "Rose · cream · cocoa"
        case .power: "Scarlet · amber · navy"
        case .general: "Olive · brass · slate"
        case .hancock: "Crimson · gold · royal blue"
        case .nel: "Mint · sage · warm ivory"
        case .custom: "Your saved colors"
        }
    }
    public var character: PomodoroCharacter? {
        switch self {
        case .samurai: .samurai
        case .ninja: .ninja
        case .rabbit: .rabbit
        case .power: .animeGirl
        case .general: .general
        case .hancock: .hancock
        case .nel: .nel
        default: nil
        }
    }
    public static func matching(_ character: PomodoroCharacter) -> Self? {
        allCases.first { $0.character == character }
    }
    public var palette: ThemePalette {
        // The original decimal components are rounded to their nearest sRGB byte.
        if self == .classic || self == .custom {
            return ThemePalette(focus: PhaseColors(0xE84D42, 0xFA8C5C),
                                shortBreak: PhaseColors(0x33A887, 0x6BDBA8),
                                longBreak: PhaseColors(0x3D82D9, 0x78BDFA))
        }
        let colors: (UInt32, UInt32, UInt32)
        switch self {
        case .samurai: colors = (0xC13327, 0xF0B84B, 0x4C6B8E)
        case .ninja: colors = (0x56637C, 0x4E8578, 0xB7BEC6)
        case .rabbit: colors = (0xF5A8B8, 0xD1BEA1, 0x6B4A38)
        case .power: colors = (0xD9473A, 0xF7B731, 0x2F4A7A)
        case .general: colors = (0x6E7345, 0xC29B3C, 0x5C7086)
        case .hancock: colors = (0xB8263A, 0xD9A441, 0x3D5BA6)
        case .nel: colors = (0x52B8A8, 0x799D6E, 0xDFCDA4)
        default: colors = (0, 0, 0) // classic and custom returned above
        }
        return ThemePalette(focus: PhaseColors(tint: ThemeColor(colors.0)),
                            shortBreak: PhaseColors(tint: ThemeColor(colors.1)),
                            longBreak: PhaseColors(tint: ThemeColor(colors.2)))
    }
}

public enum ThemeAppearance: String, Codable, CaseIterable, Identifiable, Sendable {
    case system, light, dark
    public var id: String { rawValue }
    public var name: String { rawValue.capitalized }
}

/// One versioned local preference. Custom colors survive switching to a preset.
public struct ThemeConfiguration: Codable, Equatable, Sendable {
    public var preset: ThemePreset = .classic
    public var appearance: ThemeAppearance = .system
    public var customPalette: ThemePalette?
    private var strength: Double = 1
    public var surfaceStrength: Double {
        get { strength }
        set { strength = newValue.isFinite ? min(max(newValue, 0), 1) : 1 }
    }
    public var palette: ThemePalette { preset == .custom ? customPalette ?? .classic : preset.palette }
    public init() {}

    public mutating func customize(_ update: (inout ThemePalette) -> Void) {
        var colors = palette
        update(&colors)
        customPalette = colors
        preset = .custom
    }

    private enum CodingKeys: String, CodingKey { case version, preset, appearance, customPalette, strength }
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        guard version == 1 else {
            throw DecodingError.dataCorruptedError(forKey: .version, in: container, debugDescription: "Unknown theme version")
        }
        preset = ThemePreset(rawValue: try container.decodeIfPresent(String.self, forKey: .preset) ?? "") ?? .classic
        appearance = ThemeAppearance(rawValue: try container.decodeIfPresent(String.self, forKey: .appearance) ?? "") ?? .system
        customPalette = try? container.decode(ThemePalette.self, forKey: .customPalette)
        surfaceStrength = try container.decodeIfPresent(Double.self, forKey: .strength) ?? 1
    }
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(1, forKey: .version)
        try container.encode(preset.rawValue, forKey: .preset)
        try container.encode(appearance.rawValue, forKey: .appearance)
        try container.encodeIfPresent(customPalette, forKey: .customPalette)
        try container.encode(strength, forKey: .strength)
    }
}

private extension ThemePalette {
    static var classic: Self { ThemePreset.classic.palette }
}
