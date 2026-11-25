import Foundation

/// Everything the Today screen needs: one phase, one line of encouragement,
/// four small actions.
struct DailyPlan {
    let date: Date
    let cycleDay: Int
    let phase: Phase
    let daysUntilPeriod: Int
    let encouragement: String
    let actions: [Suggestion]

    var subtitle: String {
        if phase == .menstrual { return "\(phase.season) · period day \(cycleDay)" }
        switch daysUntilPeriod {
        case 1: return "\(phase.season) · period likely tomorrow"
        default: return "\(phase.season) · period in ~\(daysUntilPeriod) days"
        }
    }

    static func make(for date: Date, calendar: CycleCalendar) -> DailyPlan {
        let day = calendar.cycleDay(on: date)
        let phase = calendar.phase(forDay: day)
        let content = phase.content

        // Rotate through each list day by day; offsets keep the four
        // categories from moving in lockstep.
        func pick(_ list: [Suggestion], _ offset: Int) -> Suggestion {
            list[(day + offset) % list.count]
        }

        return DailyPlan(
            date: date,
            cycleDay: day,
            phase: phase,
            daysUntilPeriod: calendar.daysUntilNextPeriod(from: date),
            encouragement: content.encouragements[day % content.encouragements.count],
            actions: [
                pick(content.foods, 0),
                pick(content.herbs, 1),
                pick(content.movement, 2),
                pick(content.practices, 3),
            ]
        )
    }
}
