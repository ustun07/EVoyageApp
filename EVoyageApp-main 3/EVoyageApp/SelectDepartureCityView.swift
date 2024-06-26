//
//  SelectDepartureCityView.swift
//  EVoyageApp
//
//  Created by Furkan Erdoğan on 15.06.2024.
//

import SwiftUI
import Combine

struct SelectDepartureCityView: View {
    @ObservedObject var provinceData = ProvinceData()
    @Binding var path: [AddTripItem]
    @State private var selection: Province?
    @State var buttonText = "Continue"
    @State var isLoading = false
    private let currentUserService: CurrentUserInfoService = .shared
    @Environment(\.dismiss) var dismiss
    let date: Date
    
    var body: some View {
            ZStack {
                Color.blue.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(provinceData.provinces, id: \.province) { province in
                            VStack(alignment: .leading) {
                                ProvinceSelectionRowView(province: province, isSelected: Binding(get: {
                                    province.province.contains(selection?.province ?? "")
                                }, set: { value in
                                    selection = province
                                }))
                            }
                            .padding(.horizontal)
                            .foregroundStyle(Color.white)
                            .padding(.vertical, 2.5)
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    CTAButton(
                        text: $buttonText,
                        isDisabled: .constant(false),
                        height: 50
                    ) {
                        path.append(.arrivalCity(selection ?? Province(id: "", province: "", coordinates: .init(latitude: 2.1, longitude: 2.1))))
                    }
                    .padding()
                }
                
                if isLoading {
                    Color.black
                        .opacity(0.4)
                        .overlay {
                            ProgressView()
                        }
                        .ignoresSafeArea()
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .navigationTitle("Departure City")
        }
}


// MARK: - ProvinceElement
struct ProvinceCoordinate: Codable, Hashable {
    let latitude: Double
    let longitude: Double
}

struct Province: Codable, Identifiable, Equatable, Hashable {
    let id: String?
    let province: String
    let coordinates: ProvinceCoordinate
    
    static func == (lhs: Province, rhs: Province) -> Bool {
        lhs.id == rhs.id
    }
}


import Foundation

class ProvinceData: ObservableObject {
    @Published var provinces: [Province] = []

    init() {
        loadJSON()
    }

    func loadJSON() {
        if let url = Bundle.main.url(forResource: "Provinces", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let decodedData = try decoder.decode([Province].self, from: data)
                self.provinces = decodedData
            } catch {
                print("Error loading JSON: \(error)")
            }
        }
    }
}

struct ProvinceSelectionRowView: View {
    
    let province: Province
    @Binding var isSelected: Bool
    
    var body: some View {
        Button {
            isSelected.toggle()
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(province.province)
                }
                
                Spacer()
                
                if isSelected {
                    Image(
                        systemName: "checkmark.circle.fill"
                    )
                    .foregroundStyle(
                        Color.green
                    )
                    .font(.title3)
                }
            }
        }
        
        Rectangle()
            .frame(maxWidth: .infinity)
            .frame(height: 0.5)
    }
}
