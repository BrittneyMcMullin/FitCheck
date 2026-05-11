import SwiftUI

struct AnalyticsView: View {
    @State private var analytics: [String: Any] = [:]
    @State private var isLoading = true

    var totals: [String: Any] { analytics["totals"] as? [String: Any] ?? [:] }
    var mostWorn: [[String: Any]] { analytics["most_worn"] as? [[String: Any]] ?? [] }
    var unworn: [[String: Any]] { analytics["unworn"] as? [[String: Any]] ?? [] }
    var categories: [[String: Any]] { analytics["categories"] as? [[String: Any]] ?? [] }

    var totalItems: Int { Int(totals["total_items"] as? String ?? "0") ?? 0 }
    var totalOutfits: Int { Int(totals["total_outfits"] as? String ?? "0") ?? 0 }
    var followers: Int { Int(totals["followers"] as? String ?? "0") ?? 0 }
    var following: Int { Int(totals["following"] as? String ?? "0") ?? 0 }

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
                    .padding(.top, 60)
            } else {
                VStack(spacing: 24) {

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Overview")
                            .font(.headline)
                            .padding(.horizontal)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            AnalyticsStatCard(number: "\(totalItems)", label: "Total Items", icon: "tshirt.fill")
                            AnalyticsStatCard(number: "\(totalOutfits)", label: "Outfits", icon: "rectangle.stack.fill")
                            AnalyticsStatCard(number: "\(followers)", label: "Followers", icon: "person.2.fill")
                            AnalyticsStatCard(number: "\(following)", label: "Following", icon: "person.fill.checkmark")
                        }
                        .padding(.horizontal)
                    }

                    if !categories.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("By Category")
                                .font(.headline)
                                .padding(.horizontal)
                            VStack(spacing: 8) {
                                ForEach(Array(categories.enumerated()), id: \.offset) { _, cat in
                                    let name = cat["category"] as? String ?? ""
                                    let count = Int(cat["count"] as? String ?? "0") ?? 0
                                    let percentage = totalItems > 0 ? CGFloat(count) / CGFloat(totalItems) : 0

                                    HStack(spacing: 12) {
                                        Text(name.capitalized)
                                            .font(.subheadline)
                                            .frame(width: 100, alignment: .leading)
                                        GeometryReader { geo in
                                            ZStack(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color(.systemGray5))
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color.black)
                                                    .frame(width: geo.size.width * percentage)
                                            }
                                        }
                                        .frame(height: 8)
                                        Text("\(count)")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                            .frame(width: 24, alignment: .trailing)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }

                    if !mostWorn.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Most Worn")
                                .font(.headline)
                                .padding(.horizontal)
                            ForEach(Array(mostWorn.enumerated()), id: \.offset) { index, item in
                                HStack(spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .frame(width: 20)
                                    if let urlStr = item["image_url"] as? String, let url = URL(string: urlStr) {
                                        AsyncImage(url: url) { img in
                                            img.resizable().scaledToFill()
                                        } placeholder: { Color(.systemGray5) }
                                        .frame(width: 48, height: 48)
                                        .clipped()
                                        .cornerRadius(8)
                                    } else {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(.systemGray5))
                                            .frame(width: 48, height: 48)
                                            .overlay(Image(systemName: "tshirt.fill").foregroundColor(.gray))
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item["name"] as? String ?? "")
                                            .font(.subheadline).fontWeight(.medium)
                                        Text((item["category"] as? String ?? "").capitalized)
                                            .font(.caption).foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Text("\(Int(item["wear_count"] as? String ?? "0") ?? 0)x")
                                        .font(.subheadline).foregroundColor(.gray)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    if !unworn.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Never Worn")
                                .font(.headline)
                                .padding(.horizontal)
                            Text("Consider donating these items")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                            ForEach(Array(unworn.enumerated()), id: \.offset) { _, item in
                                HStack(spacing: 12) {
                                    if let urlStr = item["image_url"] as? String, let url = URL(string: urlStr) {
                                        AsyncImage(url: url) { img in
                                            img.resizable().scaledToFill()
                                        } placeholder: { Color(.systemGray5) }
                                        .frame(width: 48, height: 48)
                                        .clipped()
                                        .cornerRadius(8)
                                    } else {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(.systemGray5))
                                            .frame(width: 48, height: 48)
                                            .overlay(Image(systemName: "tshirt.fill").foregroundColor(.gray))
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item["name"] as? String ?? "")
                                            .font(.subheadline).fontWeight(.medium)
                                        Text((item["category"] as? String ?? "").capitalized)
                                            .font(.caption).foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Image(systemName: "exclamationmark.circle")
                                        .foregroundColor(.orange)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { loadAnalytics() }
    }

    private func loadAnalytics() {
        NetworkManager.shared.getAnalytics { result in
            isLoading = false
            if case .success(let data) = result {
                analytics = data
            }
        }
    }
}

struct AnalyticsStatCard: View {
    let number: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.black)
            Text(number)
                .font(.title2).fontWeight(.bold)
            Text(label)
                .font(.caption).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
