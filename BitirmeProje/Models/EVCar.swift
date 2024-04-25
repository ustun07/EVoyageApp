//
//  EVCar.swift
//  BitirmeProje
//
//  
//

import Foundation

// MARK: - EVCar
struct EVCar: Codable {
    let name, subtitle, acceleration: String
    let range, efficiency, fastChargeSpeed, drive: String
    let numberofSeats: Int
    let priceinGermany, priceinUK: String

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case subtitle = "Subtitle"
        case acceleration = "Acceleration"
        case range = "Range"
        case efficiency = "Efficiency"
        case fastChargeSpeed = "FastChargeSpeed"
        case drive = "Drive"
        case numberofSeats = "NumberofSeats"
        case priceinGermany = "PriceinGermany"
        case priceinUK = "PriceinUK"
    }
}
