//
//  Item.swift
//  Studere
//
//  Created by Zhi Zheng Yeo on 26/3/26.
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
