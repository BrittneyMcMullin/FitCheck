
import Foundation

struct BackendItem: Codable {
    let id: Int
    let name: String
    let category: String
    let brand: String?
    let image_url: String?
    let season: String?
    let occasion: String?
    let colors: [String]?
    let tags: [String]?
    let created_at: String?
    
    func toClothingItem() -> ClothingItem {
        let categoryValue = Category(rawValue: category)
        ?? Category(rawValue: category.prefix(1).uppercased() + category.dropFirst().lowercased())
        ?? .tops
        
        let seasonStr = season?.replacingOccurrences(of: "_", with: " ") ?? ""
        let seasonCap = seasonStr.prefix(1).uppercased() + seasonStr.dropFirst().lowercased()
        let seasonValue = Season(rawValue: seasonCap) ?? .allSeasons
        
        var occasionList: [Occasion] = []
        if let occ = occasion {
            let occCap = occ.prefix(1).uppercased() + occ.dropFirst().lowercased()
            if let o = Occasion(rawValue: occCap) {
                occasionList = [o]
            }
        }
        if let tagList = tags {
            for tag in tagList {
                let tagCap = tag.prefix(1).uppercased() + tag.dropFirst().lowercased()
                if let o = Occasion(rawValue: tagCap), !occasionList.contains(o) {
                    occasionList.append(o)
                }
            }
        }
        
        return ClothingItem(
            serverId: id,
            imageURL: image_url,
            category: categoryValue,
            brand: brand ?? "",
            name: name,
            colors: colors ?? [],
            season: seasonValue,
            occasions: occasionList
        )
    }
}
