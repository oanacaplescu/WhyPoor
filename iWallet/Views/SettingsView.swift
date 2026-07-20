import SwiftUI

struct SettingsView: View {
    @AppStorage("salaryDay") private var salaryDay: Int = 1
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD"

    private let commonCurrencies = ["RON", "EUR", "GBP", "PLN", "CZK"]

    var body: some View {
        Form {
            Section("Salary day") {
                Stepper("Day \(salaryDay) of each month", value: $salaryDay, in: 1...31)
                Text("Your monthly period will run from day \(salaryDay) to day \(salaryDay - 1) of the next month.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("Currency") {
                            Picker("Currency", selection: $currencyCode) {
                                ForEach(commonCurrencies, id: \.self) { code in
                                    Text(code).tag(code)
                                }
                            }
                        }
        }
        .navigationTitle("Settings")
    }
}
