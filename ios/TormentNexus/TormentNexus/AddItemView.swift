import SwiftUI
import PhotosUI

// MARK: - Add Item View (FULLY FIXED)
struct AddItemView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: WardrobeViewModel
    
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    @State private var itemName = ""
    @State private var brand = ""
    @State private var selectedCategory: Category = .tops
    @State private var selectedSeason: Season = .allSeasons
    @State private var selectedOccasions: Set<Occasion> = []
    @State private var colorInput = ""
    @State private var selectedColors: [String] = []
    
    @State private var showingActionSheet = false
    
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
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveItem()
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedImage == nil || itemName.isEmpty)
                }
            }
            .confirmationDialog("Add Photo", isPresented: $showingActionSheet) {
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
            }
            .fullScreenCover(isPresented: $showingCamera) {
                ImagePicker(image: $selectedImage, sourceType: .camera)
                    .ignoresSafeArea()
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
                
                Button(action: {
                    showingActionSheet = true
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Change Photo")
                    }
                    .foregroundColor(.blue)
                    .padding(.vertical, 8)
                }
            } else {
                Button(action: {
                    showingActionSheet = true
                }) {
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
    
    private func saveItem() {
        guard let image = selectedImage else { return }
        
        let compressedData = image.jpegData(compressionQuality: 0.7)
        
        let newItem = ClothingItem(
            imageData: compressedData,
            category: selectedCategory,
            brand: brand,
            name: itemName,
            colors: selectedColors,
            season: selectedSeason,
            occasions: Array(selectedOccasions)
        )
        
        viewModel.addItem(newItem)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Category Button
struct CategoryButton: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title2)
                Text(category.rawValue)
                    .font(.caption)
            }
            .frame(width: 80, height: 80)
            .background(isSelected ? Color.black : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .black)
            .cornerRadius(12)
        }
    }
}

// MARK: - Color Tag
struct ColorTag: View {
    let color: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(color)
                .font(.subheadline)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(16)
    }
}

// MARK: - Occasion Toggle
struct OccasionToggle: View {
    let occasion: Occasion
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(occasion.rawValue)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.black : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .black)
                .cornerRadius(20)
        }
    }
}

// MARK: - Custom TextField Style
struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
    }
}

// MARK: - Image Picker (UIKit Bridge)
struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
