import XCTest
@testable import Tide

final class CycleCalendarTests: XCTestCase {
    private var cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d, hour: 9))!
    }

    private func make(cycle: Int = 28, period: Int = 5) -> CycleCalendar {
        CycleCalendar(lastPeriodStart: date(2026, 11, 1), cycleLength: cycle, periodLength: period, calendar: cal)
    }

    func testStartDateIsDayOne() {
        XCTAssertEqual(make().cycleDay(on: date(2026, 11, 1)), 1)
    }

    func testDaysCountAndWrap() {
        let c = make()
        XCTAssertEqual(c.cycleDay(on: date(2026, 11, 28)), 28)
        XCTAssertEqual(c.cycleDay(on: date(2026, 11, 29)), 1)
        XCTAssertEqual(c.cycleDay(on: date(2027, 1, 1)), 6) // 61 days later
    }

    func testDatesBeforeStartProjectBackward() {
        XCTAssertEqual(make().cycleDay(on: date(2026, 10, 31)), 28)
    }

    func testTypicalPhases() {
        let c = make()
        XCTAssertEqual(c.ovulationDay, 14)
        XCTAssertEqual((1...5).map(c.phase(forDay:)), Array(repeating: .menstrual, count: 5))
        XCTAssertEqual((6...12).map(c.phase(forDay:)), Array(repeating: .follicular, count: 7))
        XCTAssertEqual((13...15).map(c.phase(forDay:)), Array(repeating: .ovulatory, count: 3))
        XCTAssertEqual((16...28).map(c.phase(forDay:)), Array(repeating: .luteal, count: 13))
    }

    func testBoundsMatchPhaseForDay() {
        for cycle in 21...45 {
            for period in 2...10 {
                let c = make(cycle: cycle, period: period)
                for day in 1...cycle {
                    let b = c.bounds(of: c.phase(forDay: day))
                    XCTAssertTrue(b.start <= day && day <= b.end, "cycle \(cycle) period \(period) day \(day)")
                }
            }
        }
    }

    func testShortCycleSkipsFollicular() {
        let c = make(cycle: 21, period: 8)
        let b = c.bounds(of: .follicular)
        XCTAssertLessThan(b.end, b.start)
    }

    func testDaysUntilNextPeriod() {
        let c = make()
        XCTAssertEqual(c.daysUntilNextPeriod(from: date(2026, 11, 28)), 1)
        XCTAssertEqual(c.daysUntilNextPeriod(from: date(2026, 11, 1)), 28)
    }

    func testEveryPhaseHasContentForEveryCategory() {
        for phase in Phase.allCases {
            let content = phase.content
            XCTAssertFalse(content.foods.isEmpty)
            XCTAssertFalse(content.herbs.isEmpty)
            XCTAssertFalse(content.movement.isEmpty)
            XCTAssertFalse(content.practices.isEmpty)
            XCTAssertFalse(content.encouragements.isEmpty)
            let ids = (content.foods + content.herbs + content.movement + content.practices).map(\.id)
            XCTAssertEqual(Set(ids).count, ids.count, "duplicate suggestion ids in \(phase)")
            if let late = content.late {
                XCTAssertFalse(late.foods.isEmpty || late.herbs.isEmpty || late.movement.isEmpty
                               || late.practices.isEmpty || late.encouragements.isEmpty)
                let lateIds = late.all.map(\.id)
                XCTAssertEqual(Set(lateIds).count, lateIds.count, "duplicate late ids in \(phase)")
            }
        }
        XCTAssertNotNil(Phase.luteal.content.late)
    }

    // MARK: late luteal

    func testLateLutealIsTheLastFiveDays() {
        let c = make() // 28 days
        XCTAssertFalse(c.isLateLuteal(day: 16))
        XCTAssertFalse(c.isLateLuteal(day: 23))
        XCTAssertTrue((24...28).allSatisfy(c.isLateLuteal(day:)))
        XCTAssertFalse(c.isLateLuteal(day: 3)) // menstrual
    }

    func testLateLutealUsesGentlerLists() {
        let c = make()
        let late = Phase.luteal.content.late!
        let day25 = DailyPlan.make(for: date(2026, 11, 25), calendar: c)
        XCTAssertTrue(day25.isLateLuteal)
        XCTAssertTrue(day25.subtitle.hasPrefix("late luteal"))
        XCTAssertTrue(late.foods.contains(day25.actions[0]))
        XCTAssertTrue(late.encouragements.contains(day25.encouragement))

        let day18 = DailyPlan.make(for: date(2026, 11, 18), calendar: c)
        XCTAssertFalse(day18.isLateLuteal)
        XCTAssertTrue(day18.subtitle.hasPrefix("inner autumn"))
        XCTAssertTrue(Phase.luteal.content.foods.contains(day18.actions[0]))
    }

    // MARK: refresh / hide

    func testSwapGivesADifferentSuggestionInTheSameCategory() {
        let c = make()
        let d = date(2026, 11, 18)
        let base = DailyPlan.make(for: d, calendar: c)
        let swapped = DailyPlan.make(for: d, calendar: c, swaps: [.steep: 1])
        XCTAssertNotEqual(base.actions[1], swapped.actions[1])
        XCTAssertEqual(swapped.actions[1].kind, .steep)
        XCTAssertEqual(base.actions[0], swapped.actions[0]) // other categories untouched
    }

    func testHiddenSuggestionNeverAppears() {
        let c = make()
        let chasteberry = Phase.luteal.content.herbs.first { $0.name == "chasteberry" }!
        for offset in 0..<28 {
            let d = cal.date(byAdding: .day, value: offset, to: date(2026, 11, 1))!
            for swaps in 0..<5 {
                let plan = DailyPlan.make(for: d, calendar: c, swaps: [.steep: swaps], hidden: [chasteberry.id])
                XCTAssertFalse(plan.actions.contains(chasteberry))
            }
        }
    }

    func testCannotSwapSeeds() {
        let plan = DailyPlan.make(for: date(2026, 11, 18), calendar: make())
        XCTAssertFalse(plan.canSwap(plan.actions[4]))
        XCTAssertTrue(plan.canSwap(plan.actions[0]))
    }

    func testDailyPlanHasOneOfEachKind() {
        let c = make()
        for day in 0..<28 {
            let plan = DailyPlan.make(for: cal.date(byAdding: .day, value: day, to: date(2026, 11, 1))!, calendar: c)
            XCTAssertEqual(plan.actions.map(\.kind), [.nourish, .steep, .move, .tend, .seeds])
            let withoutSeeds = DailyPlan.make(for: plan.date, calendar: c, includeSeeds: false)
            XCTAssertEqual(withoutSeeds.actions.map(\.kind), [.nourish, .steep, .move, .tend])
        }
    }

    func testSeedCyclingSwitchesAfterOvulation() {
        let c = make() // ovulation on day 14
        XCTAssertEqual(Library.seeds(forDay: 1, ovulationDay: c.ovulationDay).name, "flax + pumpkin")
        XCTAssertEqual(Library.seeds(forDay: 14, ovulationDay: c.ovulationDay).name, "flax + pumpkin")
        XCTAssertEqual(Library.seeds(forDay: 15, ovulationDay: c.ovulationDay).name, "sunflower + sesame")
        XCTAssertEqual(Library.seeds(forDay: 28, ovulationDay: c.ovulationDay).name, "sunflower + sesame")
        // switch days get a nudge, but keep the same id so check-offs stay put
        let switchDay = Library.seeds(forDay: 15, ovulationDay: 14)
        XCTAssertTrue(switchDay.action.hasPrefix("time to switch"))
        XCTAssertEqual(switchDay.id, Library.seeds(forDay: 20, ovulationDay: 14).id)
        XCTAssertTrue(Library.seeds(forDay: 1, ovulationDay: 14).action.hasPrefix("new cycle"))
    }
}
