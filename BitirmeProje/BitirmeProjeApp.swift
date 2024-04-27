//
//  BitirmeProjeApp.swift
//  BitirmeProje
//
//  Created by Selim Can Üstün on 21.04.2024.
//
import SwiftUI
import Firebase
import GoogleSignIn

extension BitirmeProjeApp {
  private func setupAuthentication() {
    FirebaseApp.configure()
  }
}

@main
struct BitirmeProjeApp: App {
    @State private var locationManager = LocationManager()
    var body: some Scene {
        WindowGroup {
            if locationManager.isAuthorized {
                StartTab()
            } else {
                LocationDeniedView()
            }
        }
        .modelContainer(for: Destination.self)
        .environment(locationManager)
    }
}



