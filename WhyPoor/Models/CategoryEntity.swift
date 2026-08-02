import AppIntents
import SwiftData
import Foundation

struct CategoryEntity: AppEntity {
    let id: String
    let name: String
    let iconName: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Category"

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", image: .init(systemName: iconName))
    }

    static var defaultQuery = CategoryEntityQuery()
}

struct CategoryEntityQuery: EntityQuery, EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [CategoryEntity] {
        let all = try await allCategories()
        return all.filter { identifiers.contains($0.id) }
    }

    func entities(matching string: String) async throws -> [CategoryEntity] {
        let all = try await allCategories()
        return all.filter { $0.name.localizedCaseInsensitiveContains(string) }
    }

    func suggestedEntities() async throws -> [CategoryEntity] {
        try await allCategories()
    }

    private func allCategories() async throws -> [CategoryEntity] {
        let context = ModelContext(SharedModelContainer.container)
        let descriptor = FetchDescriptor<ExpenseCategory>(sortBy: [SortDescriptor(\.sortOrder)])
        let categories = try context.fetch(descriptor)
        return categories.map { CategoryEntity(id: $0.name, name: $0.name, iconName: $0.iconName) }
    }
}
