import Foundation
import Testing
@testable import PomodoroCore

@Suite("Appearance")
struct AppearanceTests {
    @Test("Existing installs retain Original colors and System appearance")
    func defaultsAndRoundTrip() {
        let defaults = makeDefaults()
        let settings = PomodoroSettings(defaults: defaults)
        #expect(settings.theme == ThemeConfiguration())
        var theme = settings.theme
        theme.preset = .hancock
        theme.appearance = .dark
        theme.surfaceStrength = 0.35
        settings.theme = theme
        #expect(PomodoroSettings(defaults: defaults).theme == theme)
    }

    @Test("Each character has exactly one matching palette")
    func roster() {
        for character in PomodoroCharacter.allCases where character != .none {
            let matches = ThemePreset.allCases.filter { $0.character == character }
            #expect(matches.count == 1)
            #expect(matches.first == ThemePreset.matching(character))
        }
        #expect(ThemePreset.matching(.none) == nil)
        #expect(ThemePreset.allCases.map(\.palette).filter { $0 != ThemePreset.classic.palette }.count == PomodoroCharacter.allCases.filter { $0 != .none }.count)
    }

    @Test("Custom colors survive trying presets and persist independently of the character")
    func savedCustomPalette() {
        let defaults = makeDefaults()
        let settings = PomodoroSettings(defaults: defaults)
        settings.character = .ninja
        var theme = ThemeConfiguration()
        theme.preset = .samurai
        theme.customize { colors in
            colors[.focus] = PhaseColors(tint: ThemeColor(0xAABBCC))
            colors.surface = ThemeColor(0x102030)
        }
        let custom = theme.palette
        #expect(theme.preset == .custom)
        #expect(custom.shortBreak == ThemePreset.samurai.palette.shortBreak)
        theme.preset = .hancock
        settings.theme = theme
        var recovered = PomodoroSettings(defaults: defaults).theme
        recovered.preset = .custom
        #expect(recovered.palette == custom)
        #expect(settings.character == .ninja)
    }

    @Test("Corrupt and future preferences fall back without touching other settings")
    func malformedPreferences() throws {
        let defaults = makeDefaults()
        let settings = PomodoroSettings(defaults: defaults)
        settings.focusMinutes = 45
        for json in ["not json", "{\"version\":999}", "{\"preset\":\"future\",\"appearance\":\"future\"}"] {
            defaults.set(Data(json.utf8), forKey: PomodoroSettings.Key.themeConfiguration.rawValue)
            #expect(settings.theme == ThemeConfiguration())
            #expect(settings.focusMinutes == 45)
        }
        let invalidColor = Data("16777216".utf8)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(ThemeColor.self, from: invalidColor) }
    }

    @Test("Tint strength is bounded in both edits and stored data")
    func strength() throws {
        var theme = ThemeConfiguration()
        theme.surfaceStrength = -2
        #expect(theme.surfaceStrength == 0)
        theme.surfaceStrength = 8
        #expect(theme.surfaceStrength == 1)
        theme.surfaceStrength = .nan
        #expect(theme.surfaceStrength == 1)
        let data = Data("{\"strength\":-20}".utf8)
        #expect(try JSONDecoder().decode(ThemeConfiguration.self, from: data).surfaceStrength == 0)
    }

    @Test("Appearance emits its own callback, without triggering timer or music settings")
    func separateCallback() {
        let settings = PomodoroSettings(defaults: makeDefaults())
        var timerCallbacks = 0
        var appearanceCallbacks = 0
        settings.onChange = { timerCallbacks += 1 }
        settings.onAppearanceChange = { appearanceCallbacks += 1 }
        var theme = settings.theme
        theme.preset = .rabbit
        settings.theme = theme
        #expect(timerCallbacks == 0)
        #expect(appearanceCallbacks == 1)
    }

    @Test("Very light and dark choices keep text readable in both appearances")
    func contrast() {
        let colors = [0x000000, 0xFFFFFF, 0xF5A8B8, 0xF7B731, 0x2F4A7A, 0xB8263A, 0x777777].map { ThemeColor(UInt32($0)) }
        for color in colors {
            #expect(color.contrast(with: color.contrastingInk) >= 4.5)
            for background in [ThemeColor(0xF5F5F5), ThemeColor(0x242424)] {
                #expect(color.legible(on: background).contrast(with: background) >= 4.5)
            }
            let phase = PhaseColors(tint: color)
            #expect(phase.highlight.contrast(with: color.contrastingInk) >= 4.5)
        }
    }

    @Test("Widget snapshots carry the theme, while old and corrupt appearance data preserve the timer")
    func snapshotCompatibility() throws {
        var theme = ThemeConfiguration()
        theme.preset = .power
        theme.appearance = .dark
        let snapshot = TimerSnapshot(phase: .shortBreak, isRunning: true,
                                     deadline: Date(timeIntervalSinceReferenceDate: 123456), theme: theme)
        let encoded = try JSONEncoder().encode(snapshot)
        #expect(try JSONDecoder().decode(TimerSnapshot.self, from: encoded) == snapshot)
        var object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object.removeValue(forKey: "theme")
        let old = try JSONDecoder().decode(TimerSnapshot.self, from: JSONSerialization.data(withJSONObject: object))
        #expect(old.theme == nil)
        #expect(old.deadline == snapshot.deadline && old.phase == .shortBreak && old.isRunning)
        object["theme"] = ["version": 999]
        let corrupt = try JSONDecoder().decode(TimerSnapshot.self, from: JSONSerialization.data(withJSONObject: object))
        #expect(corrupt.theme == nil)
        #expect(corrupt.deadline == snapshot.deadline && corrupt.isRunning)
    }
}
