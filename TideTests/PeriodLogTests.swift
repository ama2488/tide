import XCTest
@testable import Tide

final class PeriodLogTests: XCTestCase {
    private let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d, hour: 9))!
    }

    private func entry(_ start: Date, days: Int? = 5) -> PeriodEntry {
        PeriodEntry(start: start, end: days.map { cal.date(byAdding: .day, value: $0 - 1, to: start)! })
    }

    // MARK: stats

    func testNeedsTwoCyclesBeforeLearning() {
        let log = [entry(date(2026, 9, 1)), entry(date(2026, 9, 30))]
        XCTAssertNil(CycleStats.averageCycleLength(log, calendar: cal))
        XCTAssertEqual(CycleStats.averagePeriodLength(log, calendar: cal), 5)
    }

    func testAveragesRecentCycles() {
        // 29, 31, 30 → 30
        let log = [date(2026, 8, 1), date(2026, 8, 30), date(2026, 9, 30), date(2026, 10, 30)].map { entry($0) }
        XCTAssertEqual(CycleStats.cycleLengths(log, calendar: cal), [29, 31, 30])
        XCTAssertEqual(CycleStats.averageCycleLength(log, calendar: cal), 30)
    }

    func testSkipsGapsThatLookLikeAMissedLog() {
        // 28, then 56 (a missed month), then 28
        let log = [date(2026, 6, 1), date(2026, 6, 29), date(2026, 8, 24), date(2026, 9, 21)].map { entry($0) }
        XCTAssertEqual(CycleStats.cycleLengths(log, calendar: cal), [28, 28])
        XCTAssertEqual(CycleStats.averageCycleLength(log, calendar: cal), 28)
    }

    func testOpenPeriodsDontCountTowardLength() {
        let log = [entry(date(2026, 9, 1), days: 4), entry(date(2026, 9, 29), days: 6), entry(date(2026, 10, 27), days: nil)]
        XCTAssertEqual(CycleStats.periodLengths(log, calendar: cal), [4, 6])
        XCTAssertEqual(CycleStats.averagePeriodLength(log, calendar: cal), 5)
    }

    // MARK: prompts

    func testStartedPromptWindow() {
        let latest = entry(date(2026, 11, 1))
        func prompt(_ d: Date) -> PeriodPrompt? {
            PeriodPrompt.due(latest: latest, cycleLength: 28, periodLength: 5, today: d, calendar: cal)
        }
        XCTAssertNil(prompt(date(2026, 11, 20)))
        XCTAssertNil(prompt(date(2026, 11, 26)))                 // 3 days out
        XCTAssertEqual(prompt(date(2026, 11, 27)), .started)     // 2 days out
        XCTAssertEqual(prompt(date(2026, 12, 6)), .started)      // running late
        XCTAssertNil(prompt(date(2026, 12, 20)))                 // gave up asking
    }

    func testEndedPromptOnlyWhileOpen() {
        let open = entry(date(2026, 11, 1), days: nil)
        func prompt(_ d: Date, _ e: PeriodEntry) -> PeriodPrompt? {
            PeriodPrompt.due(latest: e, cycleLength: 28, periodLength: 5, today: d, calendar: cal)
        }
        XCTAssertNil(prompt(date(2026, 11, 3), open))
        XCTAssertEqual(prompt(date(2026, 11, 5), open), .ended)  // expected last day
        XCTAssertNil(prompt(date(2026, 11, 5), entry(date(2026, 11, 1))))
    }

    // MARK: grouping (Apple Health)

    func testGroupsConsecutiveDaysAndToleratesOneMissingDay() {
        let days = [1, 2, 3, 5, 29, 30, 31].map { FlowDay(date: cal.date(byAdding: .day, value: $0 - 1, to: date(2026, 10, 1))!) }
        let periods = PeriodGrouping.periods(from: days, calendar: cal)
        XCTAssertEqual(periods.count, 2)
        XCTAssertEqual(periods[0].lengthInDays(calendar: cal), 5)
        XCTAssertEqual(periods[1].lengthInDays(calendar: cal), 3)
        XCTAssertTrue(periods.allSatisfy { $0.source == .health })
    }

    func testExplicitCycleStartSplitsPeriods() {
        let days = [
            FlowDay(date: date(2026, 10, 1)),
            FlowDay(date: date(2026, 10, 2)),
            FlowDay(date: date(2026, 10, 3), isCycleStart: true),
        ]
        XCTAssertEqual(PeriodGrouping.periods(from: days, calendar: cal).count, 2)
    }

    func testDuplicateSamplesOnOneDay() {
        let days = [FlowDay(date: date(2026, 10, 1)), FlowDay(date: date(2026, 10, 1).addingTimeInterval(3600))]
        let periods = PeriodGrouping.periods(from: days, calendar: cal)
        XCTAssertEqual(periods.count, 1)
        XCTAssertEqual(periods[0].lengthInDays(calendar: cal), 1)
    }

    // MARK: late periods

    func testLatePeriodKeepsCountingInsteadOfWrapping() {
        let c = CycleCalendar(lastPeriodStart: date(2026, 11, 1), cycleLength: 28, periodLength: 5, calendar: cal, lateGrace: 10)
        XCTAssertEqual(c.cycleDay(on: date(2026, 11, 30)), 30)
        XCTAssertEqual(c.phase(on: date(2026, 11, 30)), .luteal)
        XCTAssertEqual(c.daysUntilNextPeriod(from: date(2026, 11, 30)), -1)
        XCTAssertEqual(c.cycleDay(on: date(2026, 12, 9)), 11) // past the grace window, projects again
    }

    // MARK: store

    func testStoreLogAndMerge() {
        let defaults = UserDefaults(suiteName: "tide.tests.\(UUID().uuidString)")!
        let store = CycleStore(defaults: defaults)
        store.logPeriodStart(on: date(2026, 10, 1))
        store.logPeriodStart(on: date(2026, 10, 2))   // correction, not a duplicate
        XCTAssertEqual(store.periods.count, 1)

        store.merge(fromHealth: [PeriodEntry(start: date(2026, 10, 1), end: date(2026, 10, 5), source: .health),
                                 PeriodEntry(start: date(2026, 9, 3), end: date(2026, 9, 7), source: .health)])
        XCTAssertEqual(store.periods.count, 2)
        XCTAssertEqual(store.periods.last?.source, .tide)  // tide's own entry is kept…
        XCTAssertNotNil(store.periods.last?.end)           // …and gets its end filled in

        // survives a relaunch
        XCTAssertEqual(CycleStore(defaults: defaults).periods.count, 2)
    }
}
