import SwiftUI
import SwiftData
import Charts

struct CategoryBreakdown: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let amount: Decimal
    let percentage: Double
}

struct CategoryBreakdownView: View {
    let periodTitle: String
    let allExpenses: [Expense]
    let categories: [ExpenseCategory]
    let currencyCode: String
    let periodStart: Date
    let periodEnd: Date

    @State private var rangeStart: Date
    @State private var rangeEnd: Date
    @State private var selectedOption: RangeOption = .period

    init(periodTitle: String, allExpenses: [Expense], categories: [ExpenseCategory], currencyCode: String, periodStart: Date, periodEnd: Date) {
        self.periodTitle = periodTitle
        self.allExpenses = allExpenses
        self.categories = categories
        self.currencyCode = currencyCode
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        _rangeStart = State(initialValue: periodStart)
        _rangeEnd = State(initialValue: periodEnd)
    }

    private var expenses: [Expense] {
        allExpenses.filter { $0.date >= rangeStart && $0.date <= rangeEnd }
    }

    private var total: Decimal {
        expenses.reduce(0) { $0 + $1.amount }
    }

    private var breakdown: [CategoryBreakdown] {
        let grouped = Dictionary(grouping: expenses) { $0.category }
        let totalDouble = NSDecimalNumber(decimal: total).doubleValue

        return grouped.map { name, items in
            let amount = items.reduce(Decimal(0)) { $0 + $1.amount }
            let match = categories.first(where: { $0.name == name })
            let pct = totalDouble > 0 ? (NSDecimalNumber(decimal: amount).doubleValue / totalDouble) * 100 : 0
            return CategoryBreakdown(
                name: name,
                icon: match?.iconName ?? "tag.fill",
                color: match.map { Color(hex: $0.colorHex) } ?? .gray,
                amount: amount,
                percentage: pct
            )
        }
        .sorted { $0.amount > $1.amount }
    }

    private var chartSlices: [CategoryBreakdown] {
        guard breakdown.count > 5 else { return breakdown }
        let top = Array(breakdown.prefix(4))
        let rest = breakdown.dropFirst(4)
        let otherAmount = rest.reduce(Decimal(0)) { $0 + $1.amount }
        let otherPct = rest.reduce(0.0) { $0 + $1.percentage }
        let other = CategoryBreakdown(name: "Other", icon: "ellipsis.circle.fill", color: .gray, amount: otherAmount, percentage: otherPct)
        return top + [other]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                dateRangeCard
                donutCard
                listCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(periodTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private enum RangeOption: String, CaseIterable {
        case period = "Period"
        case threeMonths = "3M"
        case sixMonths = "6M"
        case year = "1Y"
        case custom = "Custom"
    }

    private var dateRangeCard: some View {
        VStack(spacing: 12) {
            Picker("Range", selection: $selectedOption) {
                ForEach(RangeOption.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedOption) { _, newValue in
                applyOption(newValue)
            }

            Group {
                if selectedOption == .custom {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("From")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            DatePicker("", selection: $rangeStart, in: ...rangeEnd, displayedComponents: .date)
                                .labelsHidden()
                        }

                        Spacer()

                        VStack(alignment: .leading, spacing: 2) {
                            Text("To")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            DatePicker("", selection: $rangeEnd, in: rangeStart...Date.distantFuture, displayedComponents: .date)
                                .labelsHidden()
                        }
                    }
                } else {
                    HStack {
                        Text(rangeSummary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            }
            .frame(height: 44)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .animation(.easeInOut(duration: 0.2), value: selectedOption)
    }

    private var rangeSummary: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return "\(formatter.string(from: rangeStart)) – \(formatter.string(from: rangeEnd))"
    }

    private func applyOption(_ option: RangeOption) {
        let calendar = Calendar.current
        switch option {
        case .period:
            rangeStart = periodStart
            rangeEnd = periodEnd
        case .threeMonths:
            rangeEnd = .now
            rangeStart = calendar.date(byAdding: .month, value: -3, to: .now) ?? periodStart
        case .sixMonths:
            rangeEnd = .now
            rangeStart = calendar.date(byAdding: .month, value: -6, to: .now) ?? periodStart
        case .year:
            rangeEnd = .now
            rangeStart = calendar.date(byAdding: .year, value: -1, to: .now) ?? periodStart
        case .custom:
            break
        }
    }
    private func presetChip(_ label: String, months: Int) -> some View {
        Button {
            applyPreset(months: months)
        } label: {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(AppTheme.slate)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(AppTheme.sand.opacity(0.35))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func applyPreset(months: Int) {
        let calendar = Calendar.current
        rangeEnd = .now
        rangeStart = calendar.date(byAdding: .month, value: -months, to: .now) ?? periodStart
    }

    private var donutCard: some View {
        VStack {
            if breakdown.isEmpty {
                Text("No expenses in this range")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 60)
            } else {
                HStack(spacing: 20) {
                    ZStack {
                        Chart(chartSlices) { slice in
                            SectorMark(
                                angle: .value("Amount", slice.percentage),
                                innerRadius: .ratio(0.68),
                                angularInset: 1.5
                            )
                            .foregroundStyle(slice.color)
                            .cornerRadius(3)
                        }
                        .frame(width: 150, height: 150)

                        VStack(spacing: 3) {
                            Text("Expenses")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                                .padding(.bottom, 2)
                            Text(total, format: .number.precision(.fractionLength(0)))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(AppTheme.slate)
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                            Text(currencyCode)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 110)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(chartSlices) { slice in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(slice.color)
                                    .frame(width: 10, height: 10)
                                Text(slice.name)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                Spacer(minLength: 4)
                                Text(String(format: "%.2f%%", slice.percentage))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var listCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Expenses list")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 8)

            ForEach(Array(breakdown.enumerated()), id: \.element.id) { index, item in
                NavigationLink {
                    CategoryDetailView(
                        categoryName: item.name,
                        icon: item.icon,
                        color: item.color,
                        expenses: expenses.filter { $0.category == item.name },
                        currencyCode: currencyCode,
                        periodStart: rangeStart,
                        periodEnd: rangeEnd
                    )
                } label: {
                    HStack(spacing: 10) {
                        Text(String(format: "%.1f%%", item.percentage))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(width: 46, alignment: .leading)

                        Image(systemName: item.icon)
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(item.color))

                        Text(item.name)
                            .lineLimit(1)
                            .layoutPriority(1)
                            .foregroundStyle(.primary)

                        Spacer(minLength: 8)

                        Text(item.amount, format: .currency(code: currencyCode))
                            .foregroundStyle(AppTheme.slate)
                            .lineLimit(1)
                            .layoutPriority(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if index < breakdown.count - 1 {
                    Divider().padding(.leading, 16)
                }
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
