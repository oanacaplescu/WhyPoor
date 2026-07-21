import SwiftUI
import SwiftData
import UIKit

struct ExpenseListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
    @Query private var allCategories: [ExpenseCategory]
    @AppStorage("salaryDay") private var salaryDay: Int = 1
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD"

    @State private var showingAddExpense = false
    @State private var showingSettings = false
    @State private var showingPeriodPicker = false
    @State private var selectedPeriod: BillingPeriod?
    @State private var expenseToEdit: Expense?
    @State private var showingCategoryManagement = false

    private var currentPeriod: BillingPeriod {
        selectedPeriod ?? BillingPeriod.containing(date: .now, salaryDay: salaryDay)
    }

    private var availablePeriods: [BillingPeriod] {
        BillingPeriod.recentPeriods(count: 12, salaryDay: salaryDay)
    }

    private var periodExpenses: [Expense] {
        allExpenses.filter { $0.date >= currentPeriod.start && $0.date <= currentPeriod.end }
    }
    
    private var groupedExpenses: [(day: Date, expenses: [Expense])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: periodExpenses) { calendar.startOfDay(for: $0.date) }
        return grouped
            .sorted { $0.key > $1.key }
            .map { (day: $0.key, expenses: $0.value.sorted { $0.date > $1.date }) }
    }
    
    private var total: Decimal {
        periodExpenses.reduce(0) { $0 + $1.amount }
    }

    private func style(for categoryName: String) -> (color: Color, icon: String) {
        if let match = allCategories.first(where: { $0.name == categoryName }) {
            return (Color(hex: match.colorHex), match.iconName)
        }
        return (.gray, "tag.fill")
    }

    private func isCurrent(_ period: BillingPeriod) -> Bool {
        let current = BillingPeriod.containing(date: .now, salaryDay: salaryDay)
        return period.start == current.start
    }

    private func setPeriod(_ period: BillingPeriod?) {
        UIView.performWithoutAnimation {
            selectedPeriod = period
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    Section {
                        VStack(alignment: .center, spacing: 4) {
                            Text("Expenses")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(total, format: .currency(code: currencyCode))
                                .font(.system(size: 34, weight: .bold))
                                .foregroundStyle(AppTheme.slate)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(AppTheme.sand.opacity(0.25))
                    
                    Section {
                        ForEach(groupedExpenses, id: \.day) { group in
                            Section {
                                ForEach(group.expenses) { expense in
                                    let style = style(for: expense.category)
                                    HStack(spacing: 12) {
                                        Image(systemName: style.icon)
                                            .foregroundStyle(.white)
                                            .frame(width: 32, height: 32)
                                            .background(Circle().fill(style.color))
                                        
                                        VStack(alignment: .leading) {
                                            Text(expense.category)
                                            if let desc = expense.expenseDescription, !desc.isEmpty {
                                                Text(desc)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        
                                        Spacer()
                                        Text(expense.amount, format: .currency(code: currencyCode))
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        expenseToEdit = expense
                                    }
                                }
                                .onDelete { offsets in
                                    deleteExpenses(offsets, in: group.expenses)
                                }
                            } header: {
                                Text(dayLabel(for: group.day))
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(AppTheme.slate)
                                        .padding(.top, 8)                            }
                        }
                    }
                }
                
                VStack {
                    Spacer()
                    Button {
                        showingAddExpense = true
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
                
                if showingPeriodPicker {
                    Color.clear
                        .contentShape(Rectangle())
                        .ignoresSafeArea()
                        .onTapGesture { showingPeriodPicker = false }
                        .zIndex(1)
                    
                    VStack(spacing: 0) {
                        PeriodPickerView(
                            periods: availablePeriods,
                            currentPeriod: currentPeriod,
                            isCurrent: isCurrent,
                            title: title,
                            onSelect: { period in
                                setPeriod(period)
                                showingPeriodPicker = false
                            },
                            onSelectCurrentMonth: {
                                setPeriod(nil)
                                showingPeriodPicker = false
                            }
                        )
                        .frame(width: 240, height: 320)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
                        
                        Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                        .zIndex(2)
                    }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingCategoryManagement = true } label: {
                        Image(systemName: "tag")
                    }
                }
                ToolbarItem(placement: .principal) {
                    Button {
                        showingPeriodPicker = true
                    } label: {
                        Text(periodTitle)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(AppTheme.slate)
                            .lineLimit(1)
                            .frame(width: 170, alignment: .center)
                    }
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView()
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack { SettingsView() }
            }
            .sheet(item: $expenseToEdit) { expense in
                AddExpenseView(expenseToEdit: expense)
            }
            .sheet(isPresented: $showingCategoryManagement) {
                CategoryManagementView()
            }
        }
    }

    private func title(for period: BillingPeriod) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: period.start)
    }

    private var periodTitle: String {
        title(for: currentPeriod)
    }

    private func deleteExpenses(_ offsets: IndexSet, in expenses: [Expense]) {
        for index in offsets {
            context.delete(expenses[index])
        }
    }

    private func dayLabel(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
}
