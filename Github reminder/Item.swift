//
//  Item.swift
//  Github reminder
//
//  Created by Maksim Ponomarev on 1/13/25.
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
