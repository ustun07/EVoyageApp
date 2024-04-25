//
//  TabView.swift
//  BitirmeProje
//
//  Created by Selim Can Üstün on 25.04.2024.
//

import SwiftUI

struct StartTab: View {

    var body: some View {
        TabView {
            Group {
                TripMapView()
                    .tabItem {
                        Label("Yolculuk Haritası", systemImage: "map")
                    }
                DestinationsListView()
                    .tabItem {
                        Label("Kayıtlı Rotalar", systemImage: "globe.desk")
                    }
                ExploreView() // Keşfet bölümü
                    .tabItem {
                        Label("Keşfet", systemImage: "magnifyingglass")
                    }
                ProfileView() // Profil bölümü
                    .tabItem {
                        Label("Profil", systemImage: "person.circle")
                    }
            }
            .toolbarBackground(.appBlue.opacity(0.8), for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarColorScheme(.dark, for: .tabBar)
        }
    }
}

struct ExploreView: View {
    var body: some View {
        Text("Keşfet Bölümü")
    }
}

struct ProfileView: View {
    @State private var username = "John Doe"
    @State private var vehicleBrandModel = "Tesla Model S"
    @State private var editMode = false

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Image(systemName: "person.circle.fill") // Kullanıcı resmi
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            Text("Adı Soyadı: \(username)") // Kullanıcı adı soyadı
            Text("Araç Marka Modeli: \(vehicleBrandModel)") // Araç marka modeli

            if editMode {
                Button("Bilgileri Kaydet") {
                    // Bilgileri kaydetme işlemi
                    editMode.toggle() // Düzenleme modunu kapat
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            } else {
                Button("Bilgileri Düzenle") {
                    editMode.toggle() // Düzenleme modunu aç
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .navigationBarTitle("Profil")
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}

struct StartTab_Previews: PreviewProvider {
    static var previews: some View {
        StartTab()
            .modelContainer(Destination.preview)
            .environment(LocationManager())
    }
}
