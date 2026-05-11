import SwiftUI

// MARK: - Public Profile View
struct PublicProfileView: View {
    let userId: Int
    let displayName: String
    @State private var profile: [String: Any] = [:]
    @State private var items: [[String: Any]] = []
    @State private var isLoading = false
    @State private var isFollowing = false

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text(String(displayName.prefix(1)).uppercased())
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                        )

                    Text(displayName)
                        .font(.title2)
                        .fontWeight(.bold)

                    if let bio = profile["bio"] as? String, !bio.isEmpty {
                        Text(bio)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }

                    HStack(spacing: 32) {
                        VStack(spacing: 4) {
                            Text("\(Int(profile["item_count"] as? String ?? "0") ?? 0)")
                                .font(.title3).fontWeight(.bold)
                            Text("Items")
                                .font(.caption).foregroundColor(.gray)
                        }
                        VStack(spacing: 4) {
                            Text("\(Int(profile["outfit_count"] as? String ?? "0") ?? 0)")
                                .font(.title3).fontWeight(.bold)
                            Text("Outfits")
                                .font(.caption).foregroundColor(.gray)
                        }
                        VStack(spacing: 4) {
                            Text("\(Int(profile["follower_count"] as? String ?? "0") ?? 0)")
                                .font(.title3).fontWeight(.bold)
                            Text("Followers")
                                .font(.caption).foregroundColor(.gray)
                        }
                    }
                    .padding(.top, 4)
                    
                    Button(action: toggleFollow) {
                        Text(isFollowing ? "Following" : "Follow")
                            .fontWeight(.semibold)
                            .frame(width: 160)
                            .padding(.vertical, 10)
                            .background(isFollowing ? Color(.systemGray5) : Color.black)
                            .foregroundColor(isFollowing ? .black : .white)
                            .cornerRadius(20)
                    }
                }
                .padding()

                Divider()

                if isLoading {
                    ProgressView()
                        .padding(.top, 40)
                } else if items.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tshirt")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No public items yet")
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 40)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                            NavigationLink(destination: PublicItemView(item: item)) {
                                PublicItemCard(item: item)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .navigationTitle(displayName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadProfile() }
    }

    private func loadProfile() {
        isLoading = true
        NetworkManager.shared.getUserProfile(userId: userId) { result in
            if case .success(let data) = result {
                profile = data
                isFollowing = data["is_following"] as? Bool ?? false
            }
        }
        NetworkManager.shared.getUserWardrobe(userId: userId) { result in
            isLoading = false
            if case .success(let data) = result {
                items = data
            }
        }
    }

    private func toggleFollow() {
        isFollowing.toggle()
        NetworkManager.shared.toggleFollow(userId: userId) { _ in }
    }
}

// MARK: - Public Item Card
struct PublicItemCard: View {
    let item: [String: Any]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Color.clear
                .aspectRatio(1/1.3, contentMode: .fit)
                .overlay(
                    Group {
                        if let imageURL = item["image_url"] as? String,
                           let url = URL(string: imageURL) {
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Color(.systemGray5).overlay(ProgressView())
                            }
                        } else {
                            Color(.systemGray5)
                                .overlay(
                                    Image(systemName: "tshirt.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.gray)
                                )
                        }
                    }
                )
                .clipped()
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                Text(item["name"] as? String ?? "")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 10))
                        Text("\(item["like_count"] as? Int ?? Int(item["like_count"] as? String ?? "0") ?? 0)")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                    HStack(spacing: 3) {
                        Image(systemName: "hand.thumbsdown.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 10))
                        Text("\(item["dislike_count"] as? Int ?? Int(item["dislike_count"] as? String ?? "0") ?? 0)")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
            }
        }
    }
}
// MARK: - Public Item Detail View
struct PublicItemView: View {
    let item: [String: Any]
    @State private var isLiked: Bool
    @State private var isDisliked: Bool
    @State private var likeCount: Int
    @State private var dislikeCount: Int
    @State private var comments: [[String: Any]] = []
    @State private var newComment = ""
    @State private var isLoadingComments = false

    var itemId: Int { item["id"] as? Int ?? 0 }

    init(item: [String: Any]) {
        self.item = item
        _isLiked = State(initialValue: item["liked_by_me"] as? Bool ?? false)
        _isDisliked = State(initialValue: item["disliked_by_me"] as? Bool ?? false)
        _likeCount = State(initialValue: item["like_count"] as? Int ?? Int(item["like_count"] as? String ?? "0") ?? 0)
        _dislikeCount = State(initialValue: item["dislike_count"] as? Int ?? Int(item["dislike_count"] as? String ?? "0") ?? 0)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ZStack {
                    Color(.systemGray5)
                    if let imageURL = item["image_url"] as? String,
                       let url = URL(string: imageURL) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                    } else {
                        Image(systemName: "tshirt.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                    }
                }
                .frame(width: UIScreen.main.bounds.width, height: 350)
                .clipped()

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item["name"] as? String ?? "")
                            .font(.title2)
                            .fontWeight(.bold)

                        if let brand = item["brand"] as? String, !brand.isEmpty {
                            Text(brand)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }

                        HStack(spacing: 8) {
                            if let category = item["category"] as? String {
                                Text(category.capitalized)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                            if let season = item["season"] as? String {
                                Text(season.capitalized)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                        }
                    }

                    Divider()

                    HStack(spacing: 24) {
                        Button(action: toggleLike) {
                            HStack(spacing: 6) {
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .foregroundColor(isLiked ? .red : .black)
                                Text("\(likeCount)")
                                    .foregroundColor(.black)
                            }
                            .font(.headline)
                        }
                        Button(action: toggleDislike) {
                            HStack(spacing: 6) {
                                Image(systemName: isDisliked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                                    .foregroundColor(isDisliked ? .blue : .black)
                                Text("\(dislikeCount)")
                                    .foregroundColor(.black)
                            }
                            .font(.headline)
                        }
                        Spacer()
                    }

                    Divider()

                    Text("Comments")
                        .font(.headline)

                    if isLoadingComments {
                        ProgressView()
                    } else if comments.isEmpty {
                        Text("No comments yet — be the first!")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    } else {
                        ForEach(Array(comments.enumerated()), id: \.offset) { _, comment in
                            HStack(alignment: .top, spacing: 12) {
                                Circle()
                                    .fill(Color(.systemGray5))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Text(String((comment["display_name"] as? String ?? "?").prefix(1)).uppercased())
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    )
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(comment["display_name"] as? String ?? "")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                    Text(comment["content"] as? String ?? "")
                                        .font(.subheadline)
                                }
                            }
                        }
                    }

                    HStack(spacing: 12) {
                        TextField("Add a comment...", text: $newComment)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(20)
                        Button(action: submitComment) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(newComment.isEmpty ? .gray : .black)
                        }
                        .disabled(newComment.isEmpty)
                    }
                }
                .padding()
            }
            .frame(width: UIScreen.main.bounds.width)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadComments() }
    }
    private func toggleLike() {
        if isDisliked { isDisliked = false; dislikeCount -= 1 }
        isLiked.toggle()
        likeCount += isLiked ? 1 : -1
        NetworkManager.shared.toggleItemLike(itemId: itemId) { _ in }
    }

    private func toggleDislike() {
        if isLiked { isLiked = false; likeCount -= 1 }
        isDisliked.toggle()
        dislikeCount += isDisliked ? 1 : -1
        NetworkManager.shared.toggleItemDislike(itemId: itemId) { _ in }
    }

    private func loadComments() {
        isLoadingComments = true
        NetworkManager.shared.getItemComments(itemId: itemId) { result in
            isLoadingComments = false
            if case .success(let data) = result {
                comments = data
            }
        }
    }

    private func submitComment() {
        guard !newComment.isEmpty else { return }
        let content = newComment
        newComment = ""
        NetworkManager.shared.postItemComment(itemId: itemId, content: content) { result in
            if case .success(let comment) = result {
                comments.append(comment)
            }
        }
    }
}
