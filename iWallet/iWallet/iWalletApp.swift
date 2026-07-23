import SwiftUI
import SwiftData

@main
struct iWalletApp: App {
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
            // Fails silently (no crash, no data wipe, no user-facing alert) —
            // logs to console only, so this doesn't destroy local data if
            // CloudKit is temporarily unavailable (network, account, provisioning).
            print("⚠️ CloudKit ModelContainer failed to load: \(error)")
            print("⚠️ Falling back to local-only, in-memory storage for this session.")

            let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return (try? ModelContainer(for: schema, configurations: [fallbackConfig]))
                ?? (try! ModelContainer(for: schema))
        }
    }()

    var body: some Scene {
        WindowGroup {
            ExpenseListView()
                .tint(AppTheme.accent)
        }
        .modelContainer(sharedModelContainer)
    }
}
