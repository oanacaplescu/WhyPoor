import SwiftUI
import SwiftData

struct AddExpenseView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD"

    /// Pass an existing expense to edit it; leave nil to create a new one.
    var expenseToEdit: Expense?

    @State private var amountText = ""
    @State private var selectedCategory: ExpenseCategory?
    @State private var newCategoryName = ""
    @State private var newCategoryIcon: String = ExpenseCategory.icons.first ?? "tag.fill"
    @State private var description = ""
    @State private var date = Date.now
    @State private var showingNewCategoryField = false

    private let gridColumns = Array(repeating: GridItem(.flexible()), count: 6)

    private var isEditing: Bool { expenseToEdit != nil }

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

                if isEditing {
                    Section {
                        Button("Delete Expense", role: .destructive) {
                            deleteAndDismiss()
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Expense" : "Add Expense")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(Decimal(string: amountText) == nil || (showingNewCategoryField && newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty))
                }
            }
            .onAppear { loadExistingValues() }
        }
    }

    private func loadExistingValues() {
        guard let expense = expenseToEdit else { return }
        amountText = NSDecimalNumber(decimal: expense.amount).stringValue
        description = expense.expenseDescription ?? ""
        date = expense.date
        selectedCategory = categories.first(where: { $0.name == expense.category })
    }

    private func save() {
        guard let amount = Decimal(string: amountText) else { return }

        var categoryName = selectedCategory?.name ?? ""
        if showingNewCategoryField, !newCategoryName.isEmpty {
            let colorHex = ExpenseCategory.palette[categories.count % ExpenseCategory.palette.count]
            let newCategory = ExpenseCategory(name: newCategoryName, colorHex: colorHex, iconName: newCategoryIcon, sortOrder: categories.count)
            context.insert(newCategory)
            categoryName = newCategoryName
        }

        if let expense = expenseToEdit {
            expense.amount = amount
            expense.category = categoryName
            expense.expenseDescription = description.isEmpty ? nil : description
            expense.date = date
        } else {
            let expense = Expense(amount: amount, category: categoryName, expenseDescription: description.isEmpty ? nil : description, date: date)
            context.insert(expense)
        }

        dismiss()
    }

    private func deleteAndDismiss() {
        if let expense = expenseToEdit {
            context.delete(expense)
        }
        dismiss()
    }
}
