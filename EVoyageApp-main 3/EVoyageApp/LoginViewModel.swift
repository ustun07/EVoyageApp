//
//  LoginViewModel.swift
//  EVoyageApp
//
//  Created by Furkan Erdoğan on 26.05.2024.
//

import SwiftUI
import GoogleSignIn
import AuthenticationServices
import FirebaseAuth

@MainActor class LoginViewModel: ObservableObject {
    @ObservedObject var userManagementService: UserManagementService = .shared
    @Published var path: [RegisterNavigationItem] = []
    @Published var isLoading = false
    private let currentUserService: CurrentUserInfoService = .shared

    func googleSignIn() async {
        setLoading(to: true)
        do {
            let (firebaseUser, googleUser) = try await userManagementService.signInWithGoogle()
            let credentials = AuthRegisterCredentials(
                userNameSurname:  googleUser.profile?.name ?? "user\(UUID().uuidString.prefix(6))",
                userEmail: firebaseUser.email ?? "",
                carInfo: .init(brand: "", model: ""),
                userUid: firebaseUser.uid,
                profileImage: unknowImageURL
            )
            do {
                _ = try await currentUserService.getCurrentUser()
            } catch {
                print("Hello2 - \(error.localizedDescription)")
                if let error = error as? CurrentUserInfoService.Failure, error == .userNotFoundInDB {
                    await registerUser(with: credentials)
                    print("User Registered")
                    _ = await currentUserService.refreshAllUserInfo()
                    print("Refreshed All Info")
                }
            }
        } catch {
            setLoading(to: false)
            print(error.localizedDescription)
        }
    }
    
    private func registerUser(with credentials: AuthRegisterCredentials) async {
        do {
            try await AuthService.shared.registerUser(withCredential: credentials)
            setLoading(to: false)
            path.append(.carSelection)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    @MainActor private func setLoading(to value: Bool) {
        isLoading = value
    }
}

import FirebaseCore
import SwiftUI
import FirebaseAuth
import Combine

@MainActor final class UserManagementService: ObservableObject {
    public static let shared = UserManagementService()
    
    private let authService: AuthenticationService
    private let googleSignInService: GoogleSignInService
    init(
        authService: AuthenticationService = FirebaseAuthService.shared,
        googleSignInService: GoogleSignInService = GoogleSignInService.shared
    ) {
        self.authService = authService
        self.googleSignInService = googleSignInService
    }
    
    @Published public var user: User?
    @Published public var isUserSignedIn = false
    
//    private var cancellable: AnyCancellable?
    
    public func configure() {
        FirebaseApp.configure()
        self.user = Auth.auth().currentUser
        isUserSignedIn = user != nil
        
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            self?.isUserSignedIn = user != nil
        }
    }
    
    func signInWithGoogle() async throws -> GoogleSignInResult {
        return try await googleSignInService.signInWithGoogle()
    }
    
    func signOut() throws {
        try authService.signOut()
    }
}

import UIKit
import Firebase
import FirebaseStorage

struct AuthRegisterCredentials: Codable {
    let userNameSurname: String
    let userEmail: String
    let carInfo: Car
    let registrationTime: Date
    let userUid: String
    let profileImage: String
    
    init(userNameSurname: String, userEmail: String, carInfo: Car, userUid: String, profileImage: String) {
        self.userNameSurname = userNameSurname
        self.userEmail = userEmail
        self.registrationTime = Date()
        self.userUid = userUid
        self.profileImage = profileImage
        self.carInfo = carInfo
    }
}

let unknowImageURL = "https://firebasestorage.googleapis.com:443/v0/b/travelappnew-c6e92.appspot.com/o/Profile_Images%2FF29749B7-1203-4E58-BBB6-00433E09B15A?alt=media&token=a329d8b4-8377-4de4-a341-6d82d9780895"


struct AuthService {
    static let shared = AuthService()
    private let userCollection = Firestore.firestore().collection("Users")
    
    func registerUser(withCredential credentials: AuthRegisterCredentials) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {return} //TODO: - ?
        do {
            try userCollection.document(uid).setData(from: credentials)
        } catch {
            print("Furkan: \(error.localizedDescription)")
        }
    }
}

typealias GoogleSignInResult = (User, GIDGoogleUser)

@MainActor final class GoogleSignInService: ObservableObject {
    static let shared = GoogleSignInService()
    
    private let authService: AuthenticationService
    init(
        authService: AuthenticationService = FirebaseAuthService.shared
    ) {
        self.authService = authService
    }
    
    func signInWithGoogle() async throws -> GoogleSignInResult {
        guard let clientID = FirebaseApp.app()?.options.clientID else { throw GoogleSignInError.unableToGetClientID }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let presentingViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else { throw GoogleSignInError.unableToGetPresentingVeewController }
        
        let authResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
        let googleUser = authResult.user
        guard let idToken = googleUser.idToken?.tokenString else { throw GoogleSignInError.unableToGetIDToken }
        
        let user = try await authService.signInWithGoogle(withIDToken: idToken, accessTokenString: googleUser.accessToken.tokenString)
        return (user, googleUser)
    }
    
    func signOut() throws {
        try authService.signOut()
    }
}

enum GoogleSignInError: Error {
    case unableToGetClientID
    case unableToGetPresentingVeewController
    case unableToGetIDToken
}

import Foundation
import AuthenticationServices
import FirebaseAuth
import FirebaseCore

protocol AuthenticationService {
    func signInWithGoogle(withIDToken idTokenString: String, accessTokenString: String ) async throws -> User
    func signOut() throws
}

final class FirebaseAuthService: AuthenticationService {
    public static let shared = FirebaseAuthService()
    private init() {}
    
     func signInWithGoogle(withIDToken idTokenString: String, accessTokenString: String ) async throws -> User {
        let credential = GoogleAuthProvider.credential(withIDToken: idTokenString,
                                                       accessToken: accessTokenString)
        
        let authResult = try await Auth.auth().signIn(with: credential)
        return authResult.user
    }
    
    public func signOut() throws {
        try Auth.auth().signOut()
    }
}

public enum AuthenticationError: Error {
    case userNotAuthenticated
}


