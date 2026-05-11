import SwiftUI

// MARK: - Main Tab View
struct MainTabView: View {
    @StateObject private var wardrobeViewModel = WardrobeViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            WardrobeView(viewModel: wardrobeViewModel)
                .tabItem {
                    Image(systemName: "tshirt.fill")
                    Text("Wardrobe")
                }
                .tag(0)
            
            OutfitsTabView(viewModel: wardrobeViewModel)                .tabItem {
                    Image(systemName: "rectangle.stack.fill")
                    Text("Outfits")
                }
                .tag(1)
            
            WeeklyPlannerView(viewModel: wardrobeViewModel)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Planner")
                }
                .tag(2)
            
            SocialFeedView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Feed")
                }
                .tag(3)
            
            ProfileView(viewModel: wardrobeViewModel)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(4)
        }
        .accentColor(.black)
    }
}

// MARK: - Wardrobe View (WITH BOTH TAP AND LONG-PRESS)
struct WardrobeView: View {
    @ObservedObject var viewModel: WardrobeViewModel
    @State private var showingAddItem = false
    @State private var itemToDelete: ClothingItem?
    @State private var showingDeleteAlert = false
    
    let categories = ["All", "Tops", "Bottoms", "Dresses", "Shoes", "Accessories", "Outerwear"]
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search your wardrobe", text: $viewModel.searchText)
                        .autocapitalization(.none)
                        .onChange(of: viewModel.searchText) {
                            viewModel.updateFilteredItems()
                        }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(categories, id: \.self) { category in
                            CategoryPill(
                                title: category,
                                isSelected: viewModel.selectedCategory == category
                            ) {
                                viewModel.selectedCategory = category
                                viewModel.updateFilteredItems()
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
                
              
                if viewModel.filteredItems.isEmpty {
                    EmptyWardrobeView()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.filteredItems) { item in
                                NavigationLink(destination: ItemDetailView(viewModel: viewModel, item: item)) {
                                    ClothingItemCard(item: item)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contextMenu {
                                    Button(role: .destructive) {
                                        itemToDelete = item
                                        showingDeleteAlert = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Wardrobe")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddItem = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title3)
                            .foregroundColor(.black)
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddItemView(viewModel: viewModel)
                    .onDisappear {
                        viewModel.updateFilteredItems()
                    }
            }
            .alert("Delete Item", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    itemToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let item = itemToDelete {
                        viewModel.deleteItem(item)
                    }
                    itemToDelete = nil
                }
            } message: {
                if let item = itemToDelete {
                    Text("Are you sure you want to delete \(item.name)? This action cannot be undone.")
                }
            }
        }
    }
}

// MARK: - Category Pill
struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.black : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .black)
                .cornerRadius(20)
        }
    }
}

// MARK: - Clothing Item Card
struct ClothingItemCard: View {
    let item: ClothingItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else if let imageURL = item.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Color(.systemGray5)
                            .overlay(ProgressView())
                    }
                } else {
                    Color(.systemGray5)
                        .overlay(
                            Image(systemName: item.category.icon)
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                        )
                }
            }
            .frame(width: UIScreen.main.bounds.width / 2 - 24, height: (UIScreen.main.bounds.width / 2 - 24) * 1.3)
            .clipped()
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if !item.brand.isEmpty {
                    Text(item.brand)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                if !item.colors.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(item.colors.prefix(3), id: \.self) { color in
                                Text(color)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Empty Wardrobe View
struct EmptyWardrobeView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "tshirt")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("Your wardrobe is empty")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tap the + button to add your first item")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

// MARK: - Outfits Tab View (list of saved outfits)
struct OutfitsTabView: View {
    @ObservedObject var viewModel: WardrobeViewModel
    @State private var showingCreator = false
    @State private var outfits: [[String: Any]] = []
    @State private var isLoading = false
    @State private var showingRecommendations = false
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView()
                } else if outfits.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "rectangle.stack")
                            .font(.system(size: 80))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No outfits yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Tap + to create your first outfit")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(Array(outfits.enumerated()), id: \.offset) { _, outfit in
                                OutfitCard(outfit: outfit, viewModel: viewModel, onEdited: loadOutfits)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Outfits")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showingRecommendations = true }) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.black)
                        }
                        Button(action: { showingCreator = true }) {
                            Image(systemName: "plus")
                                .font(.title3)
                                .foregroundColor(.black)
                        }
                    }
                }
            }
            .onAppear { loadOutfits() }
            .sheet(isPresented: $showingCreator, onDismiss: { loadOutfits() }) {
                OutfitCreatorView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingRecommendations) {
                RecommendationsView()
            }
        }
    }
    private func loadOutfits() {
        isLoading = true
        NetworkManager.shared.getOutfits { result in
            isLoading = false
            if case .success(let data) = result {
                outfits = data
            }
        }
    }
}

// MARK: - Outfit Creator View (build a new outfit)
struct OutfitCreatorView: View {
    @ObservedObject var viewModel: WardrobeViewModel
    @State private var selectedTop: ClothingItem?
    @State private var selectedBottom: ClothingItem?
    @State private var selectedShoes: ClothingItem?
    @State private var selectedAccessory: ClothingItem?
    @State private var showingItemPicker = false
    @State private var pickingFor: Category = .tops
    @State private var outfitName = ""
    @State private var showingNameDialog = false
    @State private var showingSaveSuccess = false
    @State private var showingRecommendations = false
    @Environment(\.presentationMode) var presentationMode

    var selectedItems: [ClothingItem] {
        [selectedTop, selectedBottom, selectedShoes, selectedAccessory].compactMap { $0 }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 16) {
                        OutfitSlotView(label: "Top", item: selectedTop, category: .tops) {
                            pickingFor = .tops; showingItemPicker = true
                        } onRemove: { selectedTop = nil }

                        OutfitSlotView(label: "Bottom", item: selectedBottom, category: .bottoms) {
                            pickingFor = .bottoms; showingItemPicker = true
                        } onRemove: { selectedBottom = nil }

                        OutfitSlotView(label: "Shoes", item: selectedShoes, category: .shoes) {
                            pickingFor = .shoes; showingItemPicker = true
                        } onRemove: { selectedShoes = nil }

                        OutfitSlotView(label: "Accessory", item: selectedAccessory, category: .accessories) {
                            pickingFor = .accessories; showingItemPicker = true
                        } onRemove: { selectedAccessory = nil }
                    }
                    .padding()
                }

                VStack(spacing: 12) {
                    if showingSaveSuccess {
                        Text("Outfit saved! ✅")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                    HStack(spacing: 16) {
                        Button(action: clearOutfit) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Clear")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .foregroundColor(.black)
                            .cornerRadius(12)
                        }
                        Button(action: {
                            if !selectedItems.isEmpty { showingNameDialog = true }
                        }) {
                            HStack {
                                Image(systemName: "checkmark")
                                Text("Save Outfit")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedItems.isEmpty ? Color.gray : Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(selectedItems.isEmpty)
                    }
                }
                .padding()
            }
            .navigationTitle("Create Outfit")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
            }
            .sheet(isPresented: $showingItemPicker) {
                ItemPickerView(
                    items: viewModel.items.filter { $0.category == pickingFor },
                    category: pickingFor
                ) { item in
                    switch pickingFor {
                    case .tops: selectedTop = item
                    case .bottoms: selectedBottom = item
                    case .shoes: selectedShoes = item
                    case .accessories: selectedAccessory = item
                    default: break
                    }
                    showingItemPicker = false
                }
            }
            .alert("Name Your Outfit", isPresented: $showingNameDialog) {
                TextField("e.g., Summer Casual", text: $outfitName)
                Button("Save") { saveOutfit() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func clearOutfit() {
        selectedTop = nil
        selectedBottom = nil
        selectedShoes = nil
        selectedAccessory = nil
        outfitName = ""
    }

    private func saveOutfit() {
        guard !selectedItems.isEmpty else { return }
        let name = outfitName.isEmpty ? "My Outfit" : outfitName
        let itemIds = selectedItems.compactMap { $0.serverId }
        
        print("Saving outfit: \(name)")
        print("Item IDs: \(itemIds)")
        print("Is logged in: \(NetworkManager.shared.isLoggedIn)")
        
        NetworkManager.shared.saveOutfit(name: name, itemIds: itemIds) { result in
            switch result {
            case .success:
                print("Outfit saved successfully!")
                showingSaveSuccess = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showingSaveSuccess = false
                    clearOutfit()
                    presentationMode.wrappedValue.dismiss()
                }
            case .failure(let error):
                print("Failed to save outfit: \(error.localizedDescription)")
            }
        }
        outfitName = ""
    }
}

// MARK: - Outfit Card
struct OutfitCard: View {
    @State private var showingShare = false
    @State private var caption = ""
    @State private var shareSuccess = false
    @State private var showingEdit = false
    @State private var showingDeleteAlert = false

    var outfitId: Int { outfit["id"] as? Int ?? 0 }
    let outfit: [String: Any]
    var viewModel: WardrobeViewModel
    var onEdited: () -> Void


    var outfitName: String { outfit["name"] as? String ?? "Unnamed Outfit" }
    var items: [[String: Any]] { outfit["items"] as? [[String: Any]] ?? [] }

    var createdAt: String {
        guard let dateStr = outfit["created_at"] as? String else { return "" }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateStr) {
            let display = DateFormatter()
            display.dateStyle = .medium
            return display.string(from: date)
        }
        return ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(outfitName).font(.headline)
                Spacer()
                Text(createdAt).font(.caption).foregroundColor(.gray)
            }

            if items.isEmpty {
                Text("No items").font(.caption).foregroundColor(.gray)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                            VStack(spacing: 4) {
                                if let imageURL = item["image_url"] as? String,
                                   let url = URL(string: imageURL) {
                                    AsyncImage(url: url) { image in
                                        image.resizable().scaledToFill()
                                    } placeholder: {
                                        Color(.systemGray5)
                                    }
                                    .frame(width: 80, height: 80)
                                    .clipped()
                                    .cornerRadius(10)
                                } else {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(.systemGray5))
                                        .frame(width: 80, height: 80)
                                        .overlay(Image(systemName: "tshirt.fill").foregroundColor(.gray))
                                }
                                Text(item["name"] as? String ?? "")
                                    .font(.caption2).lineLimit(1).frame(width: 80)
                            }
                        }
                    }
                }
            }

            Divider()

            HStack {
                Button(action: { showingEdit = true }) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Edit")
                    }
                    .font(.subheadline)
                    .foregroundColor(.black)
                }
                Spacer()
                if shareSuccess {
                    Text("Shared to feed! ✅").font(.caption).foregroundColor(.green)
                } else {
                    Button(action: { showingShare = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share to Feed")
                        }
                        .font(.subheadline)
                        .foregroundColor(.black)
                    }
                }
                Spacer()
                Button(action: { showingDeleteAlert = true }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .alert("Share Outfit", isPresented: $showingShare) {
            TextField("Add a caption...", text: $caption)
            Button("Share") { shareOutfit() }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showingEdit) {
            EditOutfitView(
                outfit: outfit,
                viewModel: viewModel,
                onSaved: onEdited
            )
        }
        .alert("Delete Outfit", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                NetworkManager.shared.deleteOutfit(outfitId: outfitId) { result in
                    if case .success = result {
                        onEdited()
                    }
                }
            }
        } message: {
            Text("Delete \"\(outfitName)\"? This cannot be undone.")
        }
    }

    private func shareOutfit() {
        NetworkManager.shared.shareOutfit(outfitId: outfitId, caption: caption) { result in
            if case .success = result {
                shareSuccess = true
                caption = ""
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    shareSuccess = false
                }
            }
        }
    }
}

// MARK: - Outfit Slot View
struct OutfitSlotView: View {
    let label: String
    let item: ClothingItem?
    let category: Category
    let onTap: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.headline)
                Spacer()
                if item != nil {
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Button(action: onTap) {
                if let item = item {
                    HStack(spacing: 16) {
                        Group {
                            if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                            } else if let imageURL = item.imageURL, let url = URL(string: imageURL) {
                                AsyncImage(url: url) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Color(.systemGray5)
                                }
                            } else {
                                Color(.systemGray5)
                                    .overlay(
                                        Image(systemName: category.icon)
                                            .foregroundColor(.gray)
                                    )
                            }
                        }
                        .frame(width: 80, height: 80)
                        .clipped()
                        .cornerRadius(10)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            if !item.brand.isEmpty {
                                Text(item.brand)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                } else {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Add \(label)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                            .foregroundColor(.gray.opacity(0.5))
                    )
                }
            }
        }
    }
}

// MARK: - Item Picker View
struct ItemPickerView: View {
    let items: [ClothingItem]
    let category: Category
    let onSelect: (ClothingItem) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        NavigationView {
            Group {
                if items.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: category.icon)
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No \(category.rawValue) in your wardrobe")
                            .font(.headline)
                        Text("Add some items first!")
                            .foregroundColor(.gray)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(items) { item in
                                Button(action: { onSelect(item) }) {
                                    ClothingItemCard(item: item)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Choose \(category.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @ObservedObject var viewModel: WardrobeViewModel
    @EnvironmentObject var appState: AppState
    @State private var displayName = UserDefaults.standard.string(forKey: "display_name") ?? ""
    @State private var totalItems = 0
    @State private var totalOutfits = 0
    @State private var followers = 0
    @State private var showingImagePicker = false
    @State private var profileImage: UIImage?
    @State private var profilePhotoURL: String? = UserDefaults.standard.string(forKey: "profile_photo_url")
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Button(action: { showingImagePicker = true }) {
                            ZStack(alignment: .bottomTrailing) {
                                if let urlStr = profilePhotoURL, let url = URL(string: urlStr) {
                                    AsyncImage(url: url) { image in
                                        image.resizable().scaledToFill()
                                    } placeholder: {
                                        Circle().fill(Color(.systemGray5))
                                            .frame(width: 100, height: 100)
                                    }
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color(.systemGray5))
                                        .frame(width: 100, height: 100)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 40))
                                                .foregroundColor(.gray)
                                        )
                                }
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                        .sheet(isPresented: $showingImagePicker) {
                            ImagePicker(image: $profileImage, sourceType: .photoLibrary)
                                .onDisappear {
                                    if let img = profileImage,
                                       let data = img.jpegData(compressionQuality: 0.7) {
                                        NetworkManager.shared.uploadImage(data) { result in
                                            if case .success(let url) = result {
                                                DispatchQueue.main.async {
                                                    profilePhotoURL = url
                                                    UserDefaults.standard.set(url, forKey: "profile_photo_url")
                                                }
                                                NetworkManager.shared.updateProfilePhoto(url: url) { _ in }
                                            }
                                        }
                                    }
                                }
                        }
                        
                        Text(displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 40) {
                            StatItem(number: "\(totalItems)", label: "Items")
                            StatItem(number: "\(totalOutfits)", label: "Outfits")
                            StatItem(number: "\(followers)", label: "Followers")
                        }
                        .padding(.top, 8)
                    }
                    .padding(.top)
                    
                    VStack(spacing: 0) {
                        NavigationLink(destination: ChangePasswordView()) {
                            HStack {
                                Image(systemName: "lock")
                                    .frame(width: 24)
                                Text("Change Password")
                                    .fontWeight(.medium)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .foregroundColor(.black)
                            .padding()
                        }
                        Divider()
                        NavigationLink(destination: AnalyticsView()) {
                            HStack {
                                Image(systemName: "chart.bar")
                                    .frame(width: 24)
                                Text("Analytics")
                                    .fontWeight(.medium)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .foregroundColor(.black)
                            .padding()
                        }
                        Divider()
                        NavigationLink(destination: SettingsView()) {
                            HStack {
                                Image(systemName: "gearshape")
                                    .frame(width: 24)
                                Text("Settings")
                                    .fontWeight(.medium)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .foregroundColor(.black)
                            .padding()
                        }
                        Divider()
                        Button(action: {
                            NetworkManager.shared.logout()
                            appState.isLoggedIn = false
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .frame(width: 24)
                                Text("Log Out")
                                    .fontWeight(.medium)
                                Spacer()
                            }
                            .foregroundColor(.red)
                            .padding()
                        }
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Profile")
            .onAppear { loadStats() }
        }
    }
    
    private func loadStats() {
        NetworkManager.shared.getAnalytics { result in
            if case .success(let data) = result {
                if let totals = data["totals"] as? [String: Any] {
                    totalItems = Int(totals["total_items"] as? String ?? "0") ?? 0
                    totalOutfits = Int(totals["total_outfits"] as? String ?? "0") ?? 0
                    followers = Int(totals["followers"] as? String ?? "0") ?? 0
                }
            }
        }
        NetworkManager.shared.getProfile { result in
            if case .success(let data) = result {
                DispatchQueue.main.async {
                    if let name = data["display_name"] as? String {
                        displayName = name
                        UserDefaults.standard.set(name, forKey: "display_name")
                    }
                    if let photoURL = data["profile_photo_url"] as? String, !photoURL.isEmpty {
                        profilePhotoURL = photoURL
                        UserDefaults.standard.set(photoURL, forKey: "profile_photo_url")
                    }
                }
            }
        }
    }
    
    // MARK: - Stat Item
    struct StatItem: View {
        let number: String
        let label: String
        
        var body: some View {
            VStack(spacing: 4) {
                Text(number)
                    .font(.title3)
                    .fontWeight(.bold)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    
    // MARK: - Settings Row
    struct SettingsRow: View {
        let icon: String
        let title: String
        
        var body: some View {
            Button(action: {}) {
                HStack {
                    Image(systemName: icon)
                        .frame(width: 24)
                    Text(title)
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .foregroundColor(.black)
                .padding()
            }
        }
    }
    
    // MARK: - Settings View
    struct SettingsView: View {
        @State private var donationThreshold = 60.0
        
        var body: some View {
            List {
                Section(header: Text("Notifications")) {
                    HStack {
                        Text("Unworn item reminder")
                        Spacer()
                        Text("\(Int(donationThreshold)) days")
                            .foregroundColor(.gray)
                    }
                    Slider(value: $donationThreshold, in: 30...180, step: 10)
                        .accentColor(.black)
                }
                
                Section(header: Text("Account")) {
                    NavigationLink(destination: ChangeDisplayNameView()) {
                        Text("Change Display Name")
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0").foregroundColor(.gray)
                    }
                    HStack {
                        Text("Developer")
                        Spacer()
                        Text("Brittney McMullin").foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Preview
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            MainTabView()
        }
    }
    // MARK: - Change Display Name View
    struct ChangeDisplayNameView: View {
        @State private var newName = ""
        @State private var successMessage = ""
        @State private var isLoading = false
        @Environment(\.presentationMode) var presentationMode
        
        var body: some View {
            List {
                Section(header: Text("New display name")) {
                    TextField("Enter new name", text: $newName)
                        .autocapitalization(.words)
                }
                Section {
                    Button(action: saveName) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                                .foregroundColor(newName.isEmpty ? .gray : .black)
                        }
                    }
                    .disabled(newName.isEmpty || isLoading)
                }
                if !successMessage.isEmpty {
                    Section {
                        Text(successMessage)
                            .foregroundColor(.green)
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle("Change Display Name")
            .navigationBarTitleDisplayMode(.large)
        }
        
        private func saveName() {
            isLoading = true
            NetworkManager.shared.updateDisplayName(name: newName) { result in
                isLoading = false
                switch result {
                case .success:
                    UserDefaults.standard.set(newName, forKey: "display_name")
                    successMessage = "Display name updated!"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        presentationMode.wrappedValue.dismiss()
                    }
                case .failure:
                    successMessage = "Failed to update. Try again."
                }
            }
        }
    }
}
