import SwiftUI

struct EditOutfitView: View {
    let outfit: [String: Any]
    let onSaved: () -> Void
    @ObservedObject var viewModel: WardrobeViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var outfitName: String
    @State private var selectedTop: ClothingItem?
    @State private var selectedBottom: ClothingItem?
    @State private var selectedShoes: ClothingItem?
    @State private var selectedAccessory: ClothingItem?
    @State private var activePickerCategory: Category? = nil
    @State private var pickingFor: Category = .tops
    @State private var isSaving = false
    
    var outfitId: Int { outfit["id"] as? Int ?? 0 }
    
    init(outfit: [String: Any], viewModel: WardrobeViewModel, onSaved: @escaping () -> Void) {
        self.outfit = outfit
        self.viewModel = viewModel
        self.onSaved = onSaved
        _outfitName = State(initialValue: outfit["name"] as? String ?? "")
    }
    
    var selectedItems: [ClothingItem] {
        [selectedTop, selectedBottom, selectedShoes, selectedAccessory].compactMap { $0 }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Outfit Name")
                                .font(.headline)
                            TextField("e.g., Summer Casual", text: $outfitName)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        OutfitSlotView(label: "Top", item: selectedTop, category: .tops) {
                            activePickerCategory = .tops
                        } onRemove: { selectedTop = nil }
                        
                        OutfitSlotView(label: "Bottom", item: selectedBottom, category: .bottoms) {
                            activePickerCategory = .bottoms
                        } onRemove: { selectedBottom = nil }
                        
                        OutfitSlotView(label: "Shoes", item: selectedShoes, category: .shoes) {
                            activePickerCategory = .shoes
                        } onRemove: { selectedShoes = nil }
                        
                        OutfitSlotView(label: "Accessory", item: selectedAccessory, category: .accessories) {
                            activePickerCategory = .accessories
                        } onRemove: { selectedAccessory = nil }
                    }
                    .padding(.vertical)
                }
                
                Button(action: saveChanges) {
                    HStack {
                        Image(systemName: "checkmark")
                        Text(isSaving ? "Saving..." : "Save Changes")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isSaving)
                .padding()
            }
            .navigationTitle("Edit Outfit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
            }
            .sheet(item: $activePickerCategory) { category in
                ItemPickerView(
                    items: viewModel.items.filter { $0.category == category },
                    category: category
                ) { item in
                    switch category {
                    case .tops: selectedTop = item
                    case .bottoms: selectedBottom = item
                    case .shoes: selectedShoes = item
                    case .accessories: selectedAccessory = item
                    default: break
                    }
                    activePickerCategory = nil
                }
            }
            .onAppear { loadCurrentItems() }
        }
    }
    
    private func loadCurrentItems() {
        guard let items = outfit["items"] as? [[String: Any]] else { return }
        for item in items {
            guard let id = item["id"] as? Int,
                  let category = item["category"] as? String else { continue }
            let match = viewModel.items.first { $0.serverId == id }
            switch category.lowercased() {
            case "tops": selectedTop = match
            case "bottoms": selectedBottom = match
            case "shoes": selectedShoes = match
            case "accessories": selectedAccessory = match
            default: break
            }
        }
    }
    
    private func saveChanges() {
        isSaving = true
        let name = outfitName.isEmpty ? "My Outfit" : outfitName
        let itemIds = [selectedTop, selectedBottom, selectedShoes, selectedAccessory]
            .compactMap { $0?.serverId }
        
        NetworkManager.shared.updateOutfit(outfitId: outfitId, name: name, itemIds: itemIds) { result in
            DispatchQueue.main.async {
                isSaving = false
                onSaved()
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
extension Category: Identifiable {
    var id: String { rawValue }
}
