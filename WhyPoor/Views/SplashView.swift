import SwiftUI

struct SplashView: View {
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            AppTheme.teal.ignoresSafeArea()
            Image("LaunchLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .scaleEffect(isPulsing ? 1.06 : 0.96)
                .opacity(isPulsing ? 1.0 : 0.85)
                .animation(
                    .easeInOut(duration: 1.1).repeatForever(autoreverses: true),
                    value: isPulsing
                )
                .onAppear {
                    isPulsing = true
                }
        }
    }
}
