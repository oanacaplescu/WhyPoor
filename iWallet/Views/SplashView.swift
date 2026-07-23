import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            AppTheme.teal.ignoresSafeArea()
            Image("LaunchLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
        }
    }
}
