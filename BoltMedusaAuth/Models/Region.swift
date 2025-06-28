//
//  Region.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 28/06/2025.
//

import Foundation

// MARK: - Region Models (Updated for actual Medusa API)
struct Region: Codable, Identifiable {
    let id: String
    let name: String
    let currencyCode: String
    let countries: [Country]?
    let createdAt: String?
    let updatedAt: String?
    let deletedAt: String?
    let metadata: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, countries, metadata
        case currencyCode = "currency_code"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}

struct Country: Codable, Identifiable {
    let iso2: String
    let iso3: String
    let numCode: String
    let name: String
    let displayName: String
    let regionId: String
    let metadata: String?
    let createdAt: String?
    let updatedAt: String?
    let deletedAt: String?
    
    var id: String { iso2 } // Use iso2 as the identifier
    
    enum CodingKeys: String, CodingKey {
        case name, metadata
        case iso2 = "iso_2"
        case iso3 = "iso_3"
        case numCode = "num_code"
        case displayName = "display_name"
        case regionId = "region_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}

// MARK: - Country Selection Model (flattened from regions)
struct CountrySelection: Codable, Identifiable, Equatable {
    let country: String        // iso2 code (e.g., "gb", "fr")
    let label: String          // display name (e.g., "United Kingdom")
    let currencyCode: String   // currency (e.g., "eur")
    let regionId: String       // region ID for cart creation
    
    var id: String { country } // Use country code as identifier
    
    // MARK: - Equatable Conformance
    static func == (lhs: CountrySelection, rhs: CountrySelection) -> Bool {
        return lhs.country == rhs.country &&
               lhs.regionId == rhs.regionId &&
               lhs.currencyCode == rhs.currencyCode
    }
    
    // Computed properties for display
    var flagEmoji: String {
        let iso = country.lowercased()
        
        switch iso {
        case "gb": return "🇬🇧"
        case "us": return "🇺🇸"
        case "ca": return "🇨🇦"
        case "de": return "🇩🇪"
        case "fr": return "🇫🇷"
        case "es": return "🇪🇸"
        case "it": return "🇮🇹"
        case "dk": return "🇩🇰"
        case "se": return "🇸🇪"
        case "au": return "🇦🇺"
        case "jp": return "🇯🇵"
        case "br": return "🇧🇷"
        default: return "🏳️"
        }
    }
    
    var formattedCurrency: String {
        return currencyCode.uppercased()
    }
    
    var displayText: String {
        return "\(flagEmoji) \(label)"
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
    
    var hasUK: Bool {
        return countries?.contains { country in
            country.iso2.lowercased() == "gb" || 
            country.name.lowercased().contains("united kingdom") ||
            country.displayName.lowercased().contains("united kingdom")
        } ?? false
    }
    
    var flagEmoji: String {
        // Return flag emoji based on region name or currency
        let regionName = name.lowercased()
        let currency = currencyCode.lowercased()
        
        if hasUK && currency == "eur" {
            return "🇪🇺" // European Union flag for Europe region with UK
        } else if regionName.contains("europe") || currency == "eur" {
            return "🇪🇺"
        } else if regionName.contains("united states") || regionName.contains("usa") || currency == "usd" {
            return "🇺🇸"
        } else if regionName.contains("canada") || currency == "cad" {
            return "🇨🇦"
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
        guard let countries = countries, !countries.isEmpty else {
            return "No countries"
        }
        
        // If there are many countries, show a summary
        if countries.count > 3 {
            let firstThree = countries.prefix(3).map { $0.displayName }
            return "\(firstThree.joined(separator: ", ")) and \(countries.count - 3) more"
        } else {
            return countries.map { $0.displayName }.joined(separator: ", ")
        }
    }
    
    var countryCount: Int {
        return countries?.count ?? 0
    }
    
    var ukCountry: Country? {
        return countries?.first { country in
            country.iso2.lowercased() == "gb"
        }
    }
    
    // Convert region's countries to CountrySelection objects
    func toCountrySelections() -> [CountrySelection] {
        guard let countries = countries else { return [] }
        
        return countries.map { country in
            CountrySelection(
                country: country.iso2,
                label: country.displayName,
                currencyCode: currencyCode,
                regionId: id
            )
        }
    }
}

extension Country {
    var flagEmoji: String {
        let iso = iso2.lowercased()
        
        switch iso {
        case "gb": return "🇬🇧"
        case "us": return "🇺🇸"
        case "ca": return "🇨🇦"
        case "de": return "🇩🇪"
        case "fr": return "🇫🇷"
        case "es": return "🇪🇸"
        case "it": return "🇮🇹"
        case "dk": return "🇩🇰"
        case "se": return "🇸🇪"
        case "au": return "🇦🇺"
        case "jp": return "🇯🇵"
        case "br": return "🇧🇷"
        default: return "🏳️"
        }
    }
}