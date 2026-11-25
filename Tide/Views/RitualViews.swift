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
    @State private var items: [DraftItem]
    @State private var confirmDelete = false
    @FocusState private var focusedItem: UUID?

    /// One editable line in a protocol.
    struct DraftItem: Identifiable, Equatable {
        let id = UUID()
        var text: String
    }

    init(existing: Ritual? = nil, suggestedWindows: Set<CycleWindow> = []) {
        self.existing = existing
        _name = State(initialValue: existing?.name ?? "")
        _note = State(initialValue: existing?.note ?? "")
        _kind = State(initialValue: existing?.kind ?? .steep)
        _windows = State(initialValue: existing?.windows ?? suggestedWindows)
        _items = State(initialValue: (existing?.items ?? []).map { DraftItem(text: $0) })
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

                    protocolItems

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
                        windowRow(.menstrual, seed: 2)
                        windowRow(.follicular, seed: 9)
                        windowRow(.ovulatory, seed: 16)
                        lutealRow
                        windowRow(.earlyLuteal, seed: 23, nested: true)
                        windowRow(.lateLuteal, seed: 30, nested: true)

                        if let n = store.daysUntil(windows) {
                            Text(n == 0 ? "with your cycle as it is now, this shows today."
                                 : n == 1 ? "with your cycle as it is now, this first shows tomorrow."
                                 : "with your cycle as it is now, this first shows in \(n) days.")
                                .font(TideFont.label(10))
                                .foregroundStyle(Palette.soft)
                                .padding(.top, 12)
                                .transition(.opacity)
                        }
                    }

                    InkButton(title: "save", filled: true, seed: 33) {
                        guard canSave else { return }
                        store.save(Ritual(id: existing?.id ?? UUID(), name: name, note: note, kind: kind,
                                          windows: windows, items: items.map(\.text)))
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

    /// Optional list that turns a ritual into a protocol.
    private var protocolItems: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(items.isEmpty ? "more than one? (optional)" : "\(kind.itemNoun(2)) in this protocol")
            if items.isEmpty {
                Text("add each \(kind.itemNoun(1)) and they'll show together as one row.")
                    .font(TideFont.body(15))
                    .foregroundStyle(Palette.soft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach($items) { $item in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    WobblyCircle(seed: UInt64(abs(item.id.hashValue) % 50), wobble: 0.08, closed: true)
                        .fill(Palette.soft)
                        .frame(width: 7, height: 7)
                    TextField("\(kind.itemNoun(1))", text: $item.text,
                              prompt: Text("e.g. \(kind == .steep ? "nettle + raspberry leaf" : kind.itemNoun(1))").foregroundStyle(Palette.faint))
                        .font(TideFont.body(18))
                        .foregroundStyle(Palette.ink)
                        .focused($focusedItem, equals: item.id)
                        .submitLabel(.next)
                        .onSubmit { addItem() }
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { items.removeAll { $0.id == item.id } }
                    } label: {
                        Text("×")
                            .font(TideFont.body(20))
                            .foregroundStyle(Palette.soft)
                            .padding(.horizontal, 6)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("remove")
                }
                WobblyLine(seed: UInt64(abs(item.id.hashValue) % 40), amplitude: 0.8)
                    .stroke(Palette.faint, lineWidth: 1)
                    .frame(height: 3)
            }
            InkLink(title: "+ add a \(kind.itemNoun(1))") { addItem() }
                .padding(.top, 4)
        }
    }

    private func addItem() {
        let new = DraftItem(text: "")
        withAnimation(.easeInOut(duration: 0.2)) { items.append(new) }
        focusedItem = new.id
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

    /// "luteal" toggles both halves; the halves sit beneath it for finer timing.
    private var lutealRow: some View {
        let both: Set<CycleWindow> = [.earlyLuteal, .lateLuteal]
        let on = both.isSubset(of: windows)
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if on { windows.subtract(both) } else { windows.formUnion(both) }
            }
        } label: {
            HStack(spacing: 14) {
                HandCheck(isOn: on, color: Phase.luteal.color, seed: 37)
                Text("luteal")
                    .font(TideFont.body(19))
                    .foregroundStyle(Palette.ink)
                Spacer()
                Eyebrow("ovulation to period")
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: on)
    }

    private func windowRow(_ window: CycleWindow, seed: UInt64, nested: Bool = false) -> some View {
        let on = windows.contains(window)
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if on { windows.remove(window) } else { windows.insert(window) }
            }
        } label: {
            HStack(spacing: 14) {
                HandCheck(isOn: on, color: window.phase.color, seed: seed)
                    .scaleEffect(nested ? 0.75 : 1)
                Text(nested ? (window == .earlyLuteal ? "the first part" : "the last 5 days") : window.label)
                    .font(TideFont.body(nested ? 16 : 19))
                    .foregroundStyle(nested ? Palette.soft : Palette.ink)
                Spacer()
                if !nested { Eyebrow(window.hint) }
            }
            .padding(.vertical, nested ? 2 : 8)
            .padding(.leading, nested ? 34 : 0)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: on)
    }
}

// MARK: - Row

struct RitualRow: View {
    let ritual: Ritual
    /// "on today", "starts in 6 days"…
    var showing: String? = nil

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
                Eyebrow(ritual.isProtocol
                        ? "\(ritual.items.count) \(ritual.kind.itemNoun(ritual.items.count)) · \(CycleWindow.describe(ritual.windows))"
                        : "\(ritual.kind.label) · \(CycleWindow.describe(ritual.windows))")
                if let showing {
                    Text(showing)
                        .font(TideFont.body(14))
                        .italic()
                        .foregroundStyle(showing == "on today" ? Palette.ink : Palette.soft)
                }
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
                                Button { editing = ritual } label: { RitualRow(ritual: ritual, showing: store.showingLabel(ritual.windows)) }
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
                Button { editing = ritual } label: { RitualRow(ritual: ritual, showing: store.showingLabel(ritual.windows)) }
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
