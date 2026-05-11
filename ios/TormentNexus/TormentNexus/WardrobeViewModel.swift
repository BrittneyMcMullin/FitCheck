import Foundation
import SwiftUI

class WardrobeViewModel: ObservableObject {
    @Published var items: [ClothingItem] = []
    @Published var filteredItems: [ClothingItem] = []
    @Published var selectedCategory: String = "All"
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let network = NetworkManager.shared
    
    init() {
        fetchItems()
    }
    
    // MARK: - Filtering
    func updateFilteredItems() {
        var result = items
        
        if selectedCategory != "All" {
            result = result.filter { $0.category.rawValue == selectedCategory }
        }
        
        if !searchText.isEmpty {
            result = result.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.brand.localizedCaseInsensitiveContains(searchText) ||
                item.colors.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        result.sort { $0.dateAdded > $1.dateAdded }
        filteredItems = result
    }
    
    // MARK: - API Operations
    func fetchItems() {
        print("fetchItems called, isLoggedIn: \(network.isLoggedIn)")
        guard network.isLoggedIn else {
            print("Not logged in, loading locally")
            loadItemsLocally()
            updateFilteredItems()
            return
        }
        
        isLoading = true
        network.getItems { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            print("getItems result received")
            switch result {
            case .success(let items):
                print("Got \(items.count) items from backend")
                self.items = items
                for item in items {
                    print("Item: \(item.name), imageURL: \(item.imageURL ?? "nil")")
                }
                self.updateFilteredItems()
            case .failure(let error):
                print("Failed: \(error.localizedDescription)")
                self.errorMessage = "Failed to load items: \(error.localizedDescription)"
                self.loadItemsLocally()
                self.updateFilteredItems()
            }
        }
    }
    
    func addItem(_ item: ClothingItem) {
            print("isLoggedIn: \(network.isLoggedIn)")
            print("token: \(network.token ?? "nil")")
            
        items.append(item)
        saveItemsLocally()
        updateFilteredItems()
        
        guard network.isLoggedIn else { return }
        
        if let imageData = item.imageData {
            network.uploadImage(imageData) { [weak self] result in
                guard let self = self else { return }
                var itemWithURL = item
                if case .success(let imageURL) = result {
                    itemWithURL.imageURL = imageURL
                }
                self.saveItemToBackend(itemWithURL, originalItem: item)
            }
        } else {
            saveItemToBackend(item, originalItem: item)
        }
    }

    private func saveItemToBackend(_ item: ClothingItem, originalItem: ClothingItem) {
        network.addItem(item) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let savedItem):
                if let index = self.items.firstIndex(where: { $0.id == originalItem.id }) {
                    var updated = savedItem
                    updated.imageData = originalItem.imageData
                    self.items[index] = updated
                    self.saveItemsLocally()
                    self.updateFilteredItems()
                }
            case .failure(let error):
                self.errorMessage = "Failed to save item: \(error.localizedDescription)"
            }
        }
    }
    
    func deleteItem(_ item: ClothingItem) {
        items.removeAll { $0.id == item.id }
        saveItemsLocally()
        updateFilteredItems()
        
        guard network.isLoggedIn, let serverId = item.serverId else { return }
        
        network.deleteItem(id: serverId) { [weak self] result in
            if case .failure(let error) = result {
                self?.errorMessage = "Failed to delete item: \(error.localizedDescription)"
            }
        }
    }
    
    func updateItem(_ item: ClothingItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
            saveItemsLocally()
            updateFilteredItems()
        }
    }
    
    // MARK: - Local Storage (fallback)
    private func saveItemsLocally() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: "wardrobeItems")
        }
    }
    
    private func loadItemsLocally() {
        if let data = UserDefaults.standard.data(forKey: "wardrobeItems"),
           let decoded = try? JSONDecoder().decode([ClothingItem].self, from: data) {
            items = decoded
        }
    }
    
    // MARK: - Statistics
    var totalItems: Int { items.count }
    
    var itemsByCategory: [Category: Int] {
        Dictionary(grouping: items) { $0.category }.mapValues { $0.count }
    }
    
    var mostWornItem: ClothingItem? {
        items.max { $0.timesWorn < $1.timesWorn }
    }
    
    var leastWornItems: [ClothingItem] {
        items.filter { $0.timesWorn == 0 }.sorted { $0.dateAdded < $1.dateAdded }
    }
}
