import SwiftUI

struct WeeklyPlannerView: View {
    @ObservedObject var viewModel: WardrobeViewModel
    @State private var weekPlan: [[String: Any]] = []
    @State private var outfits: [[String: Any]] = []
    @State private var isLoading = false
    @State private var showingOutfitPicker = false
    @State private var selectedDate = ""
    @State private var weekStart = Date()

    let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var weekDates: [Date] {
        let calendar = Calendar.current
        let monday = calendar.date(from: calendar.dateComponents(
            [.yearForWeekOfYear, .weekOfYear], from: weekStart))!
        return (0..<7).map { calendar.date(byAdding: .day, value: $0, to: monday)! }
    }

    var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }

    var displayFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Button(action: { changeWeek(by: -1) }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                    }
                    Spacer()
                    Text(weekRangeText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Button(action: { changeWeek(by: 1) }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.black)
                    }
                }
                .padding()

                Divider()

                if isLoading {
                    ProgressView().padding(.top, 40)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(Array(weekDates.enumerated()), id: \.offset) { index, date in
                                DayPlanCard(
                                    day: days[index],
                                    date: displayFormatter.string(from: date),
                                    dateString: dateFormatter.string(from: date),
                                    isToday: Calendar.current.isDateInToday(date),
                                    planEntry: planForDate(dateFormatter.string(from: date)),
                                    onAdd: {
                                        selectedDate = dateFormatter.string(from: date)
                                        showingOutfitPicker = true
                                    },
                                    onMarkWorn: { plannerId in
                                        markWorn(plannerId: plannerId)
                                    },
                                    onRemove: { plannerId in
                                        removeEntry(plannerId: plannerId)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Weekly Planner")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { loadWeek() }
            .sheet(isPresented: $showingOutfitPicker, onDismiss: { loadWeek() }) {
                OutfitPickerSheet(
                    outfits: outfits,
                    onSelect: { outfitId in
                        assignOutfit(outfitId: outfitId, date: selectedDate)
                        showingOutfitPicker = false
                    }
                )
            }
        }
    }

    var weekRangeText: String {
        guard let first = weekDates.first, let last = weekDates.last else { return "" }
        return "\(displayFormatter.string(from: first)) – \(displayFormatter.string(from: last))"
    }

    private func planForDate(_ date: String) -> [String: Any]? {
        weekPlan.first { $0["planned_date"] as? String == date }
    }

    private func changeWeek(by weeks: Int) {
        weekStart = Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: weekStart)!
        loadWeek()
    }

    private func loadWeek() {
        isLoading = true
        let startStr = dateFormatter.string(from: weekDates.first ?? Date())
        NetworkManager.shared.getWeekPlan(startDate: startStr) { result in
            isLoading = false
            if case .success(let data) = result {
                weekPlan = data.map { entry in
                    var e = entry
                    if let raw = entry["planned_date"] as? String {
                        e["planned_date"] = String(raw.prefix(10))
                    }
                    return e
                }
            }
        }
        NetworkManager.shared.getOutfits { result in
            if case .success(let data) = result { outfits = data }
        }
    }

    private func assignOutfit(outfitId: Int, date: String) {
        NetworkManager.shared.assignOutfitToDay(outfitId: outfitId, date: date) { _ in
            loadWeek()
        }
    }

    private func markWorn(plannerId: Int) {
        weekPlan = weekPlan.map { entry in
            var e = entry
            if e["id"] as? Int == plannerId {
                e["worn"] = true
            }
            return e
        }
        NetworkManager.shared.markOutfitWorn(plannerId: plannerId) { _ in }
    }

    private func removeEntry(plannerId: Int) {
        NetworkManager.shared.removePlannerEntry(plannerId: plannerId) { _ in
            loadWeek()
        }
    }
}

// MARK: - Day Plan Card
struct DayPlanCard: View {
    let day: String
    let date: String
    let dateString: String
    let isToday: Bool
    let planEntry: [String: Any]?
    let onAdd: () -> Void
    let onMarkWorn: (Int) -> Void
    let onRemove: (Int) -> Void

    var plannerId: Int { planEntry?["id"] as? Int ?? 0 }
    var isWorn: Bool { planEntry?["worn"] as? Bool ?? false }
    var outfitName: String { planEntry?["outfit_name"] as? String ?? "" }
    var items: [[String: Any]] { planEntry?["items"] as? [[String: Any]] ?? [] }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(day)
                        .font(.headline)
                        .foregroundColor(isToday ? .white : .primary)
                    Text(date)
                        .font(.caption)
                        .foregroundColor(isToday ? .white.opacity(0.8) : .gray)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isToday ? Color.black : Color(.systemGray6))
                .cornerRadius(10)

                Spacer()

                if planEntry != nil {
                    if isWorn {
                        Label("Worn", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Button(action: { onMarkWorn(plannerId) }) {
                            Text("Mark Worn")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.black)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                }
            }

            if let _ = planEntry {
                HStack(spacing: 10) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(items.prefix(4).enumerated()), id: \.offset) { _, item in
                                if let urlStr = item["image_url"] as? String,
                                   let url = URL(string: urlStr) {
                                    AsyncImage(url: url) { img in
                                        img.resizable().scaledToFill()
                                    } placeholder: { Color(.systemGray5) }
                                    .frame(width: 56, height: 56)
                                    .clipped()
                                    .cornerRadius(8)
                                } else {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.systemGray5))
                                        .frame(width: 56, height: 56)
                                        .overlay(Image(systemName: "tshirt.fill").foregroundColor(.gray))
                                }
                            }
                        }
                    }
                    Spacer()
                    Button(action: { onRemove(plannerId) }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.title3)
                    }
                }

                Text(outfitName)
                    .font(.caption)
                    .foregroundColor(.gray)

            } else {
                Button(action: onAdd) {
                    HStack {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.gray)
                        Text("Plan an outfit")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                            .foregroundColor(.gray.opacity(0.4))
                    )
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Outfit Picker Sheet
struct OutfitPickerSheet: View {
    let outfits: [[String: Any]]
    let onSelect: (Int) -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List(Array(outfits.enumerated()), id: \.offset) { _, outfit in
                let outfitId = outfit["id"] as? Int ?? 0
                let name = outfit["name"] as? String ?? "Unnamed"
                let items = outfit["items"] as? [[String: Any]] ?? []

                Button(action: { onSelect(outfitId) }) {
                    HStack(spacing: 12) {
                        if let first = items.first,
                           let urlStr = first["image_url"] as? String,
                           let url = URL(string: urlStr) {
                            AsyncImage(url: url) { img in
                                img.resizable().scaledToFill()
                            } placeholder: { Color(.systemGray5) }
                            .frame(width: 56, height: 56)
                            .clipped()
                            .cornerRadius(8)
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray5))
                                .frame(width: 56, height: 56)
                                .overlay(Image(systemName: "tshirt.fill").foregroundColor(.gray))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(name).font(.subheadline).fontWeight(.semibold)
                            Text("\(items.count) items").font(.caption).foregroundColor(.gray)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(.gray)
                    }
                    .foregroundColor(.primary)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Choose Outfit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
            }
        }
    }
}
