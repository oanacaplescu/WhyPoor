import SwiftUI
import SwiftData

struct AddCategoryView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var categories: [ExpenseCategory]
    @Query private var allExpenses: [Expense]

    private static let maxNameLength = 30

    /// Pass an existing category to edit it; leave nil to create a new one.
    var categoryToEdit: ExpenseCategory?

    @State private var name = ""
    @State private var selectedIcon: String = ExpenseCategory.icons.first ?? "tag.fill"
    @State private var showingDeleteWarning = false

    private let gridColumns = Array(repeating: GridItem(.flexible()), count: 6)

    private var isEditing: Bool { categoryToEdit != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Category name", text: $name)
                        .onChange(of: name) { _, newValue in
                            if newValue.count > Self.maxNameLength {
                                name = String(newValue.prefix(Self.maxNameLength))
                            }
                        }
                    HStack {
                        Spacer()
                        Text("\(name.count)/\(Self.maxNameLength)")
                            .font(.caption)
                            .foregroundStyle(name.count >= Self.maxNameLength ? .red : .secondary)
                    }
                }

                Section("Icon") {
                    LazyVGrid(columns: gridColumns, spacing: 10) {
                        ForEach(ExpenseCategory.icons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title3)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle().fill(selectedIcon == icon ? Color.accentColor.opacity(0.2) : Color.clear)
                                )
                                .foregroundStyle(selectedIcon == icon ? Color.accentColor : .primary)
                                .onTapGesture {
                                    selectedIcon = icon
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }

                if isEditing {
                    Section {
                        Button("Delete Category", role: .destructive) {
                            let count = allExpenses.filter { $0.category == categoryToEdit?.name }.count
                            if count > 0 {
                                showingDeleteWarning = true
                            } else {
                                deleteAndDismiss()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Category" : "New Category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { loadExistingValues() }
            .alert("Delete Category?", isPresented: $showingDeleteWarning) {
                Button("Delete", role: .destructive) {
                    deleteAndDismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                let count = allExpenses.filter { $0.category == categoryToEdit?.name }.count
                Text("\(count) expense\(count == 1 ? "" : "s") use this category. They'll keep their data, but lose their icon and color.")
            }
        }
    }

    private func loadExistingValues() {
        guard let category = categoryToEdit else { return }
        name = category.name
        selectedIcon = category.iconName
    }

    private func save() {
        if let category = categoryToEdit {
            category.name = name
            category.iconName = selectedIcon
        } else {
            let colorHex = ExpenseCategory.palette[categories.count % ExpenseCategory.palette.count]
            let newCategory = ExpenseCategory(
                name: name,
                colorHex: colorHex,
                iconName: selectedIcon,
                sortOrder: categories.count
            )
            context.insert(newCategory)
        }
        dismiss()
    }

    private func deleteAndDismiss() {
        if let category = categoryToEdit {
            context.delete(category)
        }
        dismiss()
    }
}
