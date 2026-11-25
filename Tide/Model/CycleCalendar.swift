import Foundation

/// Pure cycle math. Estimates phases from averages: ovulation is assumed to
/// fall ~14 days before the next period, which is how the luteal phase
/// usually behaves even when overall cycle length varies.
struct CycleCalendar: Equatable {
    var lastPeriodStart: Date
    var cycleLength: Int
    var periodLength: Int
    var calendar: Calendar = .current

    /// 1‑based day of the current cycle on `date`. Projects forward (and
    /// backward) by whole cycles from the last recorded start.
    func cycleDay(on date: Date) -> Int {
        let start = calendar.startOfDay(for: lastPeriodStart)
        let day = calendar.startOfDay(for: date)
        let diff = calendar.dateComponents([.day], from: start, to: day).day ?? 0
        let length = max(1, cycleLength)
        return ((diff % length) + length) % length + 1
    }

    var ovulationDay: Int { max(periodLength + 2, cycleLength - 14) }

    func phase(forDay day: Int) -> Phase {
        if day <= periodLength { return .menstrual }
        if day < ovulationDay - 1 { return .follicular }
        if day <= ovulationDay + 1 { return .ovulatory }
        return .luteal
    }

    func phase(on date: Date) -> Phase { phase(forDay: cycleDay(on: date)) }

    /// First and last cycle day of a phase. `end < start` means the phase is
    /// too brief to show this cycle (e.g. a very short follicular phase).
    func bounds(of phase: Phase) -> (start: Int, end: Int) {
        switch phase {
        case .menstrual: return (start: 1, end: periodLength)
        case .follicular: return (start: periodLength + 1, end: ovulationDay - 2)
        case .ovulatory: return (start: ovulationDay - 1, end: ovulationDay + 1)
        case .luteal: return (start: ovulationDay + 2, end: cycleLength)
        }
    }

    /// Days until the next expected period begins (1 = tomorrow).
    func daysUntilNextPeriod(from date: Date) -> Int {
        cycleLength - cycleDay(on: date) + 1
    }
}
