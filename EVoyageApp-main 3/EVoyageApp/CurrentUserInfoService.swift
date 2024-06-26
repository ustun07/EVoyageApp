
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

extension CurrentUserInfoService {
    enum Failure: Error {
        case authUserNotFound
        case userNotFoundInDB
    }
}

@MainActor
final class CurrentUserInfoService: ObservableObject {
    static let shared = CurrentUserInfoService()
    
    @Published var user: UserDB?
    @Published var isAnonymousUser: Bool = true {
        didSet {
            if isAnonymousUser {
                invalidate()
            }
        }
    }
    var preloadNeeded: Bool = true
    private let userCollection = Firestore.firestore().collection("Users")
    private let travelCollection = Firestore.firestore().collection("Travels")
    
    init() {
        Auth.auth().addStateDidChangeListener { _, user in
            self.isAnonymousUser = user?.isAnonymous ?? true
        }
    }
    
    func refreshAllUserInfo() async {
        do {
            _ = try await getCurrentUser(forceUpdate: true)
            preloadNeeded = false
        } catch {
            print("Errors from \(#function) - ", error.localizedDescription)
        }
    }
    
    func getCurrentUser(forceUpdate: Bool = false) async throws -> UserDB {
        if !forceUpdate, let user {
            return user
        }
        guard let userUID = Auth.auth().currentUser?.uid else {
            throw Failure.authUserNotFound
        }
        let user = try? await userCollection
            .document(userUID)
            .getDocument()
            .data(as: UserDB.self)
        guard let user else {
            throw Failure.userNotFoundInDB
        }
        self.user = user
        return user
    }
    
    func invalidate() {
        user = nil
    }
    
    func setCarInfo(car: Car) async throws {
        let currentUser = try await getCurrentUser()
        try await userCollection.document(currentUser.userUid)
            .updateData(
                ["carInfo.brand" : car.brand,
                 "carInfo.model" : car.model,]
            )
        
        await refreshAllUserInfo()
    }
    
    func createNewTravel(with travel: TravelDBModel) async throws {
        do {
            try await travelCollection.addDocument(from: travel)
            await refreshAllUserInfo()
        } catch {
            print("WorldView - Error - ", error.localizedDescription)
        }
    }
}
