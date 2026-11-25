import SwiftUI

@main
struct TideApp: App {
    @StateObject private var store = CycleStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .tint(Palette.ink)
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var store: CycleStore

    var body: some View {
        ZStack {
            if store.hasOnboarded {
                TodayView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: store.hasOnboarded)
    }
}
