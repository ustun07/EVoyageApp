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
  @StateObject var viewModel = AuthenticationViewModel()

  init() {
      print("Furkan")
    setupAuthentication()
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(viewModel)
    }
  }
}


