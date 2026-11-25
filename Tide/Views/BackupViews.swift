import SwiftUI
import UniformTypeIdentifiers

/// Pick a backup file → confirm → restore. Used in settings and on the welcome screen.
struct BackupImporter: ViewModifier {
    @EnvironmentObject private var store: CycleStore
    @Binding var isPresented: Bool
    var onRestored: () -> Void = {}

    @State private var pending: Backup?
    @State private var confirming = false
    @State private var error: String?

    func body(content: Content) -> some View {
        content
            .fileImporter(isPresented: $isPresented, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url):
                    let scoped = url.startAccessingSecurityScopedResource()
                    defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                    do {
                        pending = try Backup.decode(Data(contentsOf: url))
                        confirming = true
                    } catch {
                        self.error = (error as? LocalizedError)?.errorDescription ?? "that file couldn't be opened."
                    }
                case .failure:
                    error = "that file couldn't be opened."
                }
            }
            .confirmationDialog(
                "replace everything on this phone with this backup?",
                isPresented: $confirming,
                titleVisibility: .visible,
                presenting: pending
            ) { backup in
                Button("restore") {
                    withAnimation(.easeInOut(duration: 0.4)) { store.restore(backup) }
                    onRestored()
                }
                Button("cancel", role: .cancel) {}
            } message: { backup in
                Text(backup.summary)
            }
            .alert("couldn't restore", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("ok", role: .cancel) {}
            } message: {
                Text(error ?? "")
            }
    }
}

extension View {
    func backupImporter(isPresented: Binding<Bool>, onRestored: @escaping () -> Void = {}) -> some View {
        modifier(BackupImporter(isPresented: isPresented, onRestored: onRestored))
    }
}

/// The "your data" block in settings.
struct BackupSection: View {
    @EnvironmentObject private var store: CycleStore
    @State private var importing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Eyebrow("your data")
            Text("save everything — periods, rituals and settings — as one file. keep it in files or icloud drive, or send it to yourself, and restore it on any phone.")
                .font(TideFont.body(15))
                .lineSpacing(3)
                .foregroundStyle(Palette.soft)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 28) {
                ShareLink(item: store.makeBackup(), preview: SharePreview("persi backup")) {
                    InkLinkLabel(title: "export a backup")
                }
                .buttonStyle(PressStyle())

                InkLink(title: "restore") { importing = true }
            }
            .padding(.top, 4)

            Text("apple health access isn't included; reconnect it on the new phone.")
                .font(TideFont.label(10))
                .foregroundStyle(Palette.soft)
        }
        .backupImporter(isPresented: $importing)
    }
}
