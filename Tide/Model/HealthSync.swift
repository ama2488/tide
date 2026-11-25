import Foundation
import HealthKit

/// Reads period days from Apple Health — whatever wrote them: Apple's Cycle
/// Tracking, Oura, Natural Cycles, Flo… Read-only; tide never writes to Health.
final class HealthSync {
    private let store = HKHealthStore()
    private let flowType = HKCategoryType(.menstrualFlow)

    static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    /// Shows Apple's permission sheet the first time. HealthKit never tells
    /// apps whether *read* access was granted — a "no" just looks like no data.
    func requestAccess() async throws {
        try await store.requestAuthorization(toShare: [], read: [flowType])
    }

    func fetchPeriods(since: Date) async throws -> [PeriodEntry] {
        let predicate = HKQuery.predicateForSamples(withStart: since, end: Date())
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: flowType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate)]
        )
        let samples = try await descriptor.result(for: store)
        let days = samples
            .filter { $0.value != HKCategoryValueMenstrualFlow.none.rawValue }
            .map { sample in
                FlowDay(
                    date: sample.startDate,
                    isCycleStart: (sample.metadata?[HKMetadataKeyMenstrualCycleStart] as? Bool) ?? false
                )
            }
        return PeriodGrouping.periods(from: days)
    }
}
