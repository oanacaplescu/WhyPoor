import SwiftUI

struct PeriodPickerView: View {
    let periods: [BillingPeriod]
    let currentPeriod: BillingPeriod
    let isCurrent: (BillingPeriod) -> Bool
    let title: (BillingPeriod) -> String
    let onSelect: (BillingPeriod) -> Void
    let onSelectCurrentMonth: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                pickerRow(label: "Current Month", icon: "calendar", isSelected: false) {
                    onSelectCurrentMonth()
                }

                Divider()

                ForEach(periods, id: \.start) { period in
                    pickerRow(
                        label: isCurrent(period) ? "\(title(period)) (current)" : title(period),
                        icon: nil,
                        isSelected: period.start == currentPeriod.start
                    ) {
                        onSelect(period)
                    }
                }
            }
        }
        .frame(width: 240, height: 320)
        .background(Color(.systemBackground))
    }

    @ViewBuilder
    private func pickerRow(label: String, icon: String?, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                if let icon {
                    Image(systemName: icon)
                        .foregroundStyle(AppTheme.teal)
                        .frame(width: 20)
                }
                Text(label)
                    .foregroundStyle(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(AppTheme.teal)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
