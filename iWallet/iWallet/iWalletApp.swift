import SwiftUI
import SwiftData

@main
struct iWalletApp: App {
    @State private var showingSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ExpenseListView()
                    .tint(AppTheme.accent)

                if showingSplash {
                    SplashView()
                        .transition(.opacity)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showingSplash = false
                    }
                }
            }
        }
        .modelContainer(SharedModelContainer.container)
    }
}
