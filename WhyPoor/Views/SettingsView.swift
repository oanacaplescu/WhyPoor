import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var categories: [ExpenseCategory]
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]

    @AppStorage("salaryDay") private var salaryDay: Int = 1
    @AppStorage("currencyCode", store: AppGroup.sharedDefaults) private var currencyCode: String = Locale.current.currency?.identifier ?? "USD"
    
    @State private var exportURL: URL?
    @State private var showingShareSheet = false
    @State private var showingImport = false

    private let commonCurrencies = ["USD", "EUR", "GBP", "RON", "CHF", "JPY", "CAD", "AUD"]

    var body: some View {
        Form {
            Section("Salary day") {
                Stepper("Day \(salaryDay) of each month", value: $salaryDay, in: 1...31)
                Text("Your monthly period will run from day \(salaryDay) to day \(salaryDay - 1) of the next month.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Currency") {
                Picker("Currency", selection: $currencyCode) {
                    ForEach(commonCurrencies, id: \.self) { code in
                        Text(code).tag(code)
                    }
                }
            }
            
            Section("Export") {
                Button {
                    exportCSV()
                } label: {
                    Label("Export All Expenses (CSV)", systemImage: "square.and.arrow.up")
                }
            }

            Section("Import") {
                Button {
                    showingImport = true
                } label: {
                    Label("Import Expenses (CSV)", systemImage: "square.and.arrow.down")
                }
            }

            #if DEBUG
            Section("Testing") {
                Button("Generate Sample Data (90 days)") {
                    generateSampleData()
                }
                Button("Delete All Expenses", role: .destructive) {
                    deleteAllExpenses()
                }
                Button("Delete All Categories", role: .destructive) {
                    deleteAllCategories()
                }
            }
            #endif
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showingShareSheet) {
            if let exportURL {
                ShareSheet(activityItems: [exportURL])
            }
        }
        .sheet(isPresented: $showingImport) {
            ImportCSVView()
        }
    }
    
    private func exportCSV() {
        guard let url = ExpenseCSVExporter.writeToTempFile(expenses: allExpenses) else { return }
        exportURL = url
        showingShareSheet = true
    }

    #if DEBUG
    private func generateSampleData() {
        let sampleCategories = [
            ("Groceries", "cart.fill"),
            ("Rent", "house.fill"),
            ("Transport", "car.fill"),
            ("Dining Out", "fork.knife"),
            ("Entertainment", "gamecontroller.fill"),
            ("Utilities", "bolt.fill"),
            ("Shopping", "bag.fill"),
            ("Health", "heart.fill")
        ]

        var allCategories = categories
        for (name, icon) in sampleCategories {
            if !allCategories.contains(where: { $0.name == name }) {
                let colorHex = ExpenseCategory.palette[allCategories.count % ExpenseCategory.palette.count]
                let newCat = ExpenseCategory(name: name, colorHex: colorHex, iconName: icon)
                context.insert(newCat)
                allCategories.append(newCat)
            }
        }

        let descriptions = ["", "", "", "weekend trip", "with friends", "monthly bill", "impulse buy", "gift"]
        let calendar = Calendar.current

        for dayOffset in 0..<90 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: .now) else { continue }
            let expenseCount = Int.random(in: 0...2)
            for _ in 0..<expenseCount {
                let category = allCategories.randomElement()!
                let amount = Decimal(Double.random(in: 5...250)).rounded(2)
                let desc = descriptions.randomElement()!
                let expense = Expense(
                    amount: amount,
                    category: category.name,
                    expenseDescription: desc.isEmpty ? nil : desc,
                    date: date
                )
                context.insert(expense)
            }
        }

        try? context.save()
    }

    private func deleteAllExpenses() {
        let descriptor = FetchDescriptor<Expense>()
        if let all = try? context.fetch(descriptor) {
            for expense in all {
                context.delete(expense)
            }
        }
        try? context.save()
    }
    
    private func deleteAllCategories() {
        let descriptor = FetchDescriptor<ExpenseCategory>()
        if let all = try? context.fetch(descriptor) {
            for category in all {
                context.delete(category)
            }
        }
        try? context.save()
    }
    #endif
}

private extension Decimal {
    func rounded(_ scale: Int) -> Decimal {
        var result = Decimal()
        var mutableSelf = self
        NSDecimalRound(&result, &mutableSelf, scale, .plain)
        return result
    }
}
