import SwiftData
import Foundation

enum SharedModelContainer {
    static let container: ModelContainer = {
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
}
