import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ImportCSVView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var existingCategories: [ExpenseCategory]

    private enum Step {
        case pickFile, mapColumns, review, done
    }

    @State private var step: Step = .pickFile
    @State private var showingFilePicker = false
    @State private var errorMessage: String?

    @State private var headers: [String] = []
    @State private var dataRows: [[String]] = []

    @State private var dateColumnIndex: Int = -1
    @State private var amountColumnIndex: Int = -1
    @State private var categoryColumnIndex: Int = -1
    @State private var descriptionColumnIndex: Int = -1
    @State private var typeColumnIndex: Int = -1
    @State private var expenseValueMatch: String = "Expenses"
    @State private var selectedDateFormat = CSVImporter.dateFormats[0]

    @State private var parsedRows: [ImportedExpenseRow] = []
    @State private var importedCount = 0

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .pickFile: pickFileStep
                case .mapColumns: mapColumnsStep
                case .review: reviewStep
                case .done: doneStep
                }
            }
            .navigationTitle("Import CSV")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.commaSeparatedText, .plainText],
                onCompletion: handleFileSelection
            )
        }
    }

    // MARK: - Step 1: Pick file

    private var pickFileStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 50))
                .foregroundStyle(AppTheme.teal)
            Text("Import expenses from a CSV file exported by another app.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 32)
            }

            Button {
                showingFilePicker = true
            } label: {
                Text("Choose CSV File")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.teal)
            .padding(.horizontal, 32)
        }
        .frame(maxHeight: .infinity)
    }

    private func handleFileSelection(_ result: Result<URL, Error>) {
        errorMessage = nil
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Couldn't access the selected file."
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let text = try String(contentsOf: url, encoding: .utf8)
                let rows = CSVImporter.parse(text)
                guard rows.count > 1 else {
                    errorMessage = "This file doesn't contain any data rows."
                    return
                }
                headers = rows[0]
                dataRows = Array(rows.dropFirst())
                autoDetectColumns()
                step = .mapColumns
            } catch {
                errorMessage = "Couldn't read that file as text/CSV."
            }
        case .failure:
            errorMessage = "File selection was cancelled or failed."
        }
    }

    private func autoDetectColumns() {
        for (index, header) in headers.enumerated() {
            let lower = header.lowercased()
            if lower.contains("date") { dateColumnIndex = index }
            else if lower.contains("amount") || lower.contains("sum") || lower.contains("total") { amountColumnIndex = index }
            else if lower.contains("categor") { categoryColumnIndex = index }
            else if lower.contains("desc") || lower.contains("note") || lower.contains("memo") { descriptionColumnIndex = index }
            else if lower.contains("income") || lower.contains("type") { typeColumnIndex = index }
        }
    }

    // MARK: - Step 2: Map columns

    private var mapColumnsStep: some View {
        Form {
            Section("Preview") {
                Text(headers.joined(separator: " | "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if let firstRow = dataRows.first {
                    Text(firstRow.joined(separator: " | "))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Section("Map Columns") {
                columnPicker("Date (required)", selection: $dateColumnIndex)
                columnPicker("Amount (required)", selection: $amountColumnIndex)
                columnPicker("Category (optional)", selection: $categoryColumnIndex)
                columnPicker("Description (optional)", selection: $descriptionColumnIndex)
                columnPicker("Type column (optional)", selection: $typeColumnIndex)
            }

            if typeColumnIndex != -1 {
                Section("Only Import Rows Where Type Is") {
                    TextField("e.g. Expenses", text: $expenseValueMatch)
                    Text("Rows where this column doesn't match this text will be skipped (income, transfers, etc.)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Date Format") {
                Picker("Format", selection: $selectedDateFormat) {
                    ForEach(CSVImporter.dateFormats, id: \.self) { format in
                        Text(format).tag(format)
                    }
                }
                .pickerStyle(.navigationLink)
            }

            Section {
                Button("Continue") {
                    buildParsedRows()
                    step = .review
                }
                .disabled(dateColumnIndex == -1 || amountColumnIndex == -1)
            }
        }
    }

    private func columnPicker(_ label: String, selection: Binding<Int>) -> some View {
        Picker(label, selection: selection) {
            Text("None").tag(-1)
            ForEach(Array(headers.enumerated()), id: \.offset) { index, header in
                Text(header).tag(index)
            }
        }
        .pickerStyle(.navigationLink)
    }

    private func buildParsedRows() {
        func value(at index: Int, in row: [String]) -> String? {
            guard index >= 0, row.indices.contains(index) else { return nil }
            return row[index]
        }

        let filteredRows: [[String]]
        if typeColumnIndex != -1 {
            let target = expenseValueMatch.trimmingCharacters(in: .whitespaces).lowercased()
            filteredRows = dataRows.filter { row in
                guard let typeValue = value(at: typeColumnIndex, in: row) else { return false }
                return typeValue.trimmingCharacters(in: .whitespaces).lowercased() == target
            }
        } else {
            filteredRows = dataRows
        }

        parsedRows = filteredRows.map { row in
            let dateString = value(at: dateColumnIndex, in: row) ?? ""
            let amountString = value(at: amountColumnIndex, in: row) ?? ""
            let categoryString = value(at: categoryColumnIndex, in: row) ?? "Imported"
            let descString = value(at: descriptionColumnIndex, in: row)

            return ImportedExpenseRow(
                date: CSVImporter.parseDate(dateString, format: selectedDateFormat),
                category: categoryString.trimmingCharacters(in: .whitespaces).isEmpty ? "Imported" : categoryString,
                amount: CSVImporter.parseAmount(amountString),
                description: descString?.trimmingCharacters(in: .whitespaces),
                rawRow: row
            )
        }
    }

    // MARK: - Step 3: Review

    private var validRows: [ImportedExpenseRow] { parsedRows.filter { $0.isValid } }
    private var invalidRows: [ImportedExpenseRow] { parsedRows.filter { !$0.isValid } }

    private var reviewStep: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    Label("\(validRows.count) rows ready to import", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    if !invalidRows.isEmpty {
                        Label("\(invalidRows.count) rows will be skipped (invalid date/amount)", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }

                Section("Preview (first 10)") {
                    ForEach(validRows.prefix(10)) { row in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(row.category)
                                if let date = row.date {
                                    Text(date, format: .dateTime.day().month().year())
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if let amount = row.amount {
                                Text(amount, format: .number)
                            }
                        }
                    }
                }
            }

            Button {
                performImport()
            } label: {
                Text("Import \(validRows.count) Expenses")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.teal)
            .disabled(validRows.isEmpty)
            .padding()
        }
    }

    private func performImport() {
        var categoryLookup: [String: ExpenseCategory] = [:]
        for cat in existingCategories {
            categoryLookup[cat.name.lowercased()] = cat
        }

        var nextSortOrder = existingCategories.count

        for row in validRows {
            guard let date = row.date, let amount = row.amount else { continue }

            let categoryKey = row.category.lowercased()
            let category: ExpenseCategory
            if let existing = categoryLookup[categoryKey] {
                category = existing
            } else {
                let colorHex = ExpenseCategory.palette[nextSortOrder % ExpenseCategory.palette.count]
                let newCategory = ExpenseCategory(name: row.category, colorHex: colorHex, iconName: "tag.fill", sortOrder: nextSortOrder)
                context.insert(newCategory)
                categoryLookup[categoryKey] = newCategory
                category = newCategory
                nextSortOrder += 1
            }

            let expense = Expense(amount: amount, category: category.name, expenseDescription: row.description?.isEmpty == true ? nil : row.description, date: date)
            context.insert(expense)
        }

        importedCount = validRows.count
        step = .done
    }

    // MARK: - Step 4: Done

    private var doneStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.green)
            Text("Imported \(importedCount) expenses")
                .font(.title3.bold())
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.teal)
        }
        .frame(maxHeight: .infinity)
    }
}
