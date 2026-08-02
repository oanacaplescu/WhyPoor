import Foundation

enum CSVImporter {
    /// Looks at the first line and picks whichever delimiter appears most —
    /// handles comma, tab, and semicolon-separated exports.
    static func detectDelimiter(in text: String) -> Character {
        guard let firstLine = text.split(separator: "\n", maxSplits: 1).first else { return "," }
        let candidates: [Character] = [",", "\t", ";"]
        let counts = candidates.map { delim in
            (delim, firstLine.filter { $0 == delim }.count)
        }
        return counts.max(by: { $0.1 < $1.1 })?.0 ?? ","
    }

    /// Parses raw delimited text into rows of string fields, handling quoted fields
    /// (including embedded delimiters and escaped quotes).
    static func parse(_ text: String, delimiter: Character? = nil) -> [[String]] {
        let delim = delimiter ?? detectDelimiter(in: text)
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var insideQuotes = false

        var chars = Array(text)
        var i = 0
        while i < chars.count {
            let char = chars[i]

            if insideQuotes {
                if char == "\"" {
                    if i + 1 < chars.count, chars[i + 1] == "\"" {
                        currentField.append("\"")
                        i += 1
                    } else {
                        insideQuotes = false
                    }
                } else {
                    currentField.append(char)
                }
            } else if char == "\"" {
                insideQuotes = true
            } else if char == delim {
                currentRow.append(currentField)
                currentField = ""
            } else if char == "\n" {
                currentRow.append(currentField)
                rows.append(currentRow)
                currentRow = []
                currentField = ""
            } else if char == "\r" {
                // skip
            } else {
                currentField.append(char)
            }
            i += 1
        }

        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField)
            rows.append(currentRow)
        }

        return rows.filter { row in
            !(row.allSatisfy { $0.trimmingCharacters(in: .whitespaces).isEmpty })
        }
    }

    static let dateFormats = [
        "yyyy-MM-dd",
        "MM/dd/yyyy",
        "dd/MM/yyyy",
        "dd.MM.yyyy",
        "MM-dd-yyyy",
        "dd-MM-yyyy",
        "yyyy-M-d"
    ]

    static func parseDate(_ string: String, format: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.isLenient = false
        return formatter.date(from: string.trimmingCharacters(in: .whitespaces))
    }

    static func parseAmount(_ string: String) -> Decimal? {
        let cleaned = string
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: "[^0-9.\\-]", with: "", options: .regularExpression)
        guard let amount = Decimal(string: cleaned) else { return nil }
        return abs(amount)
    }
}

struct ImportedExpenseRow: Identifiable {
    let id = UUID()
    let date: Date?
    let category: String
    let amount: Decimal?
    let description: String?
    let rawRow: [String]

    var isValid: Bool { date != nil && amount != nil }
}
