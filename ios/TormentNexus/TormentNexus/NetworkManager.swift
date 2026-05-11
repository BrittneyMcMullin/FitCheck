
import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = "https://wildland-clutter-blog.ngrok-free.dev/api"
    
    var token: String? {
        get { UserDefaults.standard.string(forKey: "auth_token") }
        set { UserDefaults.standard.set(newValue, forKey: "auth_token") }
    }
    
    var isLoggedIn: Bool {
        return token != nil
    }
    
    // MARK: - Auth
    
    func register(email: String, password: String, displayName: String, completion: @escaping (Result<String, Error>) -> Void) {
        let body: [String: Any] = ["email": email, "password": password, "display_name": displayName]
        request(endpoint: "/auth/register", method: "POST", body: body) { result in
            switch result {
            case .success(let data):
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let token = json["token"] as? String {
                    UserDefaults.standard.set(json["email"] as? String ?? "", forKey: "user_email")
                    completion(.success(token))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func login(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        let body: [String: Any] = ["email": email, "password": password]
        request(endpoint: "/auth/login", method: "POST", body: body) { result in
            switch result {
            case .success(let data):
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let token = json["token"] as? String {
                    if let user = json["user"] as? [String: Any],
                       let name = user["display_name"] as? String {
                        UserDefaults.standard.set(name, forKey: "display_name")
                    }
                    completion(.success(token))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid credentials"])))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: "auth_token")
    }
    
    // MARK: - Items
    
    func getItems(completion: @escaping (Result<[ClothingItem], Error>) -> Void) {
        request(endpoint: "/items", method: "GET", body: nil) { result in
            switch result {
            case .success(let data):
                if let rawString = String(data: data, encoding: .utf8) {
                    print("Raw items response: \(rawString)")
                }
                do {
                    let backendItems = try JSONDecoder().decode([BackendItem].self, from: data)
                    let items = backendItems.map { $0.toClothingItem() }
                    completion(.success(items))
                } catch {
                    print("Decode error: \(error)")
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func addItem(_ item: ClothingItem, completion: @escaping (Result<ClothingItem, Error>) -> Void) {
        let body: [String: Any] = [
            "name": item.name,
            "category": item.category.rawValue.lowercased(),
            "brand": item.brand,
            "colors": item.colors,
            "tags": item.occasions.map { $0.rawValue.lowercased() },
            "season": item.season.rawValue.lowercased(),
            "occasion": item.occasions.first?.rawValue.lowercased() ?? "",
            "image_url": item.imageURL ?? ""
        ]
        
        request(endpoint: "/items", method: "POST", body: body) { result in
            switch result {
            case .success(let data):
                do {
                    let backendItem = try JSONDecoder().decode(BackendItem.self, from: data)
                    var newItem = backendItem.toClothingItem()
                    newItem.imageData = item.imageData
                    completion(.success(newItem))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func deleteItem(id: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        request(endpoint: "/items/\(id)", method: "DELETE", body: nil) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func uploadImage(_ imageData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: baseURL + "/upload") else { return }
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"item.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let data = data else { return }
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let imageUrl = json["imageUrl"] as? String {
                    completion(.success(imageUrl))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Upload failed"])))
                }
            }
        }.resume()
    }
    
    // MARK: - Core request method
    
    private func request(endpoint: String, method: String, body: [String: Any]?, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: baseURL + endpoint) else { return }
        
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        
        URLSession.shared.dataTask(with: req) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let data = data else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                    return
                }
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMsg = json["error"] as? String,
                   errorMsg == "Invalid token" {
                    DispatchQueue.main.async {
                        self.token = nil
                        NotificationCenter.default.post(name: Notification.Name("UserDidLogout"), object: nil)
                    }
                    completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Session expired"])))
                    return
                }
                
                completion(.success(data))
            }
        }.resume()
    }
    
    func saveOutfit(name: String, itemIds: [Int], completion: @escaping (Result<Void, Error>) -> Void) {
        let body: [String: Any] = ["name": name, "item_ids": itemIds]
        request(endpoint: "/outfits", method: "POST", body: body) { result in
            switch result {
            case .success: completion(.success(()))
            case .failure(let error): completion(.failure(error))
            }
        }
    }
    
    func updateOutfit(outfitId: Int, name: String, itemIds: [Int], completion: @escaping (Result<Void, Error>) -> Void) {
        let body: [String: Any] = ["name": name, "item_ids": itemIds]
        request(endpoint: "/outfits/\(outfitId)", method: "PUT", body: body) { result in
            switch result {
            case .success: completion(.success(()))
            case .failure(let error): completion(.failure(error))
            }
        }
    }
    
    func getOutfits(completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        request(endpoint: "/outfits", method: "GET", body: nil) { result in
            switch result {
            case .success(let data):
                if let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    completion(.success(json))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    func getRecommendations(lat: Double, lon: Double, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        request(endpoint: "/recommendations?lat=\(lat)&lon=\(lon)", method: "GET", body: nil) { result in
            switch result {
            case .success(let data):
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    completion(.success(json))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    // MARK: - Social
    
    func getFeed(completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        request(endpoint: "/social/feed", method: "GET", body: nil) { result in
            switch result {
            case .success(let data):
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                        print("✅ Feed loaded:", json.count, "posts")
                        completion(.success(json))
                    } else {
                        print("❌ Feed: unexpected format")
                        completion(.success([]))
                    }
                } catch {
                    print("❌ Feed parse error:", error)
                    completion(.failure(error))
                }
            case .failure(let error):
                print("❌ Feed error:", error)
                completion(.failure(error))
            }
        }
    }
    
    func getAnalytics(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        request(endpoint: "/analytics", method: "GET", body: nil) { result in
            switch result {
            case .success(let data):
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    completion(.success(json))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func toggleLike(postId: Int, completion: @escaping (Result<Bool, Error>) -> Void) {
        request(endpoint: "/social/likes", method: "POST", body: ["post_id": postId]) { result in
            switch result {
            case .success(let data):
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let liked = json["liked"] as? Bool {
                    completion(.success(liked))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func toggleDislike(postId: Int, completion: @escaping (Result<Bool, Error>) -> Void) {
        request(endpoint: "/social/dislikes", method: "POST", body: ["post_id": postId]) { result in
            switch result {
            case .success(let data):
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let disliked = json["disliked"] as? Bool {
                    completion(.success(disliked))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getComments(postId: Int, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        request(endpoint: "/social/comments/\(postId)", method: "GET", body: nil) { result in
            switch result {
            case .success(let data):
                if let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    completion(.success(json))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func postComment(postId: Int, content: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        request(endpoint: "/social/comments", method: "POST", body: ["post_id": postId, "content": content]) { result in
            switch result {
            case .success(let data):
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    completion(.success(json))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func searchUsers(query: String, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        request(endpoint: "/social/users?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)", method: "GET", body: nil) { result in
            switch result {
            case .success(let data):
                if let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    completion(.success(json))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func toggleFollow(userId: Int, completion: @escaping (Result<Bool, Error>) -> Void) {
        request(endpoint: "/social/follows", method: "POST", body: ["user_id": userId]) { result in
            switch result {
            case .success(let data):
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let following = json["following"] as? Bool {
                    completion(.success(following))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func shareOutfit(outfitId: Int, caption: String, completion: @escaping (Result<Void, Error>) -> Void) {
        request(endpoint: "/social/posts", method: "POST", body: ["outfit_id": outfitId, "caption": caption]) { result in
            switch result {
            case .success: completion(.success(()))
            case .failure(let error): completion(.failure(error))
            }
        }
    }
    func getUserProfile(userId: Int, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        request(endpoint: "/social/users/\(userId)/profile", method: "GET", body: nil) { result in
            switch result {
            case .success(let data):
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    completion(.success(json))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getUserWardrobe(userId: Int, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        request(endpoint: "/social/users/\(userId)/wardrobe", method: "GET", body: nil) { result in
            switch result {
            case .success(let data):
                if let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    completion(.success(json))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func toggleItemLike(itemId: Int, completion: @escaping (Result<Bool, Error>) -> Void) {
        request(endpoint: "/social/items/\(itemId)/like", method: "POST", body: nil) { result in
            switch result {
            case .success(let data):
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let liked = json["liked"] as? Bool {
                    completion(.success(liked))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func toggleItemDislike(itemId: Int, completion: @escaping (Result<Bool, Error>) -> Void) {
        request(endpoint: "/social/items/\(itemId)/dislike", method: "POST", body: nil) { result in
            switch result {
            case .success(let data):
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let disliked = json["disliked"] as? Bool {
                    completion(.success(disliked))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getItemComments(itemId: Int, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        request(endpoint: "/social/items/\(itemId)/comments", method: "GET", body: nil) { result in
            switch result {
            case .success(let data):
                if let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    completion(.success(json))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func postItemComment(itemId: Int, content: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        request(endpoint: "/social/items/\(itemId)/comments", method: "POST", body: ["content": content]) { result in
            switch result {
            case .success(let data):
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    completion(.success(json))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getWeekPlan(startDate: String, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        request(endpoint: "/planner/week?start=\(startDate)", method: "GET", body: nil) { result in
            switch result {
            case .success(let data):
                if let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    completion(.success(json))
                } else {
                    completion(.success([]))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func assignOutfitToDay(outfitId: Int, date: String, completion: @escaping (Result<Void, Error>) -> Void) {
        request(endpoint: "/planner", method: "POST", body: ["outfit_id": outfitId, "planned_date": date]) { result in
            switch result {
            case .success: completion(.success(()))
            case .failure(let error): completion(.failure(error))
            }
        }
    }
    
    func markOutfitWorn(plannerId: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        request(endpoint: "/planner/\(plannerId)/worn", method: "POST", body: nil) { result in
            switch result {
            case .success: completion(.success(()))
            case .failure(let error): completion(.failure(error))
            }
        }
    }
    
    func removePlannerEntry(plannerId: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        request(endpoint: "/planner/\(plannerId)", method: "DELETE", body: nil) { result in
            switch result {
            case .success: completion(.success(()))
            case .failure(let error): completion(.failure(error))
            }
        }
    }
    
    func changePassword(email: String, currentPassword: String, newPassword: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let body: [String: Any] = [
            "email": email,
            "current_password": currentPassword,
            "new_password": newPassword
        ]
        request(endpoint: "/auth/change-password", method: "POST", body: body) { result in
            switch result {
            case .success(let data):
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success {
                    completion(.success(()))
                } else if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let error = json["error"] as? String {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: error])))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    func deleteOutfit(outfitId: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        request(endpoint: "/outfits/\(outfitId)", method: "DELETE", body: nil) { result in
            switch result {
            case .success: completion(.success(()))
            case .failure(let error): completion(.failure(error))
            }
        }
    }
    func getProfile(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        request(endpoint: "/auth/profile", method: "GET", body: nil) { result in
            switch result {
            case .success(let data):
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    completion(.success(json))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func updateDisplayName(name: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let body = ["display_name": name]
        request(endpoint: "/auth/profile", method: "PUT", body: body) { result in
            switch result {
            case .success: completion(.success(()))
            case .failure(let error): completion(.failure(error))
            }
        }
    }
    
    func updateProfilePhoto(url: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let body = ["profile_photo_url": url]
        request(endpoint: "/auth/profile", method: "PUT", body: body) { result in
            switch result {
            case .success: completion(.success(()))
            case .failure(let error): completion(.failure(error))
            }
        }
    }
}
