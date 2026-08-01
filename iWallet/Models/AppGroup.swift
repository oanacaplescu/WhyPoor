import Foundation

enum AppGroup {
    static let identifier = "group.com.amzisda.iWallet"

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
}
