import SwiftUI
import PhotosUI

// MARK: - Edit Item View
struct EditItemView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: WardrobeViewModel
    let item: ClothingItem
    
    @State private var selectedImage: UIImage?
    @State private var imageChanged = false
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    @State private var itemName: String
    @State private var brand: String
    @State private var selectedCategory: Category
    @State private var selectedSeason: Season
    @State private var selectedOccasions: Set<Occasion>
    @State private var colorInput = ""
    @State private var selectedColors: [String]
    
    @State private var showingActionSheet = false
    
    init(viewModel: WardrobeViewModel, item: ClothingItem) {
        self.viewModel = viewModel
        self.item = item
        
        _itemName = State(initialValue: item.name)
        _brand = State(initialValue: item.brand)
        _selectedCategory = State(initialValue: item.category)
        _selectedSeason = State(initialValue: item.season)
        _selectedOccasions = State(initialValue: Set(item.occasions))
        _selectedColors = State(initialValue: item.colors)
        
        if let imageData = item.imageData,
           let image = UIImage(data: imageData) {
            _selectedImage = State(initialValue: image)
        } else {
            _selectedImage = State(initialValue: nil)
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    imageSelectionSection
                    
                    formSection
                    
                    Color.clear.frame(height: 100)
                }
                .padding()
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .disabled(itemName.isEmpty)
                }
            }
            .confirmationDialog("Change Photo", isPresented: $showingActionSheet) {
                Button("Take Photo") {
                    sourceType = .camera
                    showingCamera = true
                }
                Button("Choose from Library") {
                    sourceType = .photoLibrary
                    showingImagePicker = true
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: sourceType)
                    .onDisappear {
                        imageChanged = true
                    }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                ImagePicker(image: $selectedImage, sourceType: .camera)
                    .onDisappear {
                        imageChanged = true
                    }
            }
        }
    }
    
    // MARK: - Image Selection Section
    private var imageSelectionSection: some View {
        VStack(spacing: 12) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width - 32, height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                Button(action: { showingActionSheet = true }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Change Photo")
                    }
                    .foregroundColor(.blue)
                    .padding(.vertical, 8)
                }
            } else if let imageURL = item.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color(.systemGray5).overlay(ProgressView())
                }
                .frame(width: UIScreen.main.bounds.width - 32, height: 250)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                Button(action: { showingActionSheet = true }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Change Photo")
                    }
                    .foregroundColor(.blue)
                    .padding(.vertical, 8)
                }
            } else {
                Button(action: { showingActionSheet = true }) {
                    VStack(spacing: 16) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("Add Photo")
                            .font(.headline)
                        Text("Take a photo or choose from library")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 250)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                }
            }
        }
    }
    
    // MARK: - Form Section
    private var formSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Item Name *")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                TextField("e.g., White T-Shirt", text: $itemName)
                    .textFieldStyle(RoundedTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Category *")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Category.allCases, id: \.self) { category in
                            CategoryButton(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Brand")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                TextField("e.g., Nike, Zara", text: $brand)
                    .textFieldStyle(RoundedTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Colors")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                HStack {
                    TextField("Add color", text: $colorInput)
                        .textFieldStyle(RoundedTextFieldStyle())
                    
                    Button(action: addColor) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .disabled(colorInput.isEmpty)
                }
                
                if !selectedColors.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(selectedColors, id: \.self) { color in
                                ColorTag(color: color) {
                                    selectedColors.removeAll { $0 == color }
                                }
                            }
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Season")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Picker("Season", selection: $selectedSeason) {
                    ForEach(Season.allCases, id: \.self) { season in
                        Text(season.rawValue).tag(season)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Occasions")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        ForEach(Array(Occasion.allCases.prefix(3)), id: \.self) { occasion in
                            OccasionToggle(
                                occasion: occasion,
                                isSelected: selectedOccasions.contains(occasion)
                            ) {
                                if selectedOccasions.contains(occasion) {
                                    selectedOccasions.remove(occasion)
                                } else {
                                    selectedOccasions.insert(occasion)
                                }
                            }
                        }
                    }
                    
                    HStack(spacing: 8) {
                        ForEach(Array(Occasion.allCases.dropFirst(3)), id: \.self) { occasion in
                            OccasionToggle(
                                occasion: occasion,
                                isSelected: selectedOccasions.contains(occasion)
                            ) {
                                if selectedOccasions.contains(occasion) {
                                    selectedOccasions.remove(occasion)
                                } else {
                                    selectedOccasions.insert(occasion)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    private func addColor() {
        let trimmed = colorInput.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && !selectedColors.contains(trimmed) {
            selectedColors.append(trimmed)
            colorInput = ""
        }
    }
    
    private func saveChanges() {
        var imageData: Data? = item.imageData
        var imageURL: String? = item.imageURL
        
        if imageChanged, let image = selectedImage {
            imageData = image.jpegData(compressionQuality: 0.7)
            imageURL = nil
        }

        let updatedItem = ClothingItem(
            id: item.id,
            imageData: imageData,
            imageURL: imageURL, 
            category: selectedCategory,
            brand: brand,
            name: itemName,
            colors: selectedColors,
            season: selectedSeason,
            occasions: Array(selectedOccasions),
            dateAdded: item.dateAdded,
            lastWorn: item.lastWorn,
            timesWorn: item.timesWorn
        )

        viewModel.updateItem(updatedItem)
        presentationMode.wrappedValue.dismiss()
    }
}
