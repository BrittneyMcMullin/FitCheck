import SwiftUI

// MARK: - Item Detail View
struct ItemDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: WardrobeViewModel
    let item: ClothingItem
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ZStack {
                    Color(.systemGray5)
                    if let imageData = item.imageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else if let imageURL = item.imageURL,
                              let url = URL(string: imageURL) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                    } else {
                        Image(systemName: item.category.icon)
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                    }
                }
                .frame(width: UIScreen.main.bounds.width, height: 350)
                .clipped()
                
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.title)
                            .fontWeight(.bold)
                        Text(item.category.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Divider()
                    
                    if !item.brand.isEmpty {
                        DetailRow(icon: "tag.fill", label: "Brand", value: item.brand)
                    }
                    
                    if !item.colors.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Colors", systemImage: "paintpalette.fill")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(item.colors, id: \.self) { color in
                                        Text(color)
                                            .font(.subheadline)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.blue.opacity(0.1))
                                            .foregroundColor(.blue)
                                            .cornerRadius(16)
                                    }
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    DetailRow(icon: "sun.max.fill", label: "Season", value: item.season.rawValue)
                    
                    if !item.occasions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Occasions", systemImage: "calendar")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(item.occasions.map { $0.rawValue }, id: \.self) { occasion in
                                        Text(occasion)
                                            .font(.subheadline)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color(.systemGray6))
                                            .foregroundColor(.black)
                                            .cornerRadius(16)
                                    }
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Wear Statistics", systemImage: "chart.bar.fill")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        HStack(spacing: 30) {
                            StatBox(value: "\(item.timesWorn)", label: "Times Worn")
                            if let lastWorn = item.lastWorn {
                                StatBox(value: lastWorn.formatted(date: .abbreviated, time: .omitted), label: "Last Worn")
                            } else {
                                StatBox(value: "Never", label: "Last Worn")
                            }
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        Image(systemName: "clock.fill").foregroundColor(.gray)
                        Text("Added \(item.dateAdded.formatted(date: .long, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Item Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingEditSheet = true }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle").foregroundColor(.black)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditItemView(viewModel: viewModel, item: item)
        }
        .alert("Delete Item", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                viewModel.deleteItem(item)
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Are you sure you want to delete \(item.name)? This action cannot be undone.")
        }
    }
}
// MARK: - Detail Row
struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.subheadline)
                .foregroundColor(.gray)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
        }
    }
}

// MARK: - Stat Box
struct StatBox: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Flexible View (for wrapping chips)
struct FlexibleView<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content
    
    @State private var totalHeight = CGFloat.zero
    
    var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            GeometryReader { geometry in
                self.generateContent(in: geometry)
            }
        }
        .frame(height: totalHeight)
    }
    
    private func generateContent(in g: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        
        return ZStack(alignment: .topLeading) {
            ForEach(Array(data.enumerated()), id: \.offset) { index, element in
                content(element)
                    .padding(.trailing, spacing)
                    .padding(.bottom, spacing)
                    .alignmentGuide(.leading, computeValue: { d in
                        if (abs(width - d.width) > g.size.width) {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if index == data.count - 1 {
                            width = 0
                        } else {
                            width -= d.width
                        }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: { d in
                        let result = height
                        if index == data.count - 1 {
                            height = 0
                        }
                        return result
                    })
            }
        }
        .background(viewHeightReader($totalHeight))
    }
    
    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        return GeometryReader { geometry -> Color in
            let rect = geometry.frame(in: .local)
            DispatchQueue.main.async {
                binding.wrappedValue = rect.size.height
            }
            return .clear
        }
    }
}
