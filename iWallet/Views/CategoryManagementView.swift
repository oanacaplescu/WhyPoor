import SwiftUI
import SwiftData

struct CategoryManagementView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]

    @State private var showingAddCategory = false
    @State private var categoryToEdit: ExpenseCategory?
    @State private var localOrder: [ExpenseCategory] = []
    @State private var draggedID: PersistentIdentifier?
    @State private var dragTranslation: CGFloat = 0

    private let rowHeight: CGFloat = 60

    private var draggedIndex: Int? {
        guard let draggedID else { return nil }
        return localOrder.firstIndex { $0.persistentModelID == draggedID }
    }

    private var rowsMoved: Int {
        Int((dragTranslation / rowHeight).rounded())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(localOrder.enumerated()), id: \.element.persistentModelID) { index, category in
                            CategoryRow(
                                category: category,
                                rowHeight: rowHeight,
                                onTap: { categoryToEdit = category },
                                onDelete: { delete(category) },
                                onDragChanged: { translation in
                                    draggedID = category.persistentModelID
                                    dragTranslation = translation
                                },
                                onDragEnded: {
                                    commitDrag(from: index)
                                }
                            )
                            .offset(y: visualOffset(for: index))
                            .zIndex(draggedID == category.persistentModelID ? 1 : 0)

                            if index < localOrder.count - 1 {
                                Divider().padding(.leading, 60)
                            }
                        }
                    }
                    .padding(.bottom, 90)
                }
                .background(Color(.systemBackground))

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
            .sheet(item: $categoryToEdit) { category in
                AddCategoryView(categoryToEdit: category)
            }
            .onAppear { localOrder = categories }
            .onChange(of: categories) { _, newValue in
                if draggedID == nil {
                    localOrder = newValue
                }
            }
        }
    }

    private func visualOffset(for index: Int) -> CGFloat {
        guard let draggedIndex else { return 0 }

        if index == draggedIndex {
            return dragTranslation
        }

        let target = draggedIndex + rowsMoved
        if rowsMoved > 0, index > draggedIndex, index <= target {
            return -rowHeight
        }
        if rowsMoved < 0, index < draggedIndex, index >= target {
            return rowHeight
        }
        return 0
    }

    private func commitDrag(from index: Int) {
        let target = max(0, min(localOrder.count - 1, index + rowsMoved))

        withAnimation(.easeInOut(duration: 0.2)) {
            if target != index {
                var reordered = localOrder
                let item = reordered.remove(at: index)
                reordered.insert(item, at: target)
                for (i, category) in reordered.enumerated() {
                    category.sortOrder = i
                }
                localOrder = reordered
            }
            draggedID = nil
            dragTranslation = 0
        }
    }

    private func delete(_ category: ExpenseCategory) {
        context.delete(category)
        localOrder.removeAll { $0.persistentModelID == category.persistentModelID }
    }
}

private struct CategoryRow: View {
    let category: ExpenseCategory
    let rowHeight: CGFloat
    let onTap: () -> Void
    let onDelete: () -> Void
    let onDragChanged: (CGFloat) -> Void
    let onDragEnded: () -> Void

    @State private var swipeOffset: CGFloat = 0
    private let deleteButtonWidth: CGFloat = 80

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                // Main content
                HStack(spacing: 12) {
                    Image(systemName: category.iconName)
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color(hex: category.colorHex)))
                    Text(category.name)
                    Spacer()
                    Image(systemName: "line.3.horizontal")
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(coordinateSpace: .global)
                                .onChanged { value in
                                    onDragChanged(value.translation.height)
                                }
                                .onEnded { _ in
                                    onDragEnded()
                                }
                        )
                }
                .padding(.horizontal, 16)
                .frame(width: geo.size.width, height: rowHeight)
                .background(Color(.systemBackground))
                .contentShape(Rectangle())
                .onTapGesture {
                    if swipeOffset == 0 {
                        onTap()
                    } else {
                        withAnimation(.easeOut(duration: 0.2)) {
                            swipeOffset = 0
                        }
                    }
                }

                // Delete button — a normal sibling, revealed by sliding the whole row left
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.white)
                        .frame(width: deleteButtonWidth, height: rowHeight)
                        .background(Color.red)
                }
            }
            .offset(x: swipeOffset)
            .simultaneousGesture(
                DragGesture(minimumDistance: 15)
                    .onChanged { value in
                        let isHorizontalDrag = abs(value.translation.width) > abs(value.translation.height)
                        guard isHorizontalDrag, value.translation.width < 0 else { return }
                        swipeOffset = max(value.translation.width, -deleteButtonWidth)
                    }
                    .onEnded { value in
                        let isHorizontalDrag = abs(value.translation.width) > abs(value.translation.height)
                        guard isHorizontalDrag else { return }
                        withAnimation(.easeOut(duration: 0.2)) {
                            swipeOffset = value.translation.width < -deleteButtonWidth / 2 ? -deleteButtonWidth : 0
                        }
                    }
            )
        }
        .frame(height: rowHeight)
        .clipped()
    }
}
