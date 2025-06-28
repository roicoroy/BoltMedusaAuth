//
//  Region.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 28/06/2025.
//

import Foundation

// MARK: - Region Models
struct Region: Codable, Identifiable {
    let id: String
    let name: String
    let currencyCode: String
    let taxRate: Double?
    let taxCode: String?
    let giftCardsTaxable: Bool?
    let automaticTaxes: Bool?
    let taxInclusivePricing: Bool?
    let countries: [Country]?
    let paymentProviders: [PaymentProvider]?
    let fulfillmentProviders: [FulfillmentProvider]?
    let createdAt: String
    let updatedAt: String
    let deletedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, countries
        case currencyCode = "currency_code"
        case taxRate = "tax_rate"
        case taxCode = "tax_code"
        case giftCardsTaxable = "gift_cards_taxable"
        case automaticTaxes = "automatic_taxes"
        case taxInclusivePricing = "tax_inclusive_pricing"
        case paymentProviders = "payment_providers"
        case fulfillmentProviders = "fulfillment_providers"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}

struct Country: Codable, Identifiable {
    let id: String
    let iso2: String
    let iso3: String
    let numCode: Int
    let name: String
    let displayName: String
    let regionId: String?
    
    enum CodingKeys: String, CodingKey {
        case id, iso2, iso3, name
        case numCode = "num_code"
        case displayName = "display_name"
        case regionId = "region_id"
    }
}

struct PaymentProvider: Codable, Identifiable {
    let id: String
    let isInstalled: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case isInstalled = "is_installed"
    }
}

struct FulfillmentProvider: Codable, Identifiable {
    let id: String
    let isInstalled: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case isInstalled = "is_installed"
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
    
    var countryNames: String {
        guard let countries = countries, !countries.isEmpty else {
            return "No countries"
        }
        return countries.map { $0.displayName }.joined(separator: ", ")
    }
    
    var isUK: Bool {
        return countries?.contains { $0.iso2.lowercased() == "gb" || $0.iso2.lowercased() == "uk" } ?? false
    }
    
    var flagEmoji: String {
        // Return flag emoji based on primary country
        guard let primaryCountry = countries?.first else { return "🌍" }
        
        switch primaryCountry.iso2.lowercased() {
        case "gb", "uk":
            return "🇬🇧"
        case "us":
            return "🇺🇸"
        case "ca":
            return "🇨🇦"
        case "de":
            return "🇩🇪"
        case "fr":
            return "🇫🇷"
        case "es":
            return "🇪🇸"
        case "it":
            return "🇮🇹"
        case "au":
            return "🇦🇺"
        case "jp":
            return "🇯🇵"
        case "br":
            return "🇧🇷"
        default:
            return "🌍"
        }
    }
}

extension Country {
    var flagEmoji: String {
        switch iso2.lowercased() {
        case "gb", "uk":
            return "🇬🇧"
        case "us":
            return "🇺🇸"
        case "ca":
            return "🇨🇦"
        case "de":
            return "🇩🇪"
        case "fr":
            return "🇫🇷"
        case "es":
            return "🇪🇸"
        case "it":
            return "🇮🇹"
        case "au":
            return "🇦🇺"
        case "jp":
            return "🇯🇵"
        case "br":
            return "🇧🇷"
        default:
            return "🌍"
        }
    }
}