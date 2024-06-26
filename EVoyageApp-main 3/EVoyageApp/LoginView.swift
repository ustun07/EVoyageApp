//
//  LoginView.swift
//  EVoyageApp
//
//  Created by Furkan Erdoğan on 26.05.2024.
//

import SwiftUI

enum RegisterNavigationItem: Hashable {
    case carSelection
}

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State var path: [RegisterNavigationItem] = []
    
    var body: some View {
        NavigationStack(path: $viewModel.path) {
            ZStack {
                Color.blue.ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    VStack(spacing: 24) {
                        Image("car")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 128, height: 150)
                        
                        VStack(spacing: 4) {
                            Text("Welcome to EVoyage")
                                .font(
                                    .system(
                                        size: 24,
                                        weight: .bold,
                                        design: .rounded
                                    )
                                )
                                .foregroundStyle(Color.white)
                            
                            Text("Connect with fellow travelers and streamline your electric vehicle adventures with EVoyage – your go-to platform for sharing journeys and organizing travel plans!")
                                .font(
                                    .system(
                                        size: 16,
                                        weight: .regular,
                                        design: .rounded
                                    )
                                )
                                .foregroundStyle(Color.white)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 32) {
                        VStack(spacing: 24) {
                            GoogleSignInView()
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                                .background(.white)
                                .clipShape(Capsule())
                                .onTapGesture {
                                    Task {
                                        await viewModel.googleSignIn()
                                    }
                                }
                        }
                    }
                }
                .padding()
                
                if viewModel.isLoading {
                    Color.black
                        .opacity(0.4)
                        .overlay {
                            ProgressView()
                        }
                        .ignoresSafeArea()
                }
            }
            .navigationDestination(for: RegisterNavigationItem.self) { item in
                switch item {
                case .carSelection:
                    CarSelectionView()
                }
            }
        }
    }
}

#Preview {
    LoginView()
}

struct GoogleSignInView: View {
    var body: some View {
        HStack {
            Image("googleLogo")
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20, alignment: .center)
            
            Text(String(localized: "Sign in with Google"))
                .font(.system(size: 18, weight: .semibold, design: .default))
                .foregroundColor(Color.black)
        }
    }
}

struct GoogleSignInView_Previews: PreviewProvider {
    static var previews: some View {
        GoogleSignInView()
            .previewLayout(.sizeThatFits)
    }
}

