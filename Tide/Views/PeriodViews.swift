import SwiftUI

// MARK: - Today prompt

/// A soft card that appears only around the edges of a period.
struct PeriodPromptCard: View {
    let prompt: PeriodPrompt
    let onToday: () -> Void
    let onEarlier: () -> Void
    let onNotYet: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            HStack(spacing: 10) {
                WobblyCircle(seed: 8, wobble: 0.08, closed: true)
                    .fill(Phase.menstrual.color)
                    .frame(width: 10, height: 10)
                Text(prompt.question)
                    .font(TideFont.body(20))
                    .italic()
                    .foregroundStyle(Palette.ink)
            }

            HStack(spacing: 0) {
                choice(prompt.todayLabel, emphasis: true, action: onToday)
                dot
                choice("earlier", action: onEarlier)
                dot
                choice("not yet", action: onNotYet)
            }
        }
        .padding(.vertical, 22)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background {
            ZStack {
                WobblyCapsule(seed: 14, amount: 1.4, cornerRadius: 26)
                    .fill(Phase.menstrual.color.opacity(0.09))
                WobblyCapsule(seed: 14, amount: 1.4, cornerRadius: 26)
                    .stroke(Palette.ink.opacity(0.7), lineWidth: 1)
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: prompt)
    }

    private var dot: some View {
        Text("·").font(TideFont.label(12)).foregroundStyle(Palette.faint)
    }

    private func choice(_ title: String, emphasis: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(TideFont.label(12))
                .tracking(1)
                .underline(emphasis)
                .foregroundStyle(emphasis ? Palette.ink : Palette.soft)
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressStyle())
    }
}

// MARK: - Log / edit

struct LogPeriodSheet: View {
    @EnvironmentObject private var store: CycleStore
    @Environment(\.dismiss) private var dismiss

    let existing: PeriodEntry?
    @State private var start: Date
    @State private var hasEnded: Bool
    @State private var end: Date
    @State private var confirmDelete = false

    init(existing: PeriodEntry?, suggestedStart: Date = Date(), endedByDefault: Bool = false) {
        self.existing = existing
        let cal = Calendar.current
        let start = existing?.start ?? cal.startOfDay(for: suggestedStart)
        let yesterday = cal.date(byAdding: .day, value: -1, to: cal.startOfDay(for: Date())) ?? Date()
        _start = State(initialValue: start)
        _hasEnded = State(initialValue: existing?.end != nil || endedByDefault)
        _end = State(initialValue: existing?.end ?? max(start, endedByDefault ? yesterday : Date()))
    }

    var body: some View {
        ZStack {
            PaperBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 36) {
                    SheetHeader(title: existing == nil ? "log a period" : "edit period") { dismiss() }

                    VStack(alignment: .leading, spacing: 12) {
                        Eyebrow("first day")
                        DatePicker("first day", selection: $start, in: ...Date(), displayedComponents: .date)
                            .labelsHidden()
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        Toggle(isOn: $hasEnded.animation(.easeInOut(duration: 0.25))) {
                            Eyebrow("it has ended")
                        }
                        .tint(Phase.menstrual.color)

                        if hasEnded {
                            VStack(alignment: .leading, spacing: 12) {
                                Eyebrow("last day")
                                DatePicker("last day", selection: $end,
                                           in: Calendar.current.startOfDay(for: start)...Date(),
                                           displayedComponents: .date)
                                    .labelsHidden()
                            }
                            .transition(.opacity)
                        }
                    }

                    if existing?.source == .health {
                        Text("imported from apple health. edits here stay in tide and may be refreshed on the next sync.")
                            .font(TideFont.label(10))
                            .lineSpacing(3)
                            .foregroundStyle(Palette.soft)
                    }

                    InkButton(title: "save", filled: true, seed: 31) {
                        store.save(PeriodEntry(
                            id: existing?.id ?? UUID(),
                            start: start,
                            end: hasEnded ? max(end, start) : nil,
                            source: existing?.source ?? .tide
                        ))
                        dismiss()
                    }

                    if existing != nil {
                        Button { confirmDelete = true } label: {
                            Text("delete this period")
                                .font(TideFont.label(12))
                                .tracking(1.2)
                                .foregroundStyle(Palette.soft)
                                .underline()
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(28)
            }
        }
        .presentationDetents([.large])
        .presentationBackground(Palette.paper)
        .presentationCornerRadius(28)
        .confirmationDialog("delete this period?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("delete", role: .destructive) {
                if let existing { store.delete(existing) }
                dismiss()
            }
            Button("cancel", role: .cancel) {}
        }
    }
}

// MARK: - History

/// Your rhythm in one sentence, then every period you've logged.
struct PeriodHistoryView: View {
    @EnvironmentObject private var store: CycleStore
    @State private var editing: PeriodEntry?
    @State private var adding = false

    var body: some View {
        let newestFirst = Array(store.periods.reversed())

        ZStack {
            PaperBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 36) {
                    summary

                    VStack(spacing: 0) {
                        ForEach(Array(newestFirst.enumerated()), id: \.element.id) { index, entry in
                            Button { editing = entry } label: { row(entry) }
                                .buttonStyle(.plain)

                            if index < newestFirst.count - 1 {
                                gap(from: newestFirst[index + 1], to: entry)
                            }
                        }
                    }

                    InkButton(title: "log a period", seed: 37) { adding = true }

                    Text("tap a period to edit it. tide uses your last \(CycleStats.recentWindow) cycles, and skips gaps that look like a missed log.")
                        .font(TideFont.label(10))
                        .lineSpacing(3)
                        .foregroundStyle(Palette.soft)
                }
                .padding(28)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(item: $editing) { LogPeriodSheet(existing: $0).environmentObject(store) }
        .sheet(isPresented: $adding) { LogPeriodSheet(existing: nil).environmentObject(store) }
    }

    @ViewBuilder
    private var summary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow("your rhythm")
            if let cycle = store.learnedCycleLength {
                let period = store.learnedPeriodLength.map { ", with periods of about \($0) days" } ?? ""
                Text("your cycles average \(cycle) days\(period).")
                    .font(TideFont.display(28))
                    .fixedSize(horizontal: false, vertical: true)
                Eyebrow("from your last \(store.cyclesLogged) cycles")
            } else {
                let needed = max(1, 3 - store.periods.count)
                Text("log \(needed) more \(needed == 1 ? "period" : "periods") and tide will learn your rhythm.")
                    .font(TideFont.display(28))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func row(_ entry: PeriodEntry) -> some View {
        HStack(alignment: .center, spacing: 14) {
            WobblyCircle(seed: UInt64(abs(Int(entry.start.timeIntervalSince1970 / 86_400)) % 97), wobble: 0.08, closed: true)
                .fill(Phase.menstrual.color)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 4) {
                Text(range(entry))
                    .font(TideFont.body(19))
                    .foregroundStyle(Palette.ink)
                if entry.source == .health { Eyebrow("from apple health") }
            }
            Spacer()
            Eyebrow(entry.lengthInDays().map { "\($0) \($0 == 1 ? "day" : "days")" } ?? "ongoing")
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    /// The cycle length between two periods, drawn as a quiet connector.
    private func gap(from older: PeriodEntry, to newer: PeriodEntry) -> some View {
        let days = CycleStats.days(from: older.start, to: newer.start)
        return HStack(spacing: 10) {
            WobblyLine(seed: UInt64(days), amplitude: 0.8).stroke(Palette.faint, lineWidth: 1).frame(height: 3)
            Eyebrow("\(days)-day cycle")
                .fixedSize()
            WobblyLine(seed: UInt64(days + 1), amplitude: 0.8).stroke(Palette.faint, lineWidth: 1).frame(height: 3)
        }
        .padding(.vertical, 4)
    }

    private func range(_ entry: PeriodEntry) -> String {
        let cal = Calendar.current
        let thisYear = cal.component(.year, from: Date())
        func fmt(_ d: Date) -> String {
            let style: Date.FormatStyle = cal.component(.year, from: d) == thisYear
                ? .dateTime.month(.abbreviated).day()
                : .dateTime.month(.abbreviated).day().year()
            return d.formatted(style).lowercased()
        }
        guard let end = entry.end, end != entry.start else { return fmt(entry.start) }
        return "\(fmt(entry.start)) – \(fmt(end))"
    }
}
