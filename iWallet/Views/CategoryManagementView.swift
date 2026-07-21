import SwiftUI
import SwiftData

struct CategoryManagementView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]

    @State private var showingAddCategory = false

    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    ForEach(categories) { category in
                        HStack(spacing: 12) {
                            Image(systemName: category.iconName)
                                .foregroundStyle(.white)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(Color(hex: category.colorHex)))
                            Text(category.name)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                delete(category)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .onMove(perform: moveCategories)
                }
                .environment(\.editMode, .constant(.active))

                VStack {
                    Spacer()
                    Button {
                        showingAddCategory = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(AppTheme.slate)
                            .frame(width: 60, height: 60)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().stroke(AppTheme.teal.opacity(0.4), lineWidth: 1))
                            .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAddCategory) {
                AddCategoryView()
            }
        }
    }

    private func delete(_ category: ExpenseCategory) {
        context.delete(category)
    }

    private func moveCategories(from source: IndexSet, to destination: Int) {
        var reordered = categories
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, category) in reordered.enumerated() {
            category.sortOrder = index
        }
    }
}
