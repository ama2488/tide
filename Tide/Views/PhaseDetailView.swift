import SwiftUI

/// The secondary layer: what's happening hormonally, how you might feel,
/// and the full menu for this phase — each with a tappable "why".
struct PhaseDetailView: View {
    @EnvironmentObject private var store: CycleStore
    @Environment(\.dismiss) private var dismiss

    let phase: Phase
    let calendar: CycleCalendar
    let today: Int?
    var showsClose: Bool = true

    var body: some View {
        let content = phase.content

        ZStack {
            PaperBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 40) {
                    if showsClose {
                        SheetHeader(title: phase.season) { dismiss() }
                    }

                    VStack(spacing: 14) {
                        PhaseGlyph(phase).frame(width: 120, height: 120)
                        Text(phase.name)
                            .font(TideFont.display(42))
                            .italic()
                        Text(content.tagline)
                            .font(TideFont.body(19))
                            .foregroundStyle(Palette.soft)
                    }
                    .frame(maxWidth: .infinity)

                    Prose(title: "what's happening", text: content.hormones)
                    HormoneChart(calendar: calendar, today: today)
                    Prose(title: "how you might feel", text: content.feel)

                    SuggestionList(kind: .nourish, items: content.foods, color: phase.color)
                    SuggestionList(kind: .steep, items: content.herbs, color: phase.color)
                    SuggestionList(kind: .move, items: content.movement, color: phase.color)
                    SuggestionList(kind: .tend, items: content.practices, color: phase.color)
                    if store.seedCycling {
                        SuggestionList(kind: .seeds, items: Library.seeds(for: phase), color: phase.color)
                    }

                    Disclaimer()
                }
                .padding(28)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

/// A quiet list. Names first; tap a name to unfold the why.
struct SuggestionList: View {
    let kind: SuggestionKind
    let items: [Suggestion]
    let color: Color

    @State private var open: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(kind.plural)
                .padding(.bottom, 6)

            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) { open = open == item.id ? nil : item.id }
                } label: {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(item.name)
                                .font(TideFont.body(19))
                                .foregroundStyle(Palette.ink)
                            Spacer()
                            Text(open == item.id ? "–" : "+")
                                .font(TideFont.label(15))
                                .foregroundStyle(Palette.soft)
                        }
                        if open == item.id {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(item.action)
                                    .font(TideFont.body(16))
                                    .italic()
                                    .foregroundStyle(color)
                                Text(item.why)
                                    .font(TideFont.body(15))
                                    .lineSpacing(3)
                                    .foregroundStyle(Palette.soft)
                            }
                            .fixedSize(horizontal: false, vertical: true)
                            .transition(.opacity)
                        }
                    }
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                WobblyLine(seed: UInt64(index + 50), amplitude: 0.8)
                    .stroke(Palette.faint, lineWidth: 1)
                    .frame(height: 3)
            }
        }
    }
}
