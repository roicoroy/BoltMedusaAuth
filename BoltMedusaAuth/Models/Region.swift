//
//  Region.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 28/06/2025.
//

import Foundation

// MARK: - Region Models (Simplified for actual Medusa API)
struct Region: Codable, Identifiable {
    let id: String
    let name: String
    let currencyCode: String
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case currencyCode = "currency_code"
    }
}

// MARK: - API Response Models
struct RegionsResponse: Codable {
    let regions: [Region]
    let count: Int
    let offset: Int
    let limit: Int
}

struct RegionResponse: Codable {
    let region: Region
}

// MARK: - Helper Extensions
extension Region {
    var displayName: String {
        return name
    }
    
    var formattedCurrency: String {
        return currencyCode.uppercased()
    }
    
    var isUK: Bool {
        return name.lowercased().contains("uk") || 
               name.lowercased().contains("united kingdom") ||
               name.lowercased().contains("britain") ||
               currencyCode.lowercased() == "gbp"
    }
    
    var flagEmoji: String {
        // Return flag emoji based on region name or currency
        let regionName = name.lowercased()
        let currency = currencyCode.lowercased()
        
        if isUK || currency == "gbp" {
            return "🇬🇧"
        } else if regionName.contains("united states") || regionName.contains("usa") || currency == "usd" {
            return "🇺🇸"
        } else if regionName.contains("canada") || currency == "cad" {
            return "🇨🇦"
        } else if regionName.contains("germany") || regionName.contains("deutschland") || currency == "eur" {
            return "🇪🇺"
        } else if regionName.contains("france") {
            return "🇫🇷"
        } else if regionName.contains("spain") {
            return "🇪🇸"
        } else if regionName.contains("italy") {
            return "🇮🇹"
        } else if regionName.contains("australia") || currency == "aud" {
            return "🇦🇺"
        } else if regionName.contains("japan") || currency == "jpy" {
            return "🇯🇵"
        } else if regionName.contains("brazil") || currency == "brl" {
            return "🇧🇷"
        } else {
            return "🌍"
        }
    }
    
    var countryNames: String {
        // Since we don't have countries in the simplified API, 
        // we'll derive likely countries from the region name
        let regionName = name.lowercased()
        
        if isUK {
            return "United Kingdom"
        } else if regionName.contains("united states") || regionName.contains("usa") {
            return "United States"
        } else if regionName.contains("canada") {
            return "Canada"
        } else if regionName.contains("germany") {
            return "Germany"
        } else if regionName.contains("france") {
            return "France"
        } else if regionName.contains("spain") {
            return "Spain"
        } else if regionName.contains("italy") {
            return "Italy"
        } else if regionName.contains("australia") {
            return "Australia"
        } else if regionName.contains("japan") {
            return "Japan"
        } else if regionName.contains("brazil") {
            return "Brazil"
        } else if regionName.contains("europe") || currencyCode.lowercased() == "eur" {
            return "European Union"
        } else {
            return name // Fallback to region name
        }
    }
}