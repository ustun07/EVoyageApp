//
//  EVoyageAppApp.swift
//  EVoyageApp
//
//  Created by Furkan Erdoğan on 26.05.2024.
//

import SwiftUI
import FirebaseCore
import SwiftData


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UserManagementService.shared.configure()
        
        Task {
            try? await CurrentUserInfoService.shared.getCurrentUser()
        }
        
        return true
    }
}

@main
struct EVoyageAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @SwiftUI.State private var locationManager = LocationManager()
    @StateObject var userManagementService = UserManagementService.shared
    @StateObject var currentUserService: CurrentUserInfoService = .shared
    
    enum State {
        case login
        case loading
        case main
    }
    
    var state: State {
        if userManagementService.isUserSignedIn {
            if userManagementService.user?.isAnonymous ?? true {
                return .main
            } else {
                return .main
            }
        } else {
            return .login
        }
    }
    var body: some Scene {
        WindowGroup {
            switch state {
            case .login:
                LoginView()
            case .loading:
                LoadingView()
                    .task {
                        await currentUserService.refreshAllUserInfo()
                    }
            case .main:
                if locationManager.isAuthorized {
                    MainTabView()
                } else {
                    LocationDeniedView()
                }
                
            }
        }
        .modelContainer(for: Destination.self)
        .environment(locationManager)
    }
}

struct LoadingView: View {
    var body: some View {
        Color.black
            .opacity(0.4)
            .overlay {
                ProgressView()
            }
            .ignoresSafeArea()
    }
}

#Preview {
    LoadingView()
}

import SwiftUI

struct LocationDeniedView: View {
    var body: some View {
        ContentUnavailableView(label: {
            Label("Location Services", image: "launchScreen")
        },
                               description: {
            Text("""
1. Tab the button below and go to "Privacy and Security"
2. Tap on "Location Services"
3. Locate the "MyTrips" app and tap on it
4. Change the setting to "While Using the App"
""")
            .multilineTextAlignment(.leading)
        },
                               actions: {
            Button(action: {
                UIApplication.shared.open(
                    URL(string: UIApplication.openSettingsURLString)!,
                    options: [:],
                    completionHandler: nil
                )
            }) {
                Text("Open Settings")
            }
            .buttonStyle(.borderedProminent)
        })
    }
}

#Preview {
    LocationDeniedView()
}
