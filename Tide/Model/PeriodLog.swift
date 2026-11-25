import Foundation

/// One logged period. `end` is the last day of bleeding (inclusive), or nil
/// while it's ongoing / unknown.
struct PeriodEntry: Codable, Identifiable, Hashable {
    enum Source: String, Codable {
        case tide, health
    }

    var id = UUID()
    var start: Date
    var end: Date?
    var source: Source = .tide

    func lengthInDays(calendar: Calendar = .current) -> Int? {
        end.map { CycleStats.days(from: start, to: $0, calendar: calendar) + 1 }
    }
}

/// Learns someone's actual rhythm from their log.
enum CycleStats {
    /// How many recent cycles to average.
    static let recentWindow = 6
    /// Gaps outside this range are almost always a missed log, not a real cycle.
    static let plausibleCycle = 18...45
    static let plausiblePeriod = 1...12

    static func days(from a: Date, to b: Date, calendar: Calendar = .current) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: a), to: calendar.startOfDay(for: b)).day ?? 0
    }

    static func cycleLengths(_ periods: [PeriodEntry], calendar: Calendar = .current) -> [Int] {
        let starts = periods.map(\.start).sorted()
        return zip(starts, starts.dropFirst())
            .map { days(from: $0, to: $1, calendar: calendar) }
            .filter { plausibleCycle.contains($0) }
    }

    static func periodLengths(_ periods: [PeriodEntry], calendar: Calendar = .current) -> [Int] {
        periods.sorted { $0.start < $1.start }
            .compactMap { $0.lengthInDays(calendar: calendar) }
            .filter { plausiblePeriod.contains($0) }
    }

    /// Needs at least two complete cycles (three logged starts) before it trusts itself.
    static func averageCycleLength(_ periods: [PeriodEntry], calendar: Calendar = .current) -> Int? {
        let recent = cycleLengths(periods, calendar: calendar).suffix(recentWindow)
        guard recent.count >= 2 else { return nil }
        return min(max(average(recent), 21), 45)
    }

    static func averagePeriodLength(_ periods: [PeriodEntry], calendar: Calendar = .current) -> Int? {
        let recent = periodLengths(periods, calendar: calendar).suffix(recentWindow)
        guard recent.count >= 2 else { return nil }
        return min(max(average(recent), 2), 10)
    }

    private static func average(_ values: ArraySlice<Int>) -> Int {
        Int((Double(values.reduce(0, +)) / Double(values.count)).rounded())
    }
}

/// A gentle question on the Today screen around the edges of a period.
enum PeriodPrompt: String {
    case started, ended

    var question: String {
        switch self {
        case .started: "did your period start?"
        case .ended: "has your period ended?"
        }
    }

    var todayLabel: String {
        switch self {
        case .started: "yes, today"
        case .ended: "ended today"
        }
    }

    /// `.ended` from the expected last day of bleeding (while the latest
    /// period is still open); `.started` from two days before it's due
    /// until two weeks after.
    static func due(latest: PeriodEntry?, cycleLength: Int, periodLength: Int,
                    today: Date, calendar: Calendar = .current) -> PeriodPrompt? {
        guard let latest else { return nil }
        let since = CycleStats.days(from: latest.start, to: today, calendar: calendar)
        guard since >= 0 else { return nil }
        if latest.end == nil, since >= periodLength - 1, since <= 12 { return .ended }
        if since >= cycleLength - 2, since <= cycleLength + 14 { return .started }
        return nil
    }
}

/// Turns individual days of flow (e.g. from Apple Health) into periods.
struct FlowDay {
    let date: Date
    /// Apple Health lets people mark the first day of a cycle explicitly.
    var isCycleStart = false
}

enum PeriodGrouping {
    /// Consecutive days, allowing a gap of up to `maxGap` days, form one period.
    static func periods(from flowDays: [FlowDay], calendar: Calendar = .current, maxGap: Int = 2) -> [PeriodEntry] {
        var result: [PeriodEntry] = []
        var start: Date?
        var last: Date?

        for flow in flowDays.sorted(by: { $0.date < $1.date }) {
            let day = calendar.startOfDay(for: flow.date)
            if let s = start, let l = last {
                let gap = CycleStats.days(from: l, to: day, calendar: calendar)
                if gap == 0 { continue }
                if flow.isCycleStart || gap > maxGap {
                    result.append(PeriodEntry(start: s, end: l, source: .health))
                    start = day
                }
            } else {
                start = day
            }
            last = day
        }
        if let s = start, let l = last {
            result.append(PeriodEntry(start: s, end: l, source: .health))
        }
        return result
    }
}
