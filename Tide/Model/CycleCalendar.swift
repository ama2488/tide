import Foundation

/// Pure cycle math. Estimates phases from averages: ovulation is assumed to
/// fall ~14 days before the next period, which is how the luteal phase
/// usually behaves even when overall cycle length varies.
struct CycleCalendar: Equatable {
    var lastPeriodStart: Date
    var cycleLength: Int
    var periodLength: Int
    var calendar: Calendar = .current
    /// When the start date is a real logged period, a late period should read
    /// as a longer luteal phase, not a surprise "day 1". For this many days past
    /// the expected start, the count keeps going instead of wrapping.
    var lateGrace: Int = 0

    /// 1‑based day of the current cycle on `date`. Projects forward (and
    /// backward) by whole cycles from the last recorded start. May exceed
    /// `cycleLength` during the late grace window.
    func cycleDay(on date: Date) -> Int {
        let start = calendar.startOfDay(for: lastPeriodStart)
        let day = calendar.startOfDay(for: date)
        let diff = calendar.dateComponents([.day], from: start, to: day).day ?? 0
        let length = max(1, cycleLength)
        if diff >= length && diff < length + lateGrace { return diff + 1 }
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

    /// The last five days before a period is due, plus any days running late.
    func isLateLuteal(day: Int) -> Bool {
        phase(forDay: day) == .luteal && day > cycleLength - 5
    }

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

    /// Days until the next expected period begins (1 = tomorrow, 0 = today,
    /// negative = running late).
    func daysUntilNextPeriod(from date: Date) -> Int {
        cycleLength - cycleDay(on: date) + 1
    }
}
