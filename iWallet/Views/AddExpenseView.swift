import SwiftUI
import SwiftData

struct AddExpenseView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ExpenseCategory.name) private var categories: [ExpenseCategory]
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD"

    @State private var amountText = ""
    @State private var selectedCategory: ExpenseCategory?
    @State private var newCategoryName = ""
    @State private var newCategoryIcon: String = ExpenseCategory.icons.first ?? "tag.fill"
    @State private var description = ""
    @State private var date = Date.now
    @State private var showingNewCategoryField = false

    private let gridColumns = Array(repeating: GridItem(.flexible()), count: 6)

    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    HStack {
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                        Text(currencyCode)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Category") {
                    if !categories.isEmpty {
                        Picker("Category", selection: $selectedCategory) {
                            Text("None").tag(nil as ExpenseCategory?)
                            ForEach(categories) { cat in
                                Label {
                                    Text(cat.name)
                                } icon: {
                                    Image(systemName: cat.iconName)
                                        .foregroundStyle(Color(hex: cat.colorHex))
                                }
                                .tag(cat as ExpenseCategory?)
                            }
                        }
                        .disabled(showingNewCategoryField)
                        .opacity(showingNewCategoryField ? 0.4 : 1.0)
                    }
                    Toggle("Add new category", isOn: $showingNewCategoryField)

                    if showingNewCategoryField {
                        TextField("Category name", text: $newCategoryName)

                        Text("Icon")
                        LazyVGrid(columns: gridColumns, spacing: 10) {
                            ForEach(ExpenseCategory.icons, id: \.self) { icon in
                                Image(systemName: icon)
                                    .font(.title3)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle().fill(newCategoryIcon == icon ? Color.accentColor.opacity(0.2) : Color.clear)
                                    )
                                    .foregroundStyle(newCategoryIcon == icon ? Color.accentColor : .primary)
                                    .onTapGesture {
                                        newCategoryIcon = icon
                                    }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Description (optional)") {
                    TextField("e.g. groceries at the market", text: $description)
                }

                Section("Date") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
            }
            .navigationTitle("Add Expense")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(Decimal(string: amountText) == nil)
                }
            }
        }
    }

    private func save() {
        guard let amount = Decimal(string: amountText) else { return }

        var categoryName = selectedCategory?.name ?? ""
        if showingNewCategoryField, !newCategoryName.isEmpty {
            let colorHex = ExpenseCategory.palette[categories.count % ExpenseCategory.palette.count]
            let newCategory = ExpenseCategory(name: newCategoryName, colorHex: colorHex, iconName: newCategoryIcon)
            context.insert(newCategory)
            categoryName = newCategoryName
        }

        let expense = Expense(amount: amount, category: categoryName, expenseDescription: description.isEmpty ? nil : description, date: date)
        context.insert(expense)
        dismiss()
    }
}
