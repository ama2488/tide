import SwiftUI

/// The whole cycle at a glance. Tap a phase to learn about it.
struct CycleView: View {
    @EnvironmentObject private var store: CycleStore
    @Environment(\.dismiss) private var dismiss

    let today: Date
    @State private var confirmNewCycle = false
    @State private var logging = false

    var body: some View {
        let cycle = store.cycle
        let day = cycle.cycleDay(on: today)

        NavigationStack {
            ZStack {
                PaperBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 36) {
                        SheetHeader(title: "your cycle") { dismiss() }

                        CycleWheel(calendar: cycle, today: day)
                            .frame(maxWidth: 300)

                        VStack(spacing: 0) {
                            ForEach(Phase.allCases) { phase in
                                NavigationLink(value: phase) {
                                    row(phase, cycle: cycle, isCurrent: cycle.phase(forDay: day) == phase)
                                }
                                .buttonStyle(.plain)
                                WobblyLine(seed: phase.seed, amplitude: 0.8)
                                    .stroke(Palette.faint, lineWidth: 1)
                                    .frame(height: 3)
                            }
                        }

                        VStack(spacing: 14) {
                            if cycle.phase(forDay: day) == .menstrual, store.latestPeriod != nil, store.latestPeriod?.end == nil {
                                InkButton(title: "my period ended today", filled: true, seed: 27) {
                                    withAnimation { store.logPeriodEnd(on: today) }
                                }
                            }
                            InkButton(title: "my period started today", seed: 23) { confirmNewCycle = true }

                            HStack(spacing: 28) {
                                InkLink(title: "log another date") { logging = true }
                                NavigationLink { PeriodHistoryView() } label: { InkLinkLabel(title: "period history") }
                                    .buttonStyle(PressStyle())
                            }
                            .padding(.vertical, 10)

                            Text("tide estimates your phases from averages. bodies aren't calendars — trust what you feel.")
                                .font(TideFont.label(10))
                                .lineSpacing(3)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Palette.soft)
                        }
                    }
                    .padding(28)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Phase.self) { phase in
                PhaseDetailView(phase: phase, calendar: cycle, today: day, showsClose: false)
            }
        }
        .sheet(isPresented: $logging) {
            LogPeriodSheet(existing: nil, suggestedStart: today).environmentObject(store)
        }
        .confirmationDialog("start a new cycle today?", isPresented: $confirmNewCycle, titleVisibility: .visible) {
            Button("yes, today is day 1") { store.markPeriodStarted(on: today) }
            Button("cancel", role: .cancel) {}
        }
    }

    private func row(_ phase: Phase, cycle: CycleCalendar, isCurrent: Bool) -> some View {
        let b = cycle.bounds(of: phase)
        let days = b.end >= b.start ? (b.start == b.end ? "day \(b.start)" : "days \(b.start)–\(b.end)") : "brief this cycle"

        return HStack(spacing: 14) {
            WobblyCircle(seed: phase.seed, wobble: 0.08, closed: true)
                .fill(phase.color)
                .frame(width: 12, height: 12)
            VStack(alignment: .leading, spacing: 3) {
                Text(phase.name)
                    .font(TideFont.body(20))
                    .italic(isCurrent)
                    .foregroundStyle(Palette.ink)
                Eyebrow(isCurrent ? "\(phase.season) · you are here" : phase.season)
            }
            Spacer()
            Eyebrow(days)
            Text("→")
                .font(TideFont.body(16))
                .foregroundStyle(Palette.soft)
        }
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }
}
