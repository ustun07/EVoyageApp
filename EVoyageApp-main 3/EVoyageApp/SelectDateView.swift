//
//  TravelDateSelectionView.swift
//  EVoyageApp
//
//  Created by Furkan Erdoğan on 15.06.2024.
//

import SwiftUI


enum AddTripItem: Hashable {
    
    case departureCity
    case arrivalCity(Province)
}

struct TravelDateSelectionView: View {
    @StateObject var viewModel = AddTravelViewModel()
    @Environment(\.dismiss) var dismiss
    @State var date: Date = .now
    
    var body: some View {
        NavigationStack(path: $viewModel.path) {
            ZStack {
                Color.blue
                    .ignoresSafeArea()
                VStack {
                    infoRow
                        .padding()
                    DatePicker(
                        String(localized: "Departure Date"),
                        selection: $date,
                        in: Date.fortyYearsAgoToday...Date.nextYearToday,
                        displayedComponents: .date
                    )
                    .datePickerStyle(
                        .graphical
                    )
                    .tint(.green)
                    .preferredColorScheme(
                        .dark
                    )
                    
                    Spacer()
                    CTAButton(
                        text: .constant(String(localized: "Continue")),
                        isDisabled: .constant(false),
                        height: 50
                    ) {
                        viewModel.path.append(.departureCity)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Add Trip")
            .navigationDestination(for: AddTripItem.self) { item in
                switch item {
                case .departureCity:
                    SelectDepartureCityView(path: $viewModel.path, date: date)
                case let .arrivalCity(departureProvince):
                    SelectArrivalCityView(date: date, departureCity: departureProvince) { arrivalCity in
                        Task {
                            do {
                                try await viewModel.addFlight(departureProvince: departureProvince, arrivalProvince: arrivalCity, date: date)
                                dismiss()
                            } catch {
                                print("Hata var: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    var infoRow: some View {
        HStack {
            Text("When")
                .foregroundStyle(Color.white)
                .font(
                    .system(
                        size: 18,
                        weight: .semibold,
                        design: .rounded
                    )
                )
            
            Spacer()
            
            HStack {
                Image(systemName: "calendar")
                    .font(.title3)
                    .foregroundStyle(Color.green)
                Text(date.formattedAsDDMMYYYY)
                    .font(
                        .system(
                            size: 16,
                            weight: .semibold,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(Color.white)
                Spacer()
            }
            .frame(width: 220)
            .padding()
            .background(
                Color.white
                    .opacity(0.2)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 25
                        )
                    )
            )
        }
    }
}
