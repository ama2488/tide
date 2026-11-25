import XCTest
@testable import Tide

final class BackupTests: XCTestCase {
    private func freshStore() -> CycleStore {
        CycleStore(defaults: UserDefaults(suiteName: "tide.tests.\(UUID().uuidString)")!)
    }

    func testRoundTripRestoresEverything() throws {
        let a = freshStore()
        a.hasOnboarded = true
        a.cycleLength = 31
        a.periodLength = 6
        a.seedCycling = false
        a.logPeriodStart(on: Date(timeIntervalSince1970: 1_790_000_000))
        a.save(Ritual(name: "luteal protocol", kind: .steep, windows: [.earlyLuteal, .lateLuteal],
                      items: ["tea a", "tea b"]))
        let chasteberry = Phase.luteal.content.herbs.first { $0.name == "chasteberry" }!
        a.hide(chasteberry)

        let data = try a.makeBackup().encoded()
        let b = freshStore()
        b.restore(try Backup.decode(data))

        XCTAssertTrue(b.hasOnboarded)
        XCTAssertEqual(b.cycleLength, 31)
        XCTAssertEqual(b.periodLength, 6)
        XCTAssertFalse(b.seedCycling)
        XCTAssertEqual(b.periods, a.periods)
        XCTAssertEqual(b.rituals, a.rituals)
        XCTAssertEqual(b.hiddenSuggestions, [chasteberry.id])
    }

    func testRejectsFilesThatArentPersiBackups() {
        XCTAssertThrowsError(try Backup.decode(Data(#"{"hello":"world"}"#.utf8)))
        XCTAssertThrowsError(try Backup.decode(Data("not json".utf8)))
    }

    func testToleratesMissingFields() throws {
        let minimal = #"{"app":"persi","version":1}"#
        let backup = try Backup.decode(Data(minimal.utf8))
        XCTAssertEqual(backup.cycleLength, 28)
        XCTAssertTrue(backup.rituals.isEmpty)
    }
}
