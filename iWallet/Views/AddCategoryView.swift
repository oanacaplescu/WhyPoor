import SwiftUI
import SwiftData

struct AddCategoryView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var categories: [ExpenseCategory]

    private static let maxNameLength = 30

    @State private var name = ""
    @State private var selectedIcon: String = ExpenseCategory.icons.first ?? "tag.fill"

    private let gridColumns = Array(repeating: GridItem(.flexible()), count: 6)

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
            }
            .navigationTitle("New Category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let colorHex = ExpenseCategory.palette[categories.count % ExpenseCategory.palette.count]
        let newCategory = ExpenseCategory(
            name: name,
            colorHex: colorHex,
            iconName: selectedIcon,
            sortOrder: categories.count
        )
        context.insert(newCategory)
        dismiss()
    }
}
