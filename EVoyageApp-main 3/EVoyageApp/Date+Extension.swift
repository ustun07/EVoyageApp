//
//  Date+Extension.swift
//  EVoyageApp
//
//  Created by Furkan Erdoğan on 15.06.2024.
//

import Foundation

extension Date {
    static var fullDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        return dateFormatter
    }()
    
    var fullDateString: String {
        Self.fullDateFormatter.string(from: self)
    }
    
    var shortDateString: String {
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "yyyy-MM-dd"

        return outputFormatter.string(from: self)
    }
    
    static var iso8601FullDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withFullDate
        ]
        return formatter
    }()
    
    var iso8601FullDateString: String {
        Self.iso8601FullDateFormatter.string(from: self)
    }
    
    var isPast: Bool {
        return self < .now
    }
    
    static let minTravelDate = Date.now
    
    init?(year: Int, month: Int, day: Int) {
        var dateComponents = DateComponents()
        dateComponents.year = 2006
        dateComponents.month = 1
        dateComponents.day = 1

        guard let date = Calendar.current.date(from: dateComponents) else {
            return nil
        }
        self = date
    }
    
    static var fortyYearsAgoToday: Date {
        return Calendar.current.date(byAdding: .year, value: -40, to: .now)!
    }
    
    static var nextYearToday: Date {
        return Calendar.current.date(byAdding: .year, value: 1, to: .now)!
    }
    
    static var yesterday: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: .now)!
    }
    
    static var YYYYMMDDDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()
    
    var formattedAsYYYYMMDD: String {
        Self.YYYYMMDDDateFormatter.string(from: self)
    }
    
    static var DDMMYYYYDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()
    
    var formattedAsDDMMYYYY: String {
        Self.DDMMYYYYDateFormatter.string(from: self)
    }
    
    static var MMMDDYYYYDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter
    }()
    
    var formattedAsMMMDDYYYY: String {
        Self.MMMDDYYYYDateFormatter.string(from: self)
    }
    
    static var whiteSpacedDateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter
    }()
    
    var whiteSpacedFormatted: String {
        Self.whiteSpacedDateFormatter.string(from: self)
    }
    
    func differenceInHourAndMinutes(from: Date) -> (hours: Int, minutes: Int) {
        let diff = Int(self.timeIntervalSince1970 - from.timeIntervalSince1970)
        
        let hours = diff / 3600
        let minutes = (diff - hours * 3600) / 60
        return (hours, minutes)
    }
}
