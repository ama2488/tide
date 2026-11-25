import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: CycleStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false
    @State private var connecting = false

    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 44) {
                        SheetHeader(title: "settings") { dismiss() }

                        periodLog
                        if store.healthAvailable { appleHealth }
                        lengths

                        VStack(alignment: .leading, spacing: 12) {
                            Eyebrow("daily rituals")
                            Toggle(isOn: $store.seedCycling.animation(.easeInOut(duration: 0.3))) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("seed cycling")
                                        .font(TideFont.body(17))
                                        .foregroundStyle(Palette.ink)
                                    Eyebrow("flax + pumpkin, then sunflower + sesame")
                                }
                            }
                            .tint(Phase.menstrual.color)
                        }

                        VStack(alignment: .leading, spacing: 20) {
                            Text("everything stays on your phone. tide has no account and sends nothing anywhere.")
                                .font(TideFont.body(15))
                                .foregroundStyle(Palette.soft)
                                .fixedSize(horizontal: false, vertical: true)
                            Disclaimer()
                        }

                        Button { confirmReset = true } label: {
                            Text("start over")
                                .font(TideFont.label(12))
                                .tracking(1.2)
                                .foregroundStyle(Palette.soft)
                                .underline()
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(28)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .confirmationDialog("start over? this clears your settings and period log.", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("start over", role: .destructive) {
                dismiss()
                store.reset()
            }
            Button("cancel", role: .cancel) {}
        }
    }

    // MARK: sections

    private var periodLog: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow("your periods")
            NavigationLink { PeriodHistoryView() } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("period history")
                            .font(TideFont.body(20))
                            .foregroundStyle(Palette.ink)
                        Eyebrow("\(store.periods.count) logged")
                    }
                    Spacer()
                    Text("→").font(TideFont.body(17)).foregroundStyle(Palette.soft)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var appleHealth: some View {
        VStack(alignment: .leading, spacing: 16) {
            Eyebrow("apple health")
            Text("tide can read the period days you log in apple health — from apple's cycle tracking, oura, or any app that saves them there. it only reads, and nothing leaves your phone.")
                .font(TideFont.body(15))
                .lineSpacing(3)
                .foregroundStyle(Palette.soft)
                .fixedSize(horizontal: false, vertical: true)

            if store.healthConnected {
                HStack(spacing: 10) {
                    WobblyCircle(seed: 44, wobble: 0.08, closed: true)
                        .fill(Phase.follicular.color)
                        .frame(width: 9, height: 9)
                    Eyebrow(syncedLabel)
                }
                HStack(spacing: 28) {
                    InkLink(title: "sync now") { Task { await store.syncHealth() } }
                    InkLink(title: "disconnect") { store.disconnectHealth() }
                }
                Text("to remove tide's access completely: settings → health → data access & devices → tide.")
                    .font(TideFont.label(10))
                    .lineSpacing(3)
                    .foregroundStyle(Palette.soft)
            } else {
                InkButton(title: connecting ? "connecting…" : "connect apple health", seed: 41) {
                    connecting = true
                    Task {
                        await store.connectHealth()
                        connecting = false
                    }
                }
                .disabled(connecting)
            }
        }
    }

    private var syncedLabel: String {
        guard let last = store.lastHealthSync else { return "connected" }
        return "connected · synced \(last.formatted(.relative(presentation: .named)))"
    }

    @ViewBuilder
    private var lengths: some View {
        let learnedCycle = store.useHistory ? store.learnedCycleLength : nil
        let learnedPeriod = store.useHistory ? store.learnedPeriodLength : nil
        let canLearn = store.learnedCycleLength != nil || store.learnedPeriodLength != nil

        VStack(spacing: 16) {
            Eyebrow("cycle length")
            if let learnedCycle {
                LearnedValue(value: learnedCycle, note: "days · learned from your last \(store.cyclesLogged) cycles")
            } else {
                InkStepper(value: $store.cycleLength, range: 21...45, unit: "days")
            }
        }
        .frame(maxWidth: .infinity)

        VStack(spacing: 16) {
            Eyebrow("period length")
            if let learnedPeriod {
                LearnedValue(value: learnedPeriod, note: "days · learned from your log")
            } else {
                InkStepper(value: $store.periodLength, range: 2...10, unit: "days")
            }
        }
        .frame(maxWidth: .infinity)

        if canLearn {
            Toggle(isOn: $store.useHistory.animation(.easeInOut(duration: 0.3))) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("learn from my history")
                        .font(TideFont.body(17))
                        .foregroundStyle(Palette.ink)
                    Eyebrow("off: use the numbers you set")
                }
            }
            .tint(Phase.menstrual.color)
        } else {
            Text("once you've logged a few periods, tide will learn these for you.")
                .font(TideFont.label(10))
                .lineSpacing(3)
                .foregroundStyle(Palette.soft)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
        }
    }
}
