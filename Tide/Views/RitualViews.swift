import SwiftUI

// MARK: - Editor

struct RitualEditor: View {
    @EnvironmentObject private var store: CycleStore
    @Environment(\.dismiss) private var dismiss

    let existing: Ritual?
    @State private var name: String
    @State private var note: String
    @State private var kind: SuggestionKind
    @State private var windows: Set<CycleWindow>
    @State private var confirmDelete = false

    init(existing: Ritual? = nil, suggestedWindows: Set<CycleWindow> = []) {
        self.existing = existing
        _name = State(initialValue: existing?.name ?? "")
        _note = State(initialValue: existing?.note ?? "")
        _kind = State(initialValue: existing?.kind ?? .steep)
        _windows = State(initialValue: existing?.windows ?? suggestedWindows)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !windows.isEmpty
    }

    var body: some View {
        ZStack {
            PaperBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 36) {
                    SheetHeader(title: existing == nil ? "add a ritual" : "edit ritual") { dismiss() }

                    field("what is it?", text: $name, prompt: "e.g. moon mother · follicular tea", size: 24, seed: 3)
                    field("a note for yourself", text: $note, prompt: "optional · e.g. one cup each morning", size: 17, seed: 9)

                    VStack(alignment: .leading, spacing: 14) {
                        Eyebrow("kind")
                        HStack(spacing: 10) {
                            ForEach(Ritual.kinds, id: \.self) { chip($0) }
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Eyebrow("when")
                            Spacer()
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    windows = windows.count == CycleWindow.allCases.count ? [] : Set(CycleWindow.allCases)
                                }
                            } label: {
                                Text(windows.count == CycleWindow.allCases.count ? "clear" : "every day")
                                    .font(TideFont.label(11))
                                    .tracking(1)
                                    .underline()
                                    .foregroundStyle(Palette.soft)
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                        }
                        ForEach(Array(CycleWindow.allCases.enumerated()), id: \.element) { index, window in
                            windowRow(window, seed: UInt64(index * 7 + 2))
                        }
                    }

                    InkButton(title: "save", filled: true, seed: 33) {
                        guard canSave else { return }
                        store.save(Ritual(id: existing?.id ?? UUID(), name: name, note: note, kind: kind, windows: windows))
                        dismiss()
                    }
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.35)

                    if existing != nil {
                        Button { confirmDelete = true } label: {
                            Text("delete this ritual")
                                .font(TideFont.label(12))
                                .tracking(1.2)
                                .underline()
                                .foregroundStyle(Palette.soft)
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(28)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .presentationDetents([.large])
        .presentationBackground(Palette.paper)
        .presentationCornerRadius(28)
        .confirmationDialog("delete this ritual?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("delete", role: .destructive) {
                if let existing { store.delete(existing) }
                dismiss()
            }
            Button("cancel", role: .cancel) {}
        }
    }

    private func field(_ label: String, text: Binding<String>, prompt: String, size: CGFloat, seed: UInt64) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(label)
            TextField(label, text: text, prompt: Text(prompt).foregroundStyle(Palette.faint), axis: .vertical)
                .font(TideFont.body(size))
                .foregroundStyle(Palette.ink)
            WobblyLine(seed: seed, amplitude: 1)
                .stroke(Palette.ink.opacity(0.4), lineWidth: 1)
                .frame(height: 4)
        }
    }

    private func chip(_ k: SuggestionKind) -> some View {
        let on = kind == k
        let seed = UInt64(k.rawValue.count * 5 + 1)
        return Button { withAnimation(.easeInOut(duration: 0.2)) { kind = k } } label: {
            Text(k.label)
                .font(TideFont.label(12))
                .tracking(1)
                .foregroundStyle(on ? Palette.paper : Palette.ink)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background {
                    ZStack {
                        WobblyCapsule(seed: seed, amount: 1).fill(on ? Palette.ink : Color.clear)
                        WobblyCapsule(seed: seed, amount: 1).stroke(Palette.ink, lineWidth: 1)
                    }
                }
        }
        .buttonStyle(PressStyle())
    }

    private func windowRow(_ window: CycleWindow, seed: UInt64) -> some View {
        let on = windows.contains(window)
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if on { windows.remove(window) } else { windows.insert(window) }
            }
        } label: {
            HStack(spacing: 14) {
                HandCheck(isOn: on, color: window.phase.color, seed: seed)
                Text(window.label)
                    .font(TideFont.body(19))
                    .foregroundStyle(Palette.ink)
                Spacer()
                Eyebrow(window.hint)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: on)
    }
}

// MARK: - Row

struct RitualRow: View {
    let ritual: Ritual

    var body: some View {
        HStack(spacing: 14) {
            HStack(spacing: 3) {
                ForEach(CycleWindow.allCases.filter { ritual.windows.contains($0) }) { w in
                    WobblyCircle(seed: UInt64(w.rawValue.count), wobble: 0.08, closed: true)
                        .fill(w.phase.color)
                        .frame(width: 7, height: 7)
                }
            }
            .frame(minWidth: 14, alignment: .leading)
            VStack(alignment: .leading, spacing: 4) {
                Text(ritual.name)
                    .font(TideFont.body(19))
                    .foregroundStyle(Palette.ink)
                    .multilineTextAlignment(.leading)
                Eyebrow("\(ritual.kind.label) · \(CycleWindow.describe(ritual.windows))")
            }
            Spacer()
            Text("→").font(TideFont.body(16)).foregroundStyle(Palette.soft)
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

// MARK: - All rituals (from settings)

struct RitualsView: View {
    @EnvironmentObject private var store: CycleStore
    @State private var editing: Ritual?
    @State private var adding = false

    var body: some View {
        ZStack {
            PaperBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 32) {
                    VStack(alignment: .leading, spacing: 12) {
                        Eyebrow("your rituals")
                        Text("the teas, foods and practices you already love, on the days they belong.")
                            .font(TideFont.display(26))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if store.rituals.isEmpty {
                        Text("add one and tide will show it on the right days, in place of its own suggestion of the same kind.")
                            .font(TideFont.body(16))
                            .lineSpacing(3)
                            .foregroundStyle(Palette.soft)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(sorted) { ritual in
                                Button { editing = ritual } label: { RitualRow(ritual: ritual) }
                                    .buttonStyle(.plain)
                                WobblyLine(seed: UInt64(ritual.name.count + 3), amplitude: 0.8)
                                    .stroke(Palette.faint, lineWidth: 1)
                                    .frame(height: 3)
                            }
                        }
                    }

                    InkButton(title: "add a ritual", seed: 43) { adding = true }
                }
                .padding(28)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(item: $editing) { RitualEditor(existing: $0).environmentObject(store) }
        .sheet(isPresented: $adding) { RitualEditor().environmentObject(store) }
    }

    /// In cycle order, by the first window each belongs to.
    private var sorted: [Ritual] {
        func first(_ r: Ritual) -> Int { CycleWindow.allCases.firstIndex { r.windows.contains($0) } ?? 99 }
        return store.rituals.sorted { (first($0), $0.name) < (first($1), $1.name) }
    }
}

// MARK: - On a phase page

struct PhaseRitualsSection: View {
    @EnvironmentObject private var store: CycleStore
    let phase: Phase
    @State private var editing: Ritual?
    @State private var adding = false

    var body: some View {
        let windows = CycleWindow.windows(for: phase)
        let mine = store.rituals.filter { !$0.windows.isDisjoint(with: windows) }

        VStack(alignment: .leading, spacing: 0) {
            Eyebrow("your rituals")
                .padding(.bottom, 6)
            ForEach(mine) { ritual in
                Button { editing = ritual } label: { RitualRow(ritual: ritual) }
                    .buttonStyle(.plain)
                WobblyLine(seed: UInt64(ritual.name.count + 7), amplitude: 0.8)
                    .stroke(Palette.faint, lineWidth: 1)
                    .frame(height: 3)
            }
            InkLink(title: mine.isEmpty ? "add your own for \(phase.name)" : "add another") { adding = true }
                .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(item: $editing) { RitualEditor(existing: $0).environmentObject(store) }
        .sheet(isPresented: $adding) { RitualEditor(suggestedWindows: windows).environmentObject(store) }
    }
}
