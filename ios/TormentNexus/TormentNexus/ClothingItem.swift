import Foundation
import SwiftUI

// MARK: - Clothing Item Model
struct ClothingItem: Identifiable, Codable {
    let id: UUID
    var serverId: Int?
    var imageData: Data?
    var imageURL: String?
    var category: Category
    var brand: String
    var name: String
    var colors: [String]
    var season: Season
    var occasions: [Occasion]
    var dateAdded: Date
    var lastWorn: Date?
    var timesWorn: Int
    
    init(
        id: UUID = UUID(),
        serverId: Int? = nil,
        imageData: Data? = nil,
        imageURL: String? = nil,
        category: Category,
        brand: String = "",
        name: String = "",
        colors: [String] = [],
        season: Season = .allSeasons,
        occasions: [Occasion] = [],
        dateAdded: Date = Date(),
        lastWorn: Date? = nil,
        timesWorn: Int = 0
    ) {
        self.id = id
        self.serverId = serverId
        self.imageData = imageData
        self.imageURL = imageURL
        self.category = category
        self.brand = brand
        self.name = name
        self.colors = colors
        self.season = season
        self.occasions = occasions
        self.dateAdded = dateAdded
        self.lastWorn = lastWorn
        self.timesWorn = timesWorn
    }
}
enum CodingKeys: String, CodingKey {
       case id, serverId, imageData, imageURL
       case category, brand, name, colors
       case season, occasions, dateAdded, lastWorn, timesWorn
   }

// MARK: - Category Enum
enum Category: String, Codable, CaseIterable {
    case tops = "Tops"
    case bottoms = "Bottoms"
    case dresses = "Dresses"
    case shoes = "Shoes"
    case accessories = "Accessories"
    case outerwear = "Outerwear"
    
    var icon: String {
        switch self {
        case .tops: return "tshirt.fill"
        case .bottoms: return "figure.stand"
        case .dresses: return "figure.dress.line.vertical.figure"
        case .shoes: return "shoe.fill"
        case .accessories: return "bag.fill"
        case .outerwear: return "jacket.fill"
        }
    }
}

// MARK: - Season Enum
enum Season: String, Codable, CaseIterable {
    case spring = "Spring"
    case summer = "Summer"
    case fall = "Fall"
    case winter = "Winter"
    case allSeasons = "All Seasons"
}

// MARK: - Occasion Enum
enum Occasion: String, Codable, CaseIterable {
    case casual = "Casual"
    case work = "Work"
    case formal = "Formal"
    case athletic = "Athletic"
    case party = "Party"
}

// MARK: - Sample Data for Testing
extension ClothingItem {
    static var sampleItems: [ClothingItem] {
        [
            ClothingItem(
                category: .tops,
                brand: "Nike",
                name: "White T-Shirt",
                colors: ["White"],
                season: .allSeasons,
                occasions: [.casual]
            ),
            ClothingItem(
                category: .bottoms,
                brand: "Levi's",
                name: "Blue Jeans",
                colors: ["Blue"],
                season: .allSeasons,
                occasions: [.casual, .work]
            ),
            ClothingItem(
                category: .shoes,
                brand: "Adidas",
                name: "White Sneakers",
                colors: ["White"],
                season: .allSeasons,
                occasions: [.casual, .athletic]
            )
        ]
    }
}
