import SwiftUI

enum Phase: String, CaseIterable, Identifiable, Hashable {
    case menstrual, follicular, ovulatory, luteal

    var id: String { rawValue }
    var name: String { rawValue }

    var season: String {
        switch self {
        case .menstrual: "inner winter"
        case .follicular: "inner spring"
        case .ovulatory: "inner summer"
        case .luteal: "inner autumn"
        }
    }

    /// clay · sage · marigold · plum
    var color: Color {
        switch self {
        case .menstrual: .dynamic(light: 0xB4523A, dark: 0xD9785E)
        case .follicular: .dynamic(light: 0x7E9466, dark: 0xA9C08E)
        case .ovulatory: .dynamic(light: 0xD99A2B, dark: 0xEDB851)
        case .luteal: .dynamic(light: 0x8A5A78, dark: 0xB88AA6)
        }
    }

    var seed: UInt64 {
        switch self {
        case .menstrual: 3
        case .follicular: 17
        case .ovulatory: 29
        case .luteal: 41
        }
    }

    var content: PhaseContent { Library.content(for: self) }
}

enum SuggestionKind: String, CaseIterable, Hashable {
    case nourish, steep, move, tend, seeds

    var label: String { rawValue }

    var plural: String {
        switch self {
        case .nourish: "foods to nourish"
        case .steep: "herbs to steep"
        case .move: "ways to move"
        case .tend: "ways to tend"
        case .seeds: "seed cycling"
        }
    }
}

struct Suggestion: Identifiable, Hashable {
    let kind: SuggestionKind
    /// Short noun, e.g. "pumpkin seeds".
    let name: String
    /// The call to action for today, e.g. "snack on a handful of pumpkin seeds".
    let action: String
    /// Why this helps right now. Secondary, shown on tap.
    let why: String

    var id: String { "\(kind.rawValue).\(name)" }
}

struct PhaseContent {
    /// Two or three words. The phase's whole mood.
    let tagline: String
    let hormones: String
    let feel: String
    let foods: [Suggestion]
    let herbs: [Suggestion]
    let movement: [Suggestion]
    let practices: [Suggestion]
    let encouragements: [String]
}
