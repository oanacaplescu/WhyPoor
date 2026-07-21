import SwiftData
import Foundation

@Model
final class ExpenseCategory {
    var name: String
    var colorHex: String
    var iconName: String
    var sortOrder: Int

    init(name: String, colorHex: String, iconName: String, sortOrder: Int = 0) {
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
        self.sortOrder = sortOrder
    }
}

extension ExpenseCategory {
    static let palette: [String] = [
        "#4A90D9", "#E8622C", "#4CAF50", "#9C27B0",
        "#F4B400", "#E91E63", "#00BCD4", "#795548"
    ]

    static let icons: [String] = [
        "cart.fill", "fork.knife", "cup.and.saucer.fill", "wineglass.fill",
        "birthday.cake.fill", "takeoutbag.and.cup.and.straw.fill",
        "house.fill", "bolt.fill", "drop.fill", "flame.fill",
        "wifi", "sofa.fill", "lightbulb.fill", "wrench.and.screwdriver.fill",
        "car.fill", "fuelpump.fill", "bus.fill", "tram.fill",
        "bicycle", "airplane", "parkingsign", "figure.walk",
        "creditcard.fill", "banknote.fill", "phone.fill", "doc.text.fill",
        "chart.pie.fill", "building.columns.fill", "percent",
        "heart.fill", "cross.case.fill", "pills.fill", "figure.run",
        "scissors", "sparkles",
        "bag.fill", "tshirt.fill", "gift.fill", "tag.fill",
        "book.fill", "gamecontroller.fill", "film.fill", "music.note",
        "camera.fill",
        "pawprint.fill", "figure.2.and.child.holdinghands", "teddybear.fill",
        "bed.double.fill", "map.fill", "ticket.fill", "umbrella.fill",
        "questionmark.circle.fill"
    ]
}
