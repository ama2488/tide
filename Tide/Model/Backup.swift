import Foundation
import CoreTransferable
import UniformTypeIdentifiers

/// Everything worth keeping, as one portable JSON file. Apple Health access
/// isn't included: that permission belongs to each phone.
struct Backup: Codable {
    static let currentVersion = 1

    var app = "persi"
    var version = Backup.currentVersion
    var exportedAt = Date()

    var lastPeriodStart: Date
    var cycleLength: Int
    var periodLength: Int
    var useHistory: Bool
    var seedCycling: Bool
    var periods: [PeriodEntry]
    var rituals: [Ritual]
    var hiddenSuggestions: [String]

    enum BackupError: LocalizedError {
        case notPersi
        var errorDescription: String? { "that file isn't a persi backup." }
    }

    init(lastPeriodStart: Date, cycleLength: Int, periodLength: Int, useHistory: Bool,
         seedCycling: Bool, periods: [PeriodEntry], rituals: [Ritual], hiddenSuggestions: [String]) {
        self.lastPeriodStart = lastPeriodStart
        self.cycleLength = cycleLength
        self.periodLength = periodLength
        self.useHistory = useHistory
        self.seedCycling = seedCycling
        self.periods = periods
        self.rituals = rituals
        self.hiddenSuggestions = hiddenSuggestions
    }

    // Tolerant decoding, so backups from older or newer versions still load.
    private enum CodingKeys: String, CodingKey {
        case app, version, exportedAt, lastPeriodStart, cycleLength, periodLength,
             useHistory, seedCycling, periods, rituals, hiddenSuggestions
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        guard (try? c.decode(String.self, forKey: .app)) == "persi" else { throw BackupError.notPersi }
        app = "persi"
        version = try c.decodeIfPresent(Int.self, forKey: .version) ?? 1
        exportedAt = try c.decodeIfPresent(Date.self, forKey: .exportedAt) ?? Date()
        lastPeriodStart = try c.decodeIfPresent(Date.self, forKey: .lastPeriodStart) ?? Date()
        cycleLength = try c.decodeIfPresent(Int.self, forKey: .cycleLength) ?? 28
        periodLength = try c.decodeIfPresent(Int.self, forKey: .periodLength) ?? 5
        useHistory = try c.decodeIfPresent(Bool.self, forKey: .useHistory) ?? true
        seedCycling = try c.decodeIfPresent(Bool.self, forKey: .seedCycling) ?? true
        periods = try c.decodeIfPresent([PeriodEntry].self, forKey: .periods) ?? []
        rituals = try c.decodeIfPresent([Ritual].self, forKey: .rituals) ?? []
        hiddenSuggestions = try c.decodeIfPresent([String].self, forKey: .hiddenSuggestions) ?? []
    }

    // MARK: file format

    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }

    static func decode(_ data: Data) throws -> Backup {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(Backup.self, from: data)
        } catch {
            throw BackupError.notPersi
        }
    }

    var fileName: String {
        "persi backup \(CycleStore.dayKey(exportedAt)).json"
    }

    /// One-line summary for the restore confirmation.
    var summary: String {
        let p = periods.count, r = rituals.count
        return "\(p) \(p == 1 ? "period" : "periods") and \(r) \(r == 1 ? "ritual" : "rituals"), saved \(exportedAt.formatted(date: .abbreviated, time: .omitted).lowercased())"
    }
}

/// Lets a backup be handed straight to the share sheet as a .json file.
extension Backup: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .json) { backup in
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(backup.fileName)
            try backup.encoded().write(to: url, options: .atomic)
            return SentTransferredFile(url)
        }
    }
}

extension CycleStore {
    func makeBackup() -> Backup {
        Backup(
            lastPeriodStart: lastPeriodStart,
            cycleLength: cycleLength,
            periodLength: periodLength,
            useHistory: useHistory,
            seedCycling: seedCycling,
            periods: periods,
            rituals: rituals,
            hiddenSuggestions: Array(hiddenSuggestions).sorted()
        )
    }
}
