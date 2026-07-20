import SwiftData
import Foundation

@Model
final class ExpenseCategory {
    var name: String
    var colorHex: String
    var iconName: String

    init(name: String, colorHex: String, iconName: String) {
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
    }
}

extension ExpenseCategory {
    // Paired by index: palette[i] goes with icons[i]
    static let palette: [String] = [
        "#4A90D9", // blue
        "#E8622C", // orange
        "#4CAF50", // green
        "#9C27B0", // purple
        "#F4B400", // yellow
        "#E91E63", // pink
        "#00BCD4", // cyan
        "#795548"  // brown
    ]

    static let icons: [String] = [
            // Food & drink
            "cart.fill", "fork.knife", "cup.and.saucer.fill", "wineglass.fill",
            "birthday.cake.fill", "takeoutbag.and.cup.and.straw.fill",

            // Housing & utilities
            "house.fill", "bolt.fill", "drop.fill", "flame.fill",
            "wifi", "sofa.fill", "lightbulb.fill", "wrench.and.screwdriver.fill",

            // Transport
            "car.fill", "fuelpump.fill", "bus.fill", "tram.fill",
            "bicycle", "airplane", "parkingsign", "figure.walk",

            // Bills & finance
            "creditcard.fill", "banknote.fill", "phone.fill", "doc.text.fill",
            "chart.pie.fill", "building.columns.fill", "percent",

            // Health & personal care
            "heart.fill", "cross.case.fill", "pills.fill", "figure.run",
            "scissors", "sparkles",

            // Shopping & lifestyle
            "bag.fill", "tshirt.fill", "gift.fill", "tag.fill",
            "book.fill", "gamecontroller.fill", "film.fill", "music.note",
            "camera.fill",

            // Family & pets
            "pawprint.fill", "figure.2.and.child.holdinghands", "teddybear.fill",

            // Travel & misc
            "bed.double.fill", "map.fill", "ticket.fill", "umbrella.fill",
            "questionmark.circle.fill"
        ]
    /// Deterministically assigns a color/icon pair based on how many categories already exist.
    static func nextStyle(existingCount: Int) -> (colorHex: String, iconName: String) {
        let index = existingCount % palette.count
        return (palette[index], icons[index])
    }
}
