//
//  CarSelectionView.swift
//  EVoyageApp
//
//  Created by Furkan Erdoğan on 26.05.2024.
//

import SwiftUI
import Combine

struct CarSelectionView: View {
    
    let cars = [Car(brand: "Togg", model: "T10X"),
                Car(brand: "Tesla", model: "Model Y"),
                Car(brand: "Renault", model: "Megane E-Tech"),
                Car(brand: "MG", model: "MG4"),
                Car(brand: "Skywell", model: "ET5"),
                Car(brand: "BYD", model: "ATTO 3"),
                Car(brand: "BMW", model: "i4 eDrive40"),
                Car(brand: "Porsche", model: "Taycan"),
                Car(brand: "Volvo", model: "XC40 Recharge"),
                Car(brand: "Hyundai", model: "Ioniq 5"),]
    
    @State private var selection: Car?
    @State var buttonText = "Save Car"
    @State var isLoading = false
    private let currentUserService: CurrentUserInfoService = .shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.blue.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(cars, id: \.self) { car in
                        VStack(alignment: .leading) {
                            CarRowView(car: car, isSelected: Binding(get: {
                                car.brand.contains(selection?.brand ?? "")
                            }, set: { value in
                                selection = car
                            }))
                        }
                        .padding(.horizontal)
                        .foregroundStyle(Color.white)
                        .padding(.vertical, 2.5)
                    }
                    Spacer()
                }
            }
            .safeAreaInset(edge: .bottom) {
                CTAButton(
                    text: $buttonText,
                    isDisabled: .constant(false),
                    height: 50
                ) {
                    Task.detached { @MainActor in
                        isLoading = true
                        do {
                            try await currentUserService.setCarInfo(car: selection ?? Car(brand: "", model: ""))
                            isLoading = false
                            dismiss()
                        } catch {
                            dismiss()
                            isLoading = false
                            print("Error from \(#file) - ", error.localizedDescription)
                        }
                    }
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
        .navigationTitle("Car Selection")
    }
}

#Preview {
    CarSelectionView()
}

struct CarRowView: View {
    
    let car: Car
    @Binding var isSelected: Bool
    
    var body: some View {
        Button {
            isSelected.toggle()
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(car.brand)
                        .bold()
                    Text(car.model)
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

struct CTAButton: View {
    @Binding var text: String
    @Binding var isDisabled: Bool
    let height: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            Text(text)
                .foregroundStyle(Color.white)
                .frame(height: height)
                .frame(maxWidth: .infinity)
                .font(
                    .system(
                        size: 18,
                        weight: .medium,
                        design: .rounded
                    )
                )
                .background(
                    Color.green
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: height / 2
                            )
                        )
                )
                .opacity(isDisabled ? 0.6 : 1)
        }
        .disabled(isDisabled)
    }
}
