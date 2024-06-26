//
//  MainTabView.swift
//  EVoyageApp
//
//  Created by Furkan Erdoğan on 26.05.2024.
//

import SwiftUI

class EnvironmentSettings: ObservableObject {
    @Published var showTab = true
}

extension MainTabView {
    enum FullScreenItem: String, Identifiable {
        var id: String { rawValue }
        case car
        case addTrip
    }
}

struct MainTabView: View {
    
    @State var selectedTab: TabItem = .map
    @State var fullScreenItem: MainTabView.FullScreenItem?
    @State var sheetItem: MainTabView.SheetItem? = nil
    @StateObject var environmentSettings = EnvironmentSettings()
    @StateObject var currentUserService: CurrentUserInfoService = .shared
    @ObservedObject var userManagementService: UserManagementService = .shared
    
    init() {
        UITabBar.appearance().isHidden = false
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                TripMapView()
                    .tag(TabItem.map)
                    .environmentObject(environmentSettings)
                
                ExploreView()
                    .tag(TabItem.tab2)
                    .environmentObject(environmentSettings)
                
                ChatsView()
                    .tag(TabItem.tab3)
                    .environmentObject(environmentSettings)
                
                Button(action: {
                    Task {
                        do {
                            try userManagementService.signOut()
                        } catch {
                            print("Hata var")
                        }
                    }
                }, label: {
                    Text("Log Out")
                })
                    .tag(TabItem.tab4)
                    .environmentObject(environmentSettings)
                
            }
            .onAppear(perform: {
                Task {
                    guard let user = try? await CurrentUserInfoService.shared.getCurrentUser() else { return }
                    if user.carInfo?.brand == nil ||  user.carInfo?.brand == "" {
                        fullScreenItem = .car
                    }
                }
            })
            
            if environmentSettings.showTab {
                TabBarView(
                    selectedTabItem: $selectedTab
                ) {
                    guard let _ = currentUserService.user else {
                        sheetItem = .anonymousAuthenticationView
                        return
                    }
                    
                    fullScreenItem = .addTrip
                }
            }
        }
        .fullScreenCover(item: $fullScreenItem) { item in
            switch item {
            case .car:
                NavigationStack {
                    CarSelectionView()
                }
            case .addTrip:
                TravelDateSelectionView()
            }
        }
    }
}

extension MainTabView {
    func customTabItem(
        _ item: TabItem,
        isActive: Bool
    ) -> some View {
        VStack {
            Image(systemName: item.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
            Text(item.title)
                .font(.caption)
        }
        .foregroundStyle(isActive ? Color.green : Color.red)
    }
}

#Preview {
    MainTabView()
}

enum TabItem: Int, CaseIterable {
    case map = 0
    case tab2 = 1
    case tab3 = 2
    case tab4 = 3
    
    var title: String{
        switch self {
        case .map:
            return String(localized: "Travels")
        case .tab2:
            return String(localized: "Explore")
        case .tab3:
            return String(localized: "Message")
        case .tab4:
            return String(localized: "Profile")
        }
    }
    
    var iconName: String{
        switch self {
        case .map:
            return "mappin.and.ellipse"
        case .tab2:
            return "globe"
        case .tab3:
            return "message"
        case .tab4:
            return "person.crop.circle"
        }
    }
}

extension MainTabView {
    
    enum SheetItem: String, Identifiable {
        var id: String { rawValue }
        
        case anonymousAuthenticationView
    }
}

struct TabBarView: View {
    @Binding var selectedTabItem: TabItem
    let addTravelTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            Button {
                selectedTabItem = .map
            } label: {
                TabItemView(
                    item: .map,
                    isActive: selectedTabItem == .map
                )
            }
            
            Button {
                selectedTabItem = .tab2
            } label: {
                TabItemView(
                    item: .tab2,
                    isActive: selectedTabItem == .tab2
                )
            }
            
            Button {
                addTravelTapped()
            } label: {
                Color.green
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                    .overlay {
                        Image(systemName: "plus")
                            .font(.title)
                            .foregroundStyle(.black)
                    }
            }
            
            Button {
                selectedTabItem = .tab3
            } label: {
                TabItemView(
                    item: .tab3,
                    isActive: selectedTabItem == .tab3
                )
            }
            
            Button {
                selectedTabItem = .tab4
            } label: {
                TabItemView(
                    item: .tab4,
                    isActive: selectedTabItem == .tab4
                )
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 40))
        .padding(.vertical)
    }
}

struct TabItemView: View {
    let item: TabItem
    let isActive: Bool
    
    var body: some View {
        VStack {
            Image(systemName: item.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
            Text(item.title)
                .font(
                    .system(
                        size: 10,
                        weight: .regular,
                        design: .rounded
                    )
                )
        }
        .frame(width: 45)
        .foregroundStyle(isActive ? Color.green : Color.gray)
    }
}
