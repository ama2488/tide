import Foundation

/// The parts of the cycle a ritual can belong to. Luteal is split in two so a
/// late-luteal tea can be different from an early-luteal one.
enum CycleWindow: String, Codable, CaseIterable, Identifiable, Hashable {
    case menstrual, follicular, ovulatory, earlyLuteal, lateLuteal

    var id: String { rawValue }

    var label: String {
        switch self {
        case .menstrual: "menstrual"
        case .follicular: "follicular"
        case .ovulatory: "ovulatory"
        case .earlyLuteal: "early luteal"
        case .lateLuteal: "late luteal"
        }
    }

    var hint: String {
        switch self {
        case .menstrual: "your period"
        case .follicular: "after your period"
        case .ovulatory: "mid-cycle"
        case .earlyLuteal: "after ovulation"
        case .lateLuteal: "the 5 days before"
        }
    }

    var phase: Phase {
        switch self {
        case .menstrual: .menstrual
        case .follicular: .follicular
        case .ovulatory: .ovulatory
        case .earlyLuteal, .lateLuteal: .luteal
        }
    }

    static func windows(for phase: Phase) -> Set<CycleWindow> {
        Set(allCases.filter { $0.phase == phase })
    }

    /// "every day", "luteal", "menstrual, follicular"…
    static func describe(_ windows: Set<CycleWindow>) -> String {
        if windows.count == allCases.count { return "every day" }
        var parts: [String] = []
        for w in allCases where windows.contains(w) {
            if w == .earlyLuteal && windows.contains(.lateLuteal) { parts.append("luteal"); continue }
            if w == .lateLuteal && windows.contains(.earlyLuteal) { continue }
            parts.append(w.label)
        }
        return parts.joined(separator: ", ")
    }
}

/// Something the person already does: a cycle-sync tea, a favorite food, a
/// practice. With `items`, it's a protocol: several things shown as one row.
struct Ritual: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var note: String = ""
    var kind: SuggestionKind = .steep
    var windows: Set<CycleWindow> = []
    /// e.g. the three teas in a phase protocol. Empty for a single ritual.
    var items: [String] = []

    var isProtocol: Bool { !items.isEmpty }

    /// How it appears among today's actions.
    var suggestion: Suggestion {
        let fallback = isProtocol
            ? "your protocol for \(CycleWindow.describe(windows))."
            : "you added this for \(CycleWindow.describe(windows))."
        return Suggestion(
            kind: kind,
            name: name,
            action: name,
            why: note.isEmpty ? fallback : note,
            ritualID: id,
            details: items
        )
    }

    init(id: UUID = UUID(), name: String, note: String = "", kind: SuggestionKind = .steep,
         windows: Set<CycleWindow> = [], items: [String] = []) {
        self.id = id
        self.name = name
        self.note = note
        self.kind = kind
        self.windows = windows
        self.items = items
    }

    // Rituals saved before protocols existed have no "items"; read them anyway.
    private enum CodingKeys: String, CodingKey { case id, name, note, kind, windows, items }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decode(String.self, forKey: .name)
        note = try c.decodeIfPresent(String.self, forKey: .note) ?? ""
        kind = try c.decodeIfPresent(SuggestionKind.self, forKey: .kind) ?? .steep
        windows = try c.decodeIfPresent(Set<CycleWindow>.self, forKey: .windows) ?? []
        items = try c.decodeIfPresent([String].self, forKey: .items) ?? []
    }

    /// The types a person can choose for their own ritual.
    static let kinds: [SuggestionKind] = [.steep, .nourish, .move, .tend]
}
