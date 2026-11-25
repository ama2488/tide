import Foundation

/// Everything the Today screen needs: one phase, one line of encouragement,
/// a few small actions.
struct DailyPlan {
    let date: Date
    let cycleDay: Int
    let phase: Phase
    /// True in the last few days of luteal, when the gentler late lists apply.
    let isLateLuteal: Bool
    let daysUntilPeriod: Int
    let encouragement: String
    let actions: [Suggestion]
    /// How many options each category had today (after hidden ones are
    /// removed), so the UI knows whether "show me another" can do anything.
    let poolSizes: [SuggestionKind: Int]

    func canSwap(_ suggestion: Suggestion) -> Bool {
        !suggestion.isRitual && (poolSizes[suggestion.kind] ?? 0) > 1
    }

    var phaseLabel: String { isLateLuteal ? "late luteal" : phase.season }

    var subtitle: String {
        if phase == .menstrual { return "\(phase.season) · period day \(cycleDay)" }
        switch daysUntilPeriod {
        case ..<(-1): return "\(phaseLabel) · running \(-daysUntilPeriod) days long"
        case -1: return "\(phaseLabel) · running a day long"
        case 0: return "\(phaseLabel) · period due today"
        case 1: return "\(phaseLabel) · period likely tomorrow"
        default: return "\(phaseLabel) · period in ~\(daysUntilPeriod) days"
        }
    }

    /// - Parameters:
    ///   - swaps: how many times each category was refreshed today.
    ///   - hidden: ids of suggestions the person never wants to see.
    ///   - rituals: the person's own items; one for today takes the place of
    ///     tide's suggestion of the same kind.
    static func make(for date: Date, calendar: CycleCalendar, includeSeeds: Bool = true,
                     swaps: [SuggestionKind: Int] = [:], hidden: Set<String> = [],
                     rituals: [Ritual] = []) -> DailyPlan {
        let day = calendar.cycleDay(on: date)
        let phase = calendar.phase(forDay: day)
        let content = phase.content
        let isLate = calendar.isLateLuteal(day: day)
        let late = isLate ? content.late : nil

        var poolSizes: [SuggestionKind: Int] = [:]

        // Rotate through each list day by day; offsets keep the categories
        // from moving in lockstep, and each refresh steps one further.
        func pick(_ list: [Suggestion], _ kind: SuggestionKind, _ offset: Int) -> Suggestion {
            let visible = list.filter { !hidden.contains($0.id) }
            let pool = visible.isEmpty ? list : visible
            poolSizes[kind] = pool.count
            return pool[(day + offset + (swaps[kind] ?? 0)) % pool.count]
        }

        let window = calendar.window(forDay: day)
        let todaysRituals = rituals.filter { $0.windows.contains(window) }

        // your own rituals first; otherwise tide's pick
        func slot(_ kind: SuggestionKind, _ list: [Suggestion], _ offset: Int) -> [Suggestion] {
            let mine = todaysRituals.filter { $0.kind == kind }.map(\.suggestion)
            return mine.isEmpty ? [pick(list, kind, offset)] : mine
        }

        var actions = slot(.nourish, late?.foods ?? content.foods, 0)
            + slot(.steep, late?.herbs ?? content.herbs, 1)
            + slot(.move, late?.movement ?? content.movement, 2)
            + slot(.tend, late?.practices ?? content.practices, 3)
        if includeSeeds {
            actions.append(Library.seeds(forDay: day, ovulationDay: calendar.ovulationDay))
            poolSizes[.seeds] = 1
        }

        let words = late?.encouragements ?? content.encouragements

        return DailyPlan(
            date: date,
            cycleDay: day,
            phase: phase,
            isLateLuteal: isLate,
            daysUntilPeriod: calendar.daysUntilNextPeriod(from: date),
            encouragement: words[day % words.count],
            actions: actions,
            poolSizes: poolSizes
        )
    }
}
