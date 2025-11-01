import Foundation
import SwiftData

@Model
final class Expense {
    var id: String = UUID().uuidString  // ✅ default value fixes CloudKit issue
    var emoji: String = "💰"
    var name: String = ""
    var price: Double = 0
    var date: Date = Date()
    var note: String = ""

    init(emoji: String = "💰", name: String = "", price: Double = 0, date: Date = Date(), note: String = "") {
        self.emoji = emoji
        self.name = name
        self.price = price
        self.date = date
        self.note = note
    }
}

@Model
final class Income {
    var id: String = UUID().uuidString  // ✅ default value fixes CloudKit issue
    var income: Double = 0
    var date: Date = Date()
    var note: String = ""

    init(income: Double = 0, date: Date = Date(), note: String = "") {
        self.income = income
        self.date = date
        self.note = note
    }
}

@Model
final class UserCategory {
    var id: String = UUID().uuidString
    var name: String = ""
    var emoji: String = "🔖"

    init(name: String, emoji: String = "🔖") {
        self.name = name
        self.emoji = emoji
    }
}
