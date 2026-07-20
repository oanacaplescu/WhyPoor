//
//  iWalletApp.swift
//  iWallet
//
//  Created by Oana Cozma on 20/07/2026.
//

import SwiftUI
import SwiftData

@main
struct iWalletApp: App {
    var sharedModelContainer: ModelContainer = {
            let schema = Schema([Expense.self, ExpenseCategory.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            return try! ModelContainer(for: schema, configurations: [config])
        }()

        var body: some Scene {
            WindowGroup {
                ExpenseListView()
            }
            .modelContainer(sharedModelContainer)
        }
}
