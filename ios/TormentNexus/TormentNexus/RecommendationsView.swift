import SwiftUI
import CoreLocation

struct RecommendationsView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var recommendations: [[String: Any]] = []
    @State private var weather: [String: Any] = [:]
    @State private var isLoading = false
    @Environment(\.presentationMode) var presentationMode

    var temperature: String {
        if let temp = weather["temperature"] as? Int {
            return "\(temp)°F"
        }
        return "--°F"
    }

    var condition: String {
        (weather["condition"] as? String ?? "").capitalized
    }

    var description: String {
        (weather["description"] as? String ?? "").capitalized
    }

    var weatherIcon: String {
        switch weather["condition"] as? String {
        case "cold": return "snowflake"
        case "cool": return "cloud.fill"
        case "warm": return "sun.max.fill"
        default: return "cloud.sun.fill"
        }
    }

    var weatherIconColor: Color {
        switch weather["condition"] as? String {
        case "cold": return .blue
        case "cool": return .gray
        case "warm": return .orange
        default: return .yellow
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    HStack(spacing: 16) {
                        Image(systemName: weatherIcon)
                            .font(.system(size: 44))
                            .foregroundColor(weatherIconColor)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(temperature)
                                .font(.title)
                                .fontWeight(.bold)
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text("Outfits styled for today's weather")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    if isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Styling your outfits...")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 40)
                    } else if recommendations.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 60))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("No recommendations yet")
                                .font(.headline)
                            Text("Add more items to your wardrobe to get outfit suggestions")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            Button(action: loadRecommendations) {
                                Text("Try Again")
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.black)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.top, 40)
                    } else {
                        ForEach(Array(recommendations.enumerated()), id: \.offset) { _, rec in
                            OccasionOutfitCard(recommendation: rec)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("For You")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: loadRecommendations) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.black)
                    }
                }
            }
            .onAppear { loadRecommendations() }
        }
    }

    private func loadRecommendations() {
        isLoading = true
        let lat = locationManager.latitude ?? 34.2805
        let lon = locationManager.longitude ?? -119.2945

        NetworkManager.shared.getRecommendations(lat: lat, lon: lon) { result in
            isLoading = false
            switch result {
            case .success(let data):
                weather = data["weather"] as? [String: Any] ?? [:]
                recommendations = data["recommendations"] as? [[String: Any]] ?? []
            case .failure(let error):
                print("Recommendations error: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Occasion Outfit Card
struct OccasionOutfitCard: View {
    let recommendation: [String: Any]
    @State private var isSaved = false
    @State private var isSaving = false

    var label: String { recommendation["label"] as? String ?? "" }
    var outfit: [String: Any] { recommendation["outfit"] as? [String: Any] ?? [:] }

    let slots = ["top", "bottom", "dress", "shoes", "outerwear", "accessory"]

    var itemIds: [Int] {
        slots.compactMap { slot in
            if let item = outfit[slot] as? [String: Any] {
                return item["id"] as? Int
            }
            return nil
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(label)
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }

            Divider()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(slots, id: \.self) { slot in
                        if let item = outfit[slot] as? [String: Any] {
                            VStack(spacing: 6) {
                                if let imageURL = item["image_url"] as? String,
                                   let url = URL(string: imageURL) {
                                    AsyncImage(url: url) { image in
                                        image.resizable().scaledToFill()
                                    } placeholder: {
                                        Color(.systemGray5).overlay(ProgressView())
                                    }
                                    .frame(width: 90, height: 110)
                                    .clipped()
                                    .cornerRadius(10)
                                } else {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(.systemGray5))
                                        .frame(width: 90, height: 110)
                                        .overlay(Image(systemName: "tshirt.fill").foregroundColor(.gray))
                                }
                                Text(item["name"] as? String ?? "")
                                    .font(.caption2).fontWeight(.medium)
                                    .lineLimit(1).frame(width: 90)
                                Text(slot.capitalized)
                                    .font(.caption2).foregroundColor(.gray)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            Divider()

            Button(action: saveOutfit) {
                HStack {
                    Image(systemName: isSaved ? "checkmark.circle.fill" : "plus.circle")
                    Text(isSaved ? "Saved to Outfits!" : isSaving ? "Saving..." : "Save as Outfit")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSaved ? Color.green.opacity(0.1) : Color.black)
                .foregroundColor(isSaved ? .green : .white)
                .cornerRadius(10)
            }
            .disabled(isSaved || isSaving)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }

    private func saveOutfit() {
        guard !itemIds.isEmpty else { return }
        isSaving = true
        NetworkManager.shared.saveOutfit(name: label, itemIds: itemIds) { result in
            isSaving = false
            if case .success = result {
                isSaved = true
            }
        }
    }
}
// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var latitude: Double?
    @Published var longitude: Double?

    override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        latitude = locations.first?.coordinate.latitude
        longitude = locations.first?.coordinate.longitude
    }
}
