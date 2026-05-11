import SwiftUI

// MARK: - Social Feed View
struct SocialFeedView: View {
    @State private var posts: [[String: Any]] = []
    @State private var isLoading = false
    @State private var showingSearch = false

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView()
                } else if posts.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "person.2")
                            .font(.system(size: 80))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("Your feed is empty")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Follow other users to see their outfits here")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Button(action: { showingSearch = true }) {
                            Text("Find People to Follow")
                                .fontWeight(.semibold)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.black)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(Array(posts.enumerated()), id: \.offset) { _, post in
                                FeedPostCard(post: post, onLikeToggled: loadFeed)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSearch = true }) {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(.black)
                    }
                }
            }
            .onAppear { loadFeed() }
            .sheet(isPresented: $showingSearch) {
                UserSearchView()
            }
        }
    }

    private func loadFeed() {
        isLoading = true
        NetworkManager.shared.getFeed { result in
            isLoading = false
            if case .success(let data) = result {
                posts = data
            }
        }
    }
}

// MARK: - Feed Post Card
struct FeedPostCard: View {
    let post: [String: Any]
    let onLikeToggled: () -> Void
    @State private var showingComments = false
    @State private var isLiked: Bool
    @State private var likeCount: Int
    @State private var isDisliked: Bool
    @State private var dislikeCount: Int

    init(post: [String: Any], onLikeToggled: @escaping () -> Void) {
        self.post = post
        self.onLikeToggled = onLikeToggled
        _isLiked = State(initialValue: post["liked_by_me"] as? Bool ?? false)
        _likeCount = State(initialValue: Int(post["like_count"] as? String ?? "0") ?? 0)
        _isDisliked = State(initialValue: post["disliked_by_me"] as? Bool ?? false)
        _dislikeCount = State(initialValue: Int(post["dislike_count"] as? String ?? "0") ?? 0)
    }

    var postId: Int { post["id"] as? Int ?? 0 }
    var displayName: String { post["display_name"] as? String ?? "Unknown" }
    var caption: String { post["caption"] as? String ?? "" }
    var outfitName: String { post["outfit_name"] as? String ?? "" }
    var commentCount: Int { Int(post["comment_count"] as? String ?? "0") ?? 0 }
    var items: [[String: Any]] { post["items"] as? [[String: Any]] ?? [] }

    var timeAgo: String {
        guard let dateStr = post["created_at"] as? String else { return "" }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateStr) else { return "" }
        let diff = Date().timeIntervalSince(date)
        if diff < 3600 { return "\(Int(diff / 60))m ago" }
        if diff < 86400 { return "\(Int(diff / 3600))h ago" }
        return "\(Int(diff / 86400))d ago"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink(destination: PublicProfileView(
                userId: post["user_id"] as? Int ?? 0,
                displayName: displayName
            )) {
                HStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(String(displayName.prefix(1)).uppercased())
                                .font(.headline)
                                .foregroundColor(.gray)
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text(timeAgo)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text(outfitName)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            .buttonStyle(PlainButtonStyle())

            if !items.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(items.prefix(4).enumerated()), id: \.offset) { _, item in
                            if let imageURL = item["image_url"] as? String,
                               let url = URL(string: imageURL) {
                                AsyncImage(url: url) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Color(.systemGray5)
                                }
                                .frame(width: 100, height: 120)
                                .clipped()
                                .cornerRadius(10)
                            } else {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemGray5))
                                    .frame(width: 100, height: 120)
                                    .overlay(
                                        Image(systemName: "tshirt.fill")
                                            .foregroundColor(.gray)
                                    )
                            }
                        }
                    }
                }
            }

            if !caption.isEmpty {
                Text(caption)
                    .font(.subheadline)
            }

            HStack(spacing: 20) {
                Button(action: toggleLike) {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .black)
                        Text("\(likeCount)")
                            .foregroundColor(.black)
                    }
                }

                Button(action: toggleDislike) {
                    HStack(spacing: 4) {
                        Image(systemName: isDisliked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                            .foregroundColor(isDisliked ? .blue : .black)
                        Text("\(dislikeCount)")
                            .foregroundColor(.black)
                    }
                }

                Button(action: { showingComments = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right")
                        Text("\(commentCount)")
                    }
                    .foregroundColor(.black)
                }

                Spacer()
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .sheet(isPresented: $showingComments) {
            CommentsView(postId: postId)
        }
    }

    private func toggleLike() {
        isLiked.toggle()
        likeCount += isLiked ? 1 : -1
        NetworkManager.shared.toggleLike(postId: postId) { _ in
            onLikeToggled()
        }
    }
    private func toggleDislike() {
        if isLiked {
            isLiked = false
            likeCount -= 1
        }
        isDisliked.toggle()
        dislikeCount += isDisliked ? 1 : -1
        NetworkManager.shared.toggleDislike(postId: postId) { _ in
            onLikeToggled()
        }
    }
}

// MARK: - Comments View
struct CommentsView: View {
    let postId: Int
    @State private var comments: [[String: Any]] = []
    @State private var newComment = ""
    @State private var isLoading = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView()
                        .padding()
                } else if comments.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "bubble.right")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No comments yet")
                            .foregroundColor(.gray)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            ForEach(Array(comments.enumerated()), id: \.offset) { _, comment in
                                HStack(alignment: .top, spacing: 12) {
                                    Circle()
                                        .fill(Color(.systemGray5))
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Text(String((comment["display_name"] as? String ?? "?").prefix(1)).uppercased())
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        )
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(comment["display_name"] as? String ?? "")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Text(comment["content"] as? String ?? "")
                                            .font(.subheadline)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }

                Divider()
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
                .padding()
                            }
                            .navigationTitle("Comments")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button("Done") { presentationMode.wrappedValue.dismiss() }
                                }
                            }
                            .onAppear { loadComments() }
                        }
                    }

                    private func loadComments() {
                        isLoading = true
                        NetworkManager.shared.getComments(postId: postId) { result in
                            isLoading = false
                            if case .success(let data) = result {
                                comments = data
                            }
                        }
                    }

                    private func submitComment() {
                        guard !newComment.isEmpty else { return }
                        let content = newComment
                        newComment = ""
                        NetworkManager.shared.postComment(postId: postId, content: content) { result in
                            if case .success(let comment) = result {
                                comments.append(comment)
                            }
                        }
                    }
                }

// MARK: - User Search View
struct UserSearchView: View {
    @State private var searchQuery = ""
    @State private var users: [[String: Any]] = []
    @State private var isSearching = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search by username...", text: $searchQuery)
                        .autocapitalization(.none)
                        .onChange(of: searchQuery) {
                            loadAllUsers()
                        }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()

                if isSearching {
                    ProgressView()
                } else if users.isEmpty {
                    Text("No users found")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(Array(users.enumerated()), id: \.offset) { _, user in
                        UserRow(user: user)
                    }
                    .listStyle(.plain)
                }

                Spacer()
            }
            .navigationTitle("Find People")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { presentationMode.wrappedValue.dismiss() }
                }
            }
            .onAppear { loadAllUsers() }
        }
    }

    private func loadAllUsers() {
        isSearching = true
        NetworkManager.shared.searchUsers(query: searchQuery) { result in
            isSearching = false
            if case .success(let data) = result {
                users = data
            }
        }
    }
}

                // MARK: - User Row
                struct UserRow: View {
                    let user: [String: Any]
                    @State private var isFollowing: Bool

                    init(user: [String: Any]) {
                        self.user = user
                        _isFollowing = State(initialValue: user["is_following"] as? Bool ?? false)
                    }

                    var userId: Int { user["id"] as? Int ?? 0 }
                    var displayName: String { user["display_name"] as? String ?? "" }
                    var followerCount: Int { user["follower_count"] as? Int ?? 0 }

                    var body: some View {
                        HStack {
                            Circle()
                                .fill(Color(.systemGray5))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Text(String(displayName.prefix(1)).uppercased())
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(displayName)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text("\(followerCount) followers")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Button(action: toggleFollow) {
                                Text(isFollowing ? "Following" : "Follow")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 6)
                                    .background(isFollowing ? Color(.systemGray5) : Color.black)
                                    .foregroundColor(isFollowing ? .black : .white)
                                    .cornerRadius(20)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    private func toggleFollow() {
                        isFollowing.toggle()
                        NetworkManager.shared.toggleFollow(userId: userId) { _ in }
                    }
                }
