import SwiftUI
import Charts

struct CategoryDetailView: View {
    let categoryName: String
    let icon: String
    let color: Color
    let expenses: [Expense]
    let currencyCode: String
    let periodStart: Date
    let periodEnd: Date

    private var total: Decimal {
        expenses.reduce(0) { $0 + $1.amount }
    }

    private var dayCount: Int {
        max(Calendar.current.dateComponents([.day], from: periodStart, to: periodEnd).day ?? 0, 0) + 1
    }

    private var averageDaily: Decimal {
        guard dayCount > 0 else { return 0 }
        return total / Decimal(dayCount)
    }

    private struct DailyPoint: Identifiable {
        var id: Int { dayIndex }
        let dayIndex: Int
        let amount: Decimal
    }

    private var dailyPoints: [DailyPoint] {
        let calendar = Calendar.current
        var totalsByDay: [Int: Decimal] = [:]
        for expense in expenses {
            let dayIndex = calendar.dateComponents([.day], from: periodStart, to: expense.date).day ?? 0
            totalsByDay[dayIndex, default: 0] += expense.amount
        }
        return (0..<dayCount).map { DailyPoint(dayIndex: $0, amount: totalsByDay[$0] ?? 0) }
    }

    private var sortedExpenses: [Expense] {
        expenses.sorted { $0.date > $1.date }
    }

    private func percentage(of expense: Expense) -> Double {
        guard total > 0 else { return 0 }
        return (NSDecimalNumber(decimal: expense.amount).doubleValue / NSDecimalNumber(decimal: total).doubleValue) * 100
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                chartCard
                listCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(categoryName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(categoryName)
                .font(.title3.bold())

            Text("Total: \(total, format: .currency(code: currencyCode))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Average daily: \(averageDaily, format: .currency(code: currencyCode))")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if dailyPoints.contains(where: { $0.amount > 0 }) {
                Chart(dailyPoints) { point in
                    LineMark(
                        x: .value("Day", point.dayIndex + 1),
                        y: .value("Amount", NSDecimalNumber(decimal: point.amount).doubleValue)
                    )
                    .foregroundStyle(color)
                    .interpolationMethod(.catmullRom)
                    .symbol {
                        Circle()
                            .fill(point.amount > 0 ? color.opacity(0.25) : Color(.systemGray5))
                            .frame(width: 8, height: 8)
                            .overlay(Circle().stroke(point.amount > 0 ? color : Color(.systemGray3), lineWidth: 1.5))
                    }
                }
                .frame(height: 160)
                .chartYAxis(.hidden)
                .chartXAxis {
                    AxisMarks(values: axisValues) { _ in
                        AxisValueLabel()
                        AxisGridLine()
                    }
                }
                .padding(.top, 10)
            } else {
                Text("No expenses to chart")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var axisValues: [Int] {
        Array(stride(from: 1, through: dayCount, by: 5))
    }

    private var listCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Expenses list")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 8)

            ForEach(Array(sortedExpenses.enumerated()), id: \.element.id) { index, expense in
                HStack(spacing: 10) {
                    Text(String(format: "%.1f%%", percentage(of: expense)))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(width: 46, alignment: .leading)

                    Image(systemName: icon)
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(color))

                    VStack(alignment: .leading, spacing: 2) {
                        Text((expense.expenseDescription?.isEmpty == false) ? expense.expenseDescription! : categoryName)
                            .lineLimit(1)
                        Text(expense.date, format: .dateTime.day().month(.abbreviated).year())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 8)

                    Text(expense.amount, format: .currency(code: currencyCode))
                        .foregroundStyle(AppTheme.slate)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                if index < sortedExpenses.count - 1 {
                    Divider().padding(.leading, 16)
                }
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
