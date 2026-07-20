import SwiftUI
import SwiftData

struct ExpenseListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
    @Query private var allCategories: [ExpenseCategory]
    @AppStorage("salaryDay") private var salaryDay: Int = 1
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD"

    @State private var showingAddExpense = false
    @State private var showingSettings = false

    private var currentPeriod: BillingPeriod {
        BillingPeriod.containing(date: .now, salaryDay: salaryDay)
    }

    private var periodExpenses: [Expense] {
        allExpenses.filter { $0.date >= currentPeriod.start && $0.date <= currentPeriod.end }
    }

    private var total: Decimal {
        periodExpenses.reduce(0) { $0 + $1.amount }
    }

    private func style(for categoryName: String) -> (color: Color, icon: String) {
        if let match = allCategories.first(where: { $0.name == categoryName }) {
            return (Color(hex: match.colorHex), match.iconName)
        }
        return (.gray, "tag.fill")
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("Total this period")
                        Spacer()
                        Text(total, format: .currency(code: currencyCode))
                            .bold()
                    }
                }
                Section {
                    ForEach(periodExpenses) { expense in
                        let style = style(for: expense.category)
                        HStack(spacing: 12) {
                            Image(systemName: style.icon)
                                .foregroundStyle(.white)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(style.color))

                            VStack(alignment: .leading) {
                                Text(expense.category)
                                if let desc = expense.expenseDescription, !desc.isEmpty {
                                    Text(desc)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()
                            Text(expense.amount, format: .currency(code: currencyCode))
                        }
                    }
                    .onDelete(perform: deleteExpenses)
                }
            }
            .navigationTitle(periodTitle)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAddExpense = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView()
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack { SettingsView() }
            }
        }
    }

    private var periodTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: currentPeriod.start)) – \(formatter.string(from: currentPeriod.end))"
    }

    private func deleteExpenses(at offsets: IndexSet) {
        for index in offsets {
            context.delete(periodExpenses[index])
        }
    }
}
