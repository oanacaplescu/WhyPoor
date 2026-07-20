//
//  Item.swift
//  iWallet
//
//  Created by Oana Cozma on 20/07/2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
