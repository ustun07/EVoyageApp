//
//  AddTravelViewModel.swift
//  EVoyageApp
//
//  Created by Furkan Erdoğan on 15.06.2024.
//

import SwiftUI
import FirebaseAuth
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

final class AddTravelViewModel: ObservableObject {
    
    private let db = Firestore.firestore()
//    @Published var travels: [TravelDBModel] = []
//    @Published var viewState: ViewState = .loading
    @Published var path = [AddTripItem]()
    private let travelCollection = Firestore.firestore().collection("travel")
    
    func onAppear() async {
//        await fetchTravels()
    }
    
    @MainActor
    func addFlight(departureProvince: Province, arrivalProvince: Province, date: Date) async throws {
        guard let user = try? await CurrentUserInfoService.shared.getCurrentUser() else {
            // no user // logout
            return
        }
        
        let userInfo = TravelDBModel.UserInfo(uid: user.userUid, nameSurname: user.userNameSurname, profileImageURL: user.profileImage)
        
        let travelModel = TravelDBModel(id: UUID().uuidString, publishedDate: date, departure: departureProvince, arrival: arrivalProvince, departureDate: date, user: userInfo)
        do {
            try await CurrentUserInfoService.shared.createNewTravel(with: travelModel)
        } catch {
            print("Error")
        }
    }
}

import Foundation

struct TravelDBModel: Codable, Equatable, Hashable {
    init(
        id: String,
        publishedDate: Date,
        departure: Province,
        arrival: Province,
        departureDate: Date,
        user: TravelDBModel.UserInfo
    ) {
        self.id = id
        self.publishedDate = publishedDate
        self.departure = departure
        self.arrival = arrival
        self.departureDate = departureDate
        self.user = user
    }
    
    let id: String
    let publishedDate: Date
    let departure: Province
    let arrival: Province
    let departureDate: Date
    let user: UserInfo
    
    struct UserInfo: Codable, Equatable, Hashable {
        let uid: String
        let nameSurname: String
        let profileImageURL: String?
        
        init(uid: String, nameSurname: String, profileImageURL: String?) {
            self.uid = uid
            self.nameSurname = nameSurname
            self.profileImageURL = profileImageURL
        }
        
        init(user: UserDB) {
            self.uid = user.userUid
            self.nameSurname = user.userNameSurname
            self.profileImageURL = user.profileImage
        }
    }
}


import Foundation

// Firebasedeki Model
// Travel Firestore Model
struct TravelFSModel: Codable, Equatable, Hashable {
    internal init(
        publishedDate: Date,
        travelID: String,
        userUID: String,
        userNameSurname: String,
        userProfileUrl: String?,
        departureInfo: Province,
        arrivalInfo: Province,
        departureDate: Date
    ) {
        self.publishedDate = publishedDate
        self.travelID = travelID
        self.userUID = userUID
        self.userNameSurname = userNameSurname
        self.userProfileUrl = userProfileUrl
        self.departureInfo = nil
        self.arrivalInfo = nil
        self.departureDate = departureDate
    }
    
    let publishedDate: Date
    let travelID: String
    let userUID: String
    let userNameSurname: String
    let userProfileUrl: String?
    let departureInfo: Province?
    let arrivalInfo: Province?
    let departureDate: Date
}
