import SwiftUI

struct WelcomeView: View {
    @AppStorage("salaryDay", store: AppGroup.sharedDefaults) private var salaryDay: Int = 1
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image("LaunchLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 90, height: 90)

            VStack(spacing: 8) {
                Text("Welcome to WhyPoor")
                    .font(.title2.bold())

                Text("Instead of tracking calendar months, your budget periods run from payday to payday — matching how you actually get paid.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 10) {
                Text("When's your salary day?")
                    .font(.headline)

                Stepper("Day \(salaryDay) of each month", value: $salaryDay, in: 1...31)
                    .padding(.horizontal, 40)

                Text("Your first period will run from day \(salaryDay) to day \(salaryDay == 1 ? 31 : salaryDay - 1) of the next month. You can change this anytime in Settings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.vertical, 20)
            .background(AppTheme.sand.opacity(0.25))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 24)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Get Started")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.teal)
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .interactiveDismissDisabled()
    }
}
