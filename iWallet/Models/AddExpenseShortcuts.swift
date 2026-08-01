import AppIntents

struct AddExpenseShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddExpenseIntent(),
            phrases: [
                "Add an expense in \(.applicationName)",
                "Log an expense in \(.applicationName)",
                "Add expense to \(.applicationName)",
                "Add an expense for \(\.$category) in \(.applicationName)",
                "Log an expense for \(\.$category) in \(.applicationName)"
            ],
            shortTitle: "Add Expense",
            systemImageName: "plus.circle.fill"
        )
    }
}
