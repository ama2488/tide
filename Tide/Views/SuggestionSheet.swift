import SwiftUI

/// Tap an action → what it is, why it helps right now, and a way to check it off.
struct SuggestionSheet: View {
    @EnvironmentObject private var store: CycleStore
    @Environment(\.dismiss) private var dismiss

    let suggestion: Suggestion
    let phase: Phase
    let date: Date
    var canSwap: Bool = true

    var body: some View {
        let done = store.isDone(suggestion, on: date)

        ZStack {
            PaperBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    SheetHeader(title: "\(suggestion.kind.label) · \(phase.name)") { dismiss() }

                    VStack(alignment: .leading, spacing: 12) {
                        Text(suggestion.name)
                            .font(TideFont.display(36))
                            .italic()
                            .foregroundStyle(Palette.ink)
                        Text(suggestion.action)
                            .font(TideFont.body(19))
                            .foregroundStyle(Palette.soft)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    WobblyLine(seed: 4, amplitude: 1)
                        .stroke(phase.color, lineWidth: 1.5)
                        .frame(width: 64, height: 4)

                    Prose(title: "why now", text: suggestion.why)

                    InkButton(title: done ? "done — undo" : "mark as done", filled: !done, seed: 19) {
                        withAnimation(.easeInOut(duration: 0.25)) { store.toggle(suggestion, on: date) }
                        if !done { dismiss() }
                    }
                    .padding(.top, 8)

                    if suggestion.kind == .seeds {
                        Text("not doing seeds? turn seed cycling off in settings.")
                            .font(TideFont.label(10))
                            .foregroundStyle(Palette.soft)
                            .frame(maxWidth: .infinity)
                    } else {
                        VStack(spacing: 18) {
                            if canSwap {
                                InkLink(title: "show me another") {
                                    dismiss()
                                    withAnimation(.easeInOut(duration: 0.35)) { store.swap(suggestion, on: date) }
                                }
                            }
                            Button {
                                dismiss()
                                withAnimation(.easeInOut(duration: 0.35)) { store.hide(suggestion) }
                            } label: {
                                Text("don't suggest this again")
                                    .font(TideFont.label(11))
                                    .tracking(1)
                                    .underline()
                                    .foregroundStyle(Palette.soft)
                                    .padding(6)
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    if suggestion.kind == .steep {
                        Disclaimer()
                    }
                }
                .padding(28)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Palette.paper)
        .presentationCornerRadius(28)
        .presentationDragIndicator(.visible)
    }
}
