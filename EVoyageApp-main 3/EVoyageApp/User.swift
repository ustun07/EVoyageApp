//
//  User.swift
//  EVoyageApp
//
//  Created by Furkan Erdoğan on 26.05.2024.
//

import Foundation
import FirebaseFirestoreSwift
import FirebaseAuth

struct UserDB: Codable, Identifiable, Equatable, Hashable {
    internal init(
        userNameSurname: String,
        userUid: String,
        userEmail: String,
        profileImage: String? = nil,
        carInfo: Car
    ) {
        self.userNameSurname = userNameSurname
        self.userUid = userUid
        self.userEmail = userEmail
        self.profileImage = profileImage
        self.carInfo = carInfo
    }
    
    let userNameSurname: String
    let userUid: String
    let userEmail: String
    let profileImage: String?
    let carInfo: Car?
    
    var id: String { userUid }
    
    static let mockUser1 = UserDB(userNameSurname: "Ahmet Safa Öztürk", userUid: UUID().uuidString, userEmail: "", profileImage: "", carInfo: .init(brand: "", model: ""))
    
    static let mockUser2 = UserDB(userNameSurname: "Ömer Faruk Öztekin", userUid: UUID().uuidString, userEmail: "", profileImage: "", carInfo: .init(brand: "", model: ""))
}

struct Car: Codable, Equatable, Hashable {
    let brand: String
    let model: String
    
    init(brand: String, model: String) {
        self.brand = brand
        self.model = model
    }
    
    init(car: Car) {
        self.brand = car.brand
        self.model = car.model
    }
}
