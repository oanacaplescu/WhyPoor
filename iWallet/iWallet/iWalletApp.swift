import SwiftUI
import SwiftData

@main
struct iWalletApp: App {
    @State private var showingSplash = true

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Expense.self, ExpenseCategory.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            print("⚠️ CloudKit ModelContainer failed to load: \(error)")
            print("⚠️ Falling back to local-only, in-memory storage for this session.")
            let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return (try? ModelContainer(for: schema, configurations: [fallbackConfig]))
                ?? (try! ModelContainer(for: schema))
        }
    }()

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
        .modelContainer(sharedModelContainer)
    }
}
