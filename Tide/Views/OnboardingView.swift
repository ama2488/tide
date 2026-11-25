import SwiftUI

/// Three questions, one per screen. That's all tide needs.
struct OnboardingView: View {
    @EnvironmentObject private var store: CycleStore

    @State private var step = 0
    @State private var start = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var cycle = 28
    @State private var period = 5

    @State private var connecting = false

    /// 0 welcome · 1 last period · 2 cycle · 3 period · 4 apple health (if available)
    private var lastStep: Int { store.healthAvailable ? 4 : 3 }

    var body: some View {
        ZStack {
            PaperBackground()

            VStack(spacing: 0) {
                HStack {
                    if step > 0 {
                        Button { withAnimation(.easeInOut(duration: 0.4)) { step -= 1 } } label: {
                            Text("back")
                                .font(TideFont.label(12))
                                .tracking(1.2)
                                .foregroundStyle(Palette.soft)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                    dots
                }
                .frame(height: 36)

                Spacer(minLength: 16)

                Group {
                    switch step {
                    case 0: welcome
                    case 1: lastPeriod
                    case 2: cycleLength
                    case 3: periodLength
                    default: appleHealth
                    }
                }
                .id(step)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .offset(y: 12)),
                    removal: .opacity
                ))

                Spacer(minLength: 16)

                if step == 4 {
                    VStack(spacing: 18) {
                        InkButton(title: connecting ? "connecting…" : "connect apple health", filled: true, seed: 9) {
                            connecting = true
                            Task {
                                saveAnswers()
                                await store.connectHealth()
                                store.hasOnboarded = true
                            }
                        }
                        .disabled(connecting)
                        InkLink(title: "skip for now") { finish() }
                    }
                } else {
                    InkButton(title: step == 0 ? "begin" : (step == lastStep ? "meet your day" : "next"), filled: true, seed: UInt64(step + 3)) {
                        advance()
                    }
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
        }
    }

    // MARK: steps

    private var welcome: some View {
        VStack(spacing: 28) {
            HStack(spacing: 10) {
                ForEach(Phase.allCases) { PhaseGlyph($0).frame(width: 58, height: 58) }
            }
            VStack(spacing: 14) {
                Text("tide")
                    .font(TideFont.display(68))
                    .italic()
                Text("a gentle daily guide to living with your cycle, not against it.")
                    .font(TideFont.body(19))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Palette.soft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var lastPeriod: some View {
        VStack(spacing: 24) {
            question("when did your last period begin?", hint: "your best guess is fine.")
            DatePicker("last period began", selection: $start, in: ...Date(), displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .tint(Phase.menstrual.color)
        }
    }

    private var cycleLength: some View {
        VStack(spacing: 40) {
            question("how long is your cycle, usually?", hint: "first day of one period to the first day of the next. 28 is a fine guess.")
            InkStepper(value: $cycle, range: 21...45, unit: "days")
        }
    }

    private var periodLength: some View {
        VStack(spacing: 40) {
            question("and how many days do you bleed?", hint: "you can change any of this later.")
            InkStepper(value: $period, range: 2...10, unit: "days")
        }
    }

    private var appleHealth: some View {
        VStack(spacing: 32) {
            ZStack {
                WobblyCircle(seed: 90, wobble: 0.07, closed: true)
                    .fill(Phase.menstrual.color.opacity(0.16))
                WobblyCircle(seed: 91, wobble: 0.04)
                    .stroke(Palette.ink, lineWidth: 1.2)
                    .padding(26)
                Text("♡")
                    .font(TideFont.display(40))
                    .foregroundStyle(Phase.menstrual.color)
            }
            .frame(width: 140, height: 140)
            question("already track your cycle somewhere?",
                     hint: "tide can read the period days in apple health — from apple's cycle tracking, oura and other apps. it only reads, and nothing leaves your phone.")
        }
    }

    private func question(_ text: String, hint: String) -> some View {
        VStack(spacing: 12) {
            Text(text)
                .font(TideFont.display(30))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text(hint)
                .font(TideFont.label(11))
                .tracking(0.6)
                .lineSpacing(3)
                .multilineTextAlignment(.center)
                .foregroundStyle(Palette.soft)
        }
    }

    private var dots: some View {
        HStack(spacing: 8) {
            ForEach(0...lastStep, id: \.self) { i in
                WobblyCircle(seed: UInt64(i + 60), wobble: 0.1, closed: true)
                    .fill(i == step ? Palette.ink : Palette.faint)
                    .frame(width: 7, height: 7)
            }
        }
    }

    private func advance() {
        if step < lastStep {
            withAnimation(.easeInOut(duration: 0.4)) { step += 1 }
        } else {
            finish()
        }
    }

    private func saveAnswers() {
        store.lastPeriodStart = Calendar.current.startOfDay(for: start)
        store.cycleLength = cycle
        store.periodLength = period
        store.logPeriodStart(on: start)
    }

    private func finish() {
        saveAnswers()
        store.hasOnboarded = true
    }
}
