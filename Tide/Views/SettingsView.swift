import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: CycleStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    var body: some View {
        ZStack {
            PaperBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 44) {
                    SheetHeader(title: "settings") { dismiss() }

                    VStack(alignment: .leading, spacing: 12) {
                        Eyebrow("last period began")
                        DatePicker("last period began", selection: $store.lastPeriodStart, in: ...Date(), displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                    }

                    VStack(spacing: 16) {
                        Eyebrow("cycle length")
                        InkStepper(value: $store.cycleLength, range: 21...45, unit: "days")
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 16) {
                        Eyebrow("period length")
                        InkStepper(value: $store.periodLength, range: 2...10, unit: "days")
                    }
                    .frame(maxWidth: .infinity)

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
        .confirmationDialog("start over? this clears your settings.", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("start over", role: .destructive) {
                dismiss()
                store.reset()
            }
            Button("cancel", role: .cancel) {}
        }
    }
}
