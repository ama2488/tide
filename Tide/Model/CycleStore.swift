import Foundation
import Combine

/// App state, persisted to UserDefaults. Everything stays on device.
final class CycleStore: ObservableObject {
    private enum Keys {
        static let onboarded = "tide.onboarded"
        static let start = "tide.lastPeriodStart"
        static let cycle = "tide.cycleLength"
        static let period = "tide.periodLength"
        static let done = "tide.completed"
    }

    private let defaults: UserDefaults

    @Published var hasOnboarded: Bool { didSet { defaults.set(hasOnboarded, forKey: Keys.onboarded) } }
    @Published var lastPeriodStart: Date { didSet { defaults.set(lastPeriodStart, forKey: Keys.start) } }
    @Published var cycleLength: Int { didSet { defaults.set(cycleLength, forKey: Keys.cycle) } }
    @Published var periodLength: Int { didSet { defaults.set(periodLength, forKey: Keys.period) } }
    /// "yyyy-MM-dd|suggestion.id" for each action checked off.
    @Published private(set) var completed: Set<String> { didSet { defaults.set(Array(completed), forKey: Keys.done) } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        hasOnboarded = defaults.bool(forKey: Keys.onboarded)
        lastPeriodStart = defaults.object(forKey: Keys.start) as? Date
            ?? Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let cycle = defaults.integer(forKey: Keys.cycle)
        cycleLength = cycle == 0 ? 28 : cycle
        let period = defaults.integer(forKey: Keys.period)
        periodLength = period == 0 ? 5 : period

        // keep only the last two weeks of check-offs
        let cutoff = Self.dayKey(Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date())
        completed = Set((defaults.stringArray(forKey: Keys.done) ?? []).filter { $0 >= cutoff })
    }

    var cycle: CycleCalendar {
        CycleCalendar(lastPeriodStart: lastPeriodStart, cycleLength: cycleLength, periodLength: periodLength)
    }

    func plan(for date: Date) -> DailyPlan { DailyPlan.make(for: date, calendar: cycle) }

    // MARK: check-offs

    func isDone(_ suggestion: Suggestion, on date: Date) -> Bool {
        completed.contains(key(suggestion, date))
    }

    func toggle(_ suggestion: Suggestion, on date: Date) {
        let k = key(suggestion, date)
        if completed.contains(k) { completed.remove(k) } else { completed.insert(k) }
    }

    // MARK: cycle

    func markPeriodStarted(on date: Date) {
        lastPeriodStart = Calendar.current.startOfDay(for: date)
    }

    func reset() {
        completed = []
        cycleLength = 28
        periodLength = 5
        hasOnboarded = false
    }

    // MARK: helpers

    private func key(_ s: Suggestion, _ date: Date) -> String { "\(Self.dayKey(date))|\(s.id)" }

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func dayKey(_ date: Date) -> String { formatter.string(from: date) }
}
