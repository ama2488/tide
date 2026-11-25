import XCTest
@testable import Tide

final class RitualTests: XCTestCase {
    private let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d, hour: 9))!
    }

    /// 28-day cycle starting nov 1: menstrual 1–5, follicular 6–12,
    /// ovulatory 13–15, early luteal 16–23, late luteal 24–28.
    private let cycle: CycleCalendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return CycleCalendar(lastPeriodStart: c.date(from: DateComponents(year: 2026, month: 11, day: 1, hour: 9))!,
                             cycleLength: 28, periodLength: 5, calendar: c)
    }()

    func testWindows() {
        XCTAssertEqual(cycle.window(forDay: 3), .menstrual)
        XCTAssertEqual(cycle.window(forDay: 8), .follicular)
        XCTAssertEqual(cycle.window(forDay: 14), .ovulatory)
        XCTAssertEqual(cycle.window(forDay: 20), .earlyLuteal)
        XCTAssertEqual(cycle.window(forDay: 26), .lateLuteal)
    }

    func testRitualTakesTheSlotOfItsKindOnlyInItsWindows() {
        let tea = Ritual(name: "follicular tea", kind: .steep, windows: [.follicular])

        let follicularDay = DailyPlan.make(for: date(2026, 11, 8), calendar: cycle, rituals: [tea])
        let steeps = follicularDay.actions.filter { $0.kind == .steep }
        XCTAssertEqual(steeps.count, 1)
        XCTAssertEqual(steeps.first?.ritualID, tea.id)
        XCTAssertEqual(steeps.first?.label, "steep · yours")
        XCTAssertEqual(follicularDay.actions.map(\.kind), [.nourish, .steep, .move, .tend, .seeds])
        XCTAssertFalse(follicularDay.canSwap(steeps[0]))

        let lutealDay = DailyPlan.make(for: date(2026, 11, 20), calendar: cycle, rituals: [tea])
        XCTAssertFalse(lutealDay.actions.contains { $0.isRitual })
    }

    func testTwoRitualsOfTheSameKindBothShow() {
        let a = Ritual(name: "tea a", kind: .steep, windows: [.lateLuteal])
        let b = Ritual(name: "tea b", kind: .steep, windows: [.lateLuteal])
        let plan = DailyPlan.make(for: date(2026, 11, 26), calendar: cycle, rituals: [a, b])
        XCTAssertEqual(plan.actions.filter { $0.kind == .steep }.map(\.name), ["tea a", "tea b"])
    }

    func testRitualIdsAreUniqueEvenWithSameName() {
        let a = Ritual(name: "same", windows: [.menstrual])
        let b = Ritual(name: "same", windows: [.menstrual])
        XCTAssertNotEqual(a.suggestion.id, b.suggestion.id)
    }

    func testDescribe() {
        XCTAssertEqual(CycleWindow.describe(Set(CycleWindow.allCases)), "every day")
        XCTAssertEqual(CycleWindow.describe([.earlyLuteal, .lateLuteal]), "luteal")
        XCTAssertEqual(CycleWindow.describe([.lateLuteal]), "late luteal")
        XCTAssertEqual(CycleWindow.describe([.follicular, .menstrual]), "menstrual, follicular")
    }

    func testStorePersistsRituals() {
        let defaults = UserDefaults(suiteName: "tide.tests.\(UUID().uuidString)")!
        let store = CycleStore(defaults: defaults)
        store.save(Ritual(name: "  moon tea  ", windows: [.menstrual]))
        XCTAssertEqual(store.rituals.first?.name, "moon tea")
        XCTAssertEqual(CycleStore(defaults: defaults).rituals.count, 1)
        store.delete(store.rituals[0])
        XCTAssertTrue(store.rituals.isEmpty)
    }
}
