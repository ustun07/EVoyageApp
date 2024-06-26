//
//  SelectArrivalCityView.swift
//  EVoyageApp
//
//  Created by Furkan Erdoğan on 15.06.2024.
//

import SwiftUI
import Combine

struct SelectArrivalCityView: View {
    
    @ObservedObject var provinceData = ProvinceData()
    
    @State private var selection: Province?
    @State var buttonText = "Continue"
    @State var isLoading = false
    private let currentUserService: CurrentUserInfoService = .shared
    @Environment(\.dismiss) var dismiss
    let date: Date
    let departureCity: Province
    let addTravelTapped: (_ arrivalCity: Province) -> Void
    
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
                    addTravelTapped(selection ?? .init(id: "", province: "", coordinates: .init(latitude: 2.1, longitude: 2.1)))
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
        .navigationTitle("Arrival City")
    }
}
