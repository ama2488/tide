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
        }
    }

    func testDailyPlanHasOneOfEachKind() {
        let c = make()
        for day in 0..<28 {
            let plan = DailyPlan.make(for: cal.date(byAdding: .day, value: day, to: date(2026, 11, 1))!, calendar: c)
            XCTAssertEqual(plan.actions.map(\.kind), [.nourish, .steep, .move, .tend])
        }
    }
}
