import SwiftUI

/// The one screen that matters: where you are, one line for today,
/// four small things to do. Everything else is a tap away.
struct TodayView: View {
    @EnvironmentObject private var store: CycleStore
    @Environment(\.scenePhase) private var scenePhase

    @State private var today = Date()
    @State private var selected: Suggestion?
    @State private var sheet: TodaySheet?
    @State private var breathe = false

    enum TodaySheet: String, Identifiable {
        case phase, cycle, settings, logStart, logEnd
        var id: String { rawValue }
    }

    var body: some View {
        let plan = store.plan(for: today)
        let prompt = store.prompt(on: today)

        ZStack {
            PaperBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    header
                    hero(plan).padding(.top, 32)
                    words(plan).padding(.top, 36)

                    WobblyLine(seed: 12)
                        .stroke(Palette.faint, lineWidth: 1)
                        .frame(height: 6)
                        .padding(.vertical, 36)

                    if let prompt {
                        PeriodPromptCard(
                            prompt: prompt,
                            onToday: {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    switch prompt {
                                    case .started: store.logPeriodStart(on: today)
                                    case .ended: store.logPeriodEnd(on: today)
                                    }
                                }
                            },
                            onEarlier: { sheet = prompt == .started ? .logStart : .logEnd },
                            onNotYet: { withAnimation(.easeInOut(duration: 0.3)) { store.dismiss(prompt, on: today) } }
                        )
                        .padding(.bottom, 36)
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                    }

                    actions(plan)
                    footer(plan).padding(.top, 48)
                }
                .padding(.horizontal, 28)
                .padding(.top, 8)
                .padding(.bottom, 56)
            }
        }
        .sheet(item: $selected) { suggestion in
            SuggestionSheet(suggestion: suggestion, phase: plan.phase, date: today, canSwap: plan.canSwap(suggestion))
                .environmentObject(store)
        }
        .sheet(item: $sheet) { which in
            Group {
                switch which {
                case .phase: PhaseDetailView(phase: plan.phase, calendar: store.cycle, today: plan.cycleDay)
                case .cycle: CycleView(today: today)
                case .settings: SettingsView()
                case .logStart:
                    LogPeriodSheet(existing: nil,
                                   suggestedStart: Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today)
                case .logEnd: LogPeriodSheet(existing: store.latestPeriod, endedByDefault: true)
                }
            }
            .environmentObject(store)
            .presentationBackground(Palette.paper)
            .presentationCornerRadius(28)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                today = Date()
                Task { await store.syncHealth() }
            }
        }
        .task { await store.syncHealth() }
    }

    // MARK: sections

    private var header: some View {
        HStack {
            Text(today.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()).lowercased())
                .font(TideFont.label(12))
                .tracking(1.4)
                .foregroundStyle(Palette.soft)
            Spacer()
            Button { sheet = .settings } label: {
                Text("settings")
                    .font(TideFont.label(12))
                    .tracking(1.4)
                    .foregroundStyle(Palette.soft)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private func hero(_ plan: DailyPlan) -> some View {
        VStack(spacing: 20) {
            Button { sheet = .cycle } label: {
                PhaseGlyph(plan.phase)
                    .frame(width: 210, height: 210)
                    .scaleEffect(breathe ? 1.03 : 0.98)
            }
            .buttonStyle(PressStyle())
            .onAppear {
                withAnimation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true)) { breathe = true }
            }

            VStack(spacing: 8) {
                Eyebrow("day \(plan.cycleDay)")
                Text(plan.phase.name)
                    .font(TideFont.display(48))
                    .italic()
                    .foregroundStyle(Palette.ink)
                Text(plan.subtitle)
                    .font(TideFont.label(11))
                    .tracking(1)
                    .foregroundStyle(Palette.soft)
            }
        }
    }

    private func words(_ plan: DailyPlan) -> some View {
        VStack(spacing: 14) {
            Eyebrow("for today")
            Text(plan.encouragement)
                .font(TideFont.display(25))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 8)
    }

    private func actions(_ plan: DailyPlan) -> some View {
        let doneCount = plan.actions.filter { store.isDone($0, on: today) }.count
        let allDone = doneCount == plan.actions.count

        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Eyebrow("today, try")
                Spacer()
                Eyebrow("\(doneCount) of \(plan.actions.count)")
                    .contentTransition(.numericText())
            }
            .padding(.bottom, 4)

            ForEach(Array(plan.actions.enumerated()), id: \.element.id) { index, suggestion in
                ActionRow(
                    suggestion: suggestion,
                    isDone: store.isDone(suggestion, on: today),
                    color: plan.phase.color,
                    seed: UInt64(index * 13 + 5),
                    onToggle: {
                        withAnimation(.easeInOut(duration: 0.25)) { store.toggle(suggestion, on: today) }
                    },
                    onOpen: { selected = suggestion },
                    onSwap: plan.canSwap(suggestion) ? {
                        withAnimation(.easeInOut(duration: 0.35)) { store.swap(suggestion, on: today) }
                    } : nil,
                    onHide: (suggestion.kind == .seeds || suggestion.isRitual) ? nil : {
                        withAnimation(.easeInOut(duration: 0.35)) { store.hide(suggestion) }
                    }
                )
                if index < plan.actions.count - 1 {
                    WobblyLine(seed: UInt64(index + 30), amplitude: 1)
                        .stroke(Palette.faint, lineWidth: 1)
                        .frame(height: 3)
                }
            }

            if allDone {
                Text("that's the day. beautifully tended.")
                    .font(TideFont.body(16))
                    .italic()
                    .foregroundStyle(Palette.soft)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .sensoryFeedback(.success, trigger: allDone) { _, now in now }
    }

    private func footer(_ plan: DailyPlan) -> some View {
        VStack(spacing: 20) {
            InkLink(title: "why this, and why now") { sheet = .phase }
            InkLink(title: "see your whole cycle") { sheet = .cycle }
        }
    }
}

// MARK: - Action row

struct ActionRow: View {
    let suggestion: Suggestion
    let isDone: Bool
    let color: Color
    let seed: UInt64
    let onToggle: () -> Void
    let onOpen: () -> Void
    /// Long-press options. nil hides the option.
    var onSwap: (() -> Void)? = nil
    var onHide: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Button(action: onToggle) {
                HandCheck(isOn: isDone, color: color, seed: seed)
                    .padding(6)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.impact(weight: .light), trigger: isDone)
            .accessibilityLabel(isDone ? "done" : "mark done")

            Button(action: onOpen) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 6) {
                        Eyebrow(suggestion.label)
                        Text(suggestion.action)
                            .font(TideFont.body(18))
                            .strikethrough(isDone, color: Palette.soft)
                            .foregroundStyle(Palette.ink)
                            .opacity(isDone ? 0.45 : 1)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 12)
                    Text("why")
                        .font(TideFont.label(11))
                        .foregroundStyle(Palette.soft)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 16)
        .contextMenu {
            if let onSwap {
                Button(action: onSwap) { Label("show me another", systemImage: "arrow.triangle.2.circlepath") }
            }
            if let onHide {
                Button(role: .destructive, action: onHide) { Label("don't suggest this again", systemImage: "eye.slash") }
            }
        }
        .transition(.opacity)
        .id(suggestion.id)
    }
}
