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
        static let periods = "tide.periods"
        static let useHistory = "tide.useHistory"
        static let health = "tide.healthConnected"
        static let healthSync = "tide.lastHealthSync"
        static let dismissed = "tide.promptDismissed"
        static let seeds = "tide.seedCycling"
        static let swaps = "tide.swaps"
        static let hidden = "tide.hiddenSuggestions"
        static let rituals = "tide.rituals"
    }

    private let defaults: UserDefaults
    private let health = HealthSync()

    @Published var hasOnboarded: Bool { didSet { defaults.set(hasOnboarded, forKey: Keys.onboarded) } }
    /// Fallback anchor, used only if the period log is empty.
    @Published var lastPeriodStart: Date { didSet { defaults.set(lastPeriodStart, forKey: Keys.start) } }
    /// What the person told us. Used until the log has enough history.
    @Published var cycleLength: Int { didSet { defaults.set(cycleLength, forKey: Keys.cycle) } }
    @Published var periodLength: Int { didSet { defaults.set(periodLength, forKey: Keys.period) } }
    /// Prefer averages learned from the log over the numbers above.
    @Published var useHistory: Bool { didSet { defaults.set(useHistory, forKey: Keys.useHistory) } }
    /// Show a daily seed-cycling action.
    @Published var seedCycling: Bool { didSet { defaults.set(seedCycling, forKey: Keys.seeds) } }

    /// Every logged period, oldest first.
    @Published private(set) var periods: [PeriodEntry] {
        didSet {
            if let data = try? JSONEncoder().encode(periods) { defaults.set(data, forKey: Keys.periods) }
        }
    }

    @Published private(set) var healthConnected: Bool { didSet { defaults.set(healthConnected, forKey: Keys.health) } }
    @Published private(set) var lastHealthSync: Date? { didSet { defaults.set(lastHealthSync, forKey: Keys.healthSync) } }
    @Published private var dismissedPrompt: String { didSet { defaults.set(dismissedPrompt, forKey: Keys.dismissed) } }
    /// "yyyy-MM-dd|kind" → how many times that category was refreshed that day.
    @Published private var swaps: [String: Int] { didSet { defaults.set(swaps, forKey: Keys.swaps) } }
    /// Suggestion ids the person never wants to see.
    @Published private(set) var hiddenSuggestions: Set<String> {
        didSet { defaults.set(Array(hiddenSuggestions), forKey: Keys.hidden) }
    }
    /// The person's own teas, foods and practices.
    @Published private(set) var rituals: [Ritual] {
        didSet {
            if let data = try? JSONEncoder().encode(rituals) { defaults.set(data, forKey: Keys.rituals) }
        }
    }
    /// "yyyy-MM-dd|suggestion.id" for each action checked off.
    @Published private(set) var completed: Set<String> { didSet { defaults.set(Array(completed), forKey: Keys.done) } }

    init(defaults: UserDefaults = .standard) {
        let cal = Calendar.current
        self.defaults = defaults
        hasOnboarded = defaults.bool(forKey: Keys.onboarded)
        lastPeriodStart = defaults.object(forKey: Keys.start) as? Date
            ?? cal.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let cycle = defaults.integer(forKey: Keys.cycle)
        cycleLength = cycle == 0 ? 28 : cycle
        let period = defaults.integer(forKey: Keys.period)
        periodLength = period == 0 ? 5 : period
        useHistory = defaults.object(forKey: Keys.useHistory) as? Bool ?? true
        seedCycling = defaults.object(forKey: Keys.seeds) as? Bool ?? true
        healthConnected = defaults.bool(forKey: Keys.health)
        lastHealthSync = defaults.object(forKey: Keys.healthSync) as? Date
        dismissedPrompt = defaults.string(forKey: Keys.dismissed) ?? ""

        let saved = defaults.data(forKey: Keys.periods)
            .flatMap { try? JSONDecoder().decode([PeriodEntry].self, from: $0) } ?? []
        periods = saved.sorted { $0.start < $1.start }

        // keep only the last two weeks of check-offs
        let cutoff = Self.dayKey(cal.date(byAdding: .day, value: -14, to: Date()) ?? Date())
        completed = Set((defaults.stringArray(forKey: Keys.done) ?? []).filter { $0 >= cutoff })
        swaps = ((defaults.dictionary(forKey: Keys.swaps) as? [String: Int]) ?? [:]).filter { $0.key >= cutoff }
        hiddenSuggestions = Set(defaults.stringArray(forKey: Keys.hidden) ?? [])
        rituals = defaults.data(forKey: Keys.rituals)
            .flatMap { try? JSONDecoder().decode([Ritual].self, from: $0) } ?? []

        // people who onboarded before the log existed: seed it from their start date
        if periods.isEmpty && hasOnboarded {
            periods = [PeriodEntry(start: cal.startOfDay(for: lastPeriodStart))]
        }
    }

    // MARK: - Cycle

    var latestPeriod: PeriodEntry? { periods.last }

    var learnedCycleLength: Int? { CycleStats.averageCycleLength(periods) }
    var learnedPeriodLength: Int? { CycleStats.averagePeriodLength(periods) }
    var cyclesLogged: Int { min(CycleStats.cycleLengths(periods).count, CycleStats.recentWindow) }

    var effectiveCycleLength: Int { (useHistory ? learnedCycleLength : nil) ?? cycleLength }
    var effectivePeriodLength: Int { (useHistory ? learnedPeriodLength : nil) ?? periodLength }

    var cycle: CycleCalendar {
        CycleCalendar(
            lastPeriodStart: latestPeriod?.start ?? lastPeriodStart,
            cycleLength: effectiveCycleLength,
            periodLength: currentPeriodLength,
            lateGrace: periods.isEmpty ? 0 : 10
        )
    }

    /// The latest period's real length once it's over; the usual length while
    /// it's ongoing (or still being filled in from Health).
    private var currentPeriodLength: Int {
        guard let latest = latestPeriod, let end = latest.end,
              let length = latest.lengthInDays() else { return effectivePeriodLength }
        let stillFilling = CycleStats.days(from: end, to: Date()) <= 1
        let clamped = min(max(length, 1), 10)
        return stillFilling ? max(clamped, effectivePeriodLength) : clamped
    }

    func plan(for date: Date) -> DailyPlan {
        let day = Self.dayKey(date)
        var todaysSwaps: [SuggestionKind: Int] = [:]
        for kind in SuggestionKind.allCases {
            if let n = swaps["\(day)|\(kind.rawValue)"] { todaysSwaps[kind] = n }
        }
        return DailyPlan.make(for: date, calendar: cycle, includeSeeds: seedCycling,
                              swaps: todaysSwaps, hidden: hiddenSuggestions, rituals: rituals)
    }

    // MARK: - Refresh / hide

    /// "show me another" — steps to the next option in that category, for today only.
    func swap(_ suggestion: Suggestion, on date: Date) {
        swaps["\(Self.dayKey(date))|\(suggestion.kind.rawValue)", default: 0] += 1
    }

    /// "don't suggest this again" — removed from every day, until restored in settings.
    func hide(_ suggestion: Suggestion) {
        hiddenSuggestions.insert(suggestion.id)
    }

    func restoreHiddenSuggestions() {
        hiddenSuggestions = []
    }

    // MARK: - Rituals

    /// Days until any of these windows is in effect (0 = today).
    func daysUntil(_ windows: Set<CycleWindow>, from date: Date = Date()) -> Int? {
        let c = cycle
        return windows.compactMap { c.daysUntil($0, from: date) }.min()
    }

    /// "on today", "starts tomorrow", "starts in 6 days".
    func showingLabel(_ windows: Set<CycleWindow>) -> String? {
        guard let n = daysUntil(windows) else { return nil }
        switch n {
        case 0: return "on today"
        case 1: return "starts tomorrow"
        default: return "starts in \(n) days"
        }
    }

    func ritual(for suggestion: Suggestion) -> Ritual? {
        suggestion.ritualID.flatMap { id in rituals.first { $0.id == id } }
    }

    func save(_ ritual: Ritual) {
        var clean = ritual
        clean.name = ritual.name.trimmingCharacters(in: .whitespacesAndNewlines)
        clean.note = ritual.note.trimmingCharacters(in: .whitespacesAndNewlines)
        clean.items = ritual.items
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if let i = rituals.firstIndex(where: { $0.id == clean.id }) { rituals[i] = clean } else { rituals.append(clean) }
    }

    func delete(_ ritual: Ritual) {
        rituals.removeAll { $0.id == ritual.id }
    }

    // MARK: - Period log

    func logPeriodStart(on date: Date) {
        let day = Calendar.current.startOfDay(for: date)
        var list = periods
        // tapping near an existing entry corrects it rather than adding a duplicate
        if let i = list.firstIndex(where: { abs(CycleStats.days(from: $0.start, to: day)) <= 3 }) {
            list[i].start = day
            if let end = list[i].end, end < day { list[i].end = nil }
        } else {
            list.append(PeriodEntry(start: day))
        }
        periods = list.sorted { $0.start < $1.start }
    }

    /// Kept for the cycle screen's button.
    func markPeriodStarted(on date: Date) { logPeriodStart(on: date) }

    func logPeriodEnd(on date: Date) {
        guard var latest = latestPeriod else { return }
        latest.end = max(Calendar.current.startOfDay(for: date), latest.start)
        save(latest)
    }

    func save(_ entry: PeriodEntry) {
        let cal = Calendar.current
        var clean = entry
        clean.start = cal.startOfDay(for: entry.start)
        clean.end = entry.end.map { max(cal.startOfDay(for: $0), clean.start) }

        var list = periods
        if let i = list.firstIndex(where: { $0.id == clean.id }) { list[i] = clean } else { list.append(clean) }
        periods = list.sorted { $0.start < $1.start }
    }

    func delete(_ entry: PeriodEntry) {
        periods.removeAll { $0.id == entry.id }
    }

    // MARK: - Prompts

    func prompt(on date: Date) -> PeriodPrompt? {
        guard let p = PeriodPrompt.due(latest: latestPeriod, cycleLength: effectiveCycleLength,
                                       periodLength: effectivePeriodLength, today: date) else { return nil }
        return dismissedPrompt == "\(Self.dayKey(date))|\(p.rawValue)" ? nil : p
    }

    /// "not yet" — ask again tomorrow.
    func dismiss(_ prompt: PeriodPrompt, on date: Date) {
        dismissedPrompt = "\(Self.dayKey(date))|\(prompt.rawValue)"
    }

    // MARK: - Apple Health

    var healthAvailable: Bool { HealthSync.isAvailable }

    @MainActor
    func connectHealth() async {
        guard healthAvailable else { return }
        do {
            try await health.requestAccess()
            healthConnected = true
            await syncHealth()
        } catch {
            healthConnected = false
        }
    }

    @MainActor
    func syncHealth() async {
        guard healthConnected, healthAvailable else { return }
        let since = Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date()
        guard let incoming = try? await health.fetchPeriods(since: since) else { return }
        merge(fromHealth: incoming)
        lastHealthSync = Date()
    }

    /// Stops syncing. Periods already imported stay in the log.
    func disconnectHealth() {
        healthConnected = false
    }

    /// Health entries update in place; a period logged in tide is kept, and
    /// only gets its end date filled in from Health.
    func merge(fromHealth incoming: [PeriodEntry]) {
        var list = periods
        for h in incoming {
            if let i = list.firstIndex(where: { abs(CycleStats.days(from: $0.start, to: h.start)) <= 3 }) {
                if list[i].source == .health {
                    list[i].start = h.start
                    list[i].end = h.end
                } else if list[i].end == nil, let end = h.end, end >= list[i].start {
                    list[i].end = end
                }
            } else {
                list.append(h)
            }
        }
        periods = list.sorted { $0.start < $1.start }
    }

    // MARK: - Check-offs

    func isDone(_ suggestion: Suggestion, on date: Date) -> Bool {
        completed.contains(key(suggestion, date))
    }

    func toggle(_ suggestion: Suggestion, on date: Date) {
        let k = key(suggestion, date)
        if completed.contains(k) { completed.remove(k) } else { completed.insert(k) }
    }

    // MARK: - Backup

    /// Replaces everything on this phone with the backup. Apple Health access
    /// stays as it is on this phone.
    func restore(_ backup: Backup) {
        lastPeriodStart = backup.lastPeriodStart
        cycleLength = min(max(backup.cycleLength, 21), 45)
        periodLength = min(max(backup.periodLength, 2), 10)
        useHistory = backup.useHistory
        seedCycling = backup.seedCycling
        periods = backup.periods.sorted { $0.start < $1.start }
        rituals = backup.rituals
        hiddenSuggestions = Set(backup.hiddenSuggestions)
        swaps = [:]
        completed = []
        dismissedPrompt = ""
        hasOnboarded = true
    }

    // MARK: - Reset

    func reset() {
        completed = []
        periods = []
        cycleLength = 28
        periodLength = 5
        useHistory = true
        seedCycling = true
        swaps = [:]
        hiddenSuggestions = []
        rituals = []
        healthConnected = false
        lastHealthSync = nil
        dismissedPrompt = ""
        hasOnboarded = false
    }

    // MARK: - Helpers

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
