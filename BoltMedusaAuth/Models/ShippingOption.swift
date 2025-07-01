//
//  ShippingOption.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 01/07/2025.
//

import Foundation

// MARK: - Shipping Option Models
struct ShippingOption: Codable, Identifiable {
    let id: String
    let name: String
    let priceType: String
    let serviceZoneId: String?
    let providerId: String?
    let provider: ShippingProvider?
    let type: ShippingType?
    let shippingProfileId: String?
    let amount: Int?
    let data: [String: Any]?
    let prices: [ShippingPrice]?
    let calculatedPrice: CalculatedPrice?
    let insufficientInventory: Bool?
    let createdAt: String?
    let updatedAt: String?
    let deletedAt: String?
    let metadata: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, amount, data, prices, metadata
        case priceType = "price_type"
        case serviceZoneId = "service_zone_id"
        case providerId = "provider_id"
        case provider
        case type
        case shippingProfileId = "shipping_profile_id"
        case calculatedPrice = "calculated_price"
        case insufficientInventory = "insufficient_inventory"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
    
    // Custom decoder to handle flexible data and metadata
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        priceType = try container.decode(String.self, forKey: .priceType)
        serviceZoneId = try container.decodeIfPresent(String.self, forKey: .serviceZoneId)
        providerId = try container.decodeIfPresent(String.self, forKey: .providerId)
        provider = try container.decodeIfPresent(ShippingProvider.self, forKey: .provider)
        type = try container.decodeIfPresent(ShippingType.self, forKey: .type)
        shippingProfileId = try container.decodeIfPresent(String.self, forKey: .shippingProfileId)
        amount = try container.decodeIfPresent(Int.self, forKey: .amount)
        prices = try container.decodeIfPresent([ShippingPrice].self, forKey: .prices)
        calculatedPrice = try container.decodeIfPresent(CalculatedPrice.self, forKey: .calculatedPrice)
        insufficientInventory = try container.decodeIfPresent(Bool.self, forKey: .insufficientInventory)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        deletedAt = try container.decodeIfPresent(String.self, forKey: .deletedAt)
        
        // Handle flexible data dictionary
        if container.contains(.data) {
            if let dataDict = try? container.decode([String: AnyCodable].self, forKey: .data) {
                data = dataDict.mapValues { $0.value }
            } else {
                data = nil
            }
        } else {
            data = nil
        }
        
        // Handle flexible metadata dictionary
        if container.contains(.metadata) {
            if let metadataDict = try? container.decode([String: AnyCodable].self, forKey: .metadata) {
                metadata = metadataDict.mapValues { $0.value }
            } else {
                metadata = nil
            }
        } else {
            metadata = nil
        }
    }
    
    // Custom encoder
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(priceType, forKey: .priceType)
        try container.encodeIfPresent(serviceZoneId, forKey: .serviceZoneId)
        try container.encodeIfPresent(providerId, forKey: .providerId)
        try container.encodeIfPresent(provider, forKey: .provider)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encodeIfPresent(shippingProfileId, forKey: .shippingProfileId)
        try container.encodeIfPresent(amount, forKey: .amount)
        try container.encodeIfPresent(prices, forKey: .prices)
        try container.encodeIfPresent(calculatedPrice, forKey: .calculatedPrice)
        try container.encodeIfPresent(insufficientInventory, forKey: .insufficientInventory)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(deletedAt, forKey: .deletedAt)
        
        // Skip data and metadata encoding for simplicity
    }
}

// MARK: - Supporting Models

struct ShippingProvider: Codable, Identifiable {
    let id: String
    let isEnabled: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case isEnabled = "is_enabled"
    }
}

struct ShippingType: Codable, Identifiable {
    let id: String
    let label: String
    let description: String?
    let code: String
}

struct ShippingPrice: Codable, Identifiable {
    let id: String
    let currencyCode: String
    let amount: Int
    let minQuantity: Int?
    let maxQuantity: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, amount
        case currencyCode = "currency_code"
        case minQuantity = "min_quantity"
        case maxQuantity = "max_quantity"
    }
}

struct CalculatedPrice: Codable, Identifiable {
    let id: String
    let calculatedAmount: Int
    let originalAmount: Int
    let currencyCode: String
    let originalAmountWithTax: Int?
    let originalAmountWithoutTax: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case calculatedAmount = "calculated_amount"
        case originalAmount = "original_amount"
        case currencyCode = "currency_code"
        case originalAmountWithTax = "original_amount_with_tax"
        case originalAmountWithoutTax = "original_amount_without_tax"
    }
}

// MARK: - API Response Models
struct ShippingOptionsResponse: Codable {
    let shippingOptions: [ShippingOption]
    
    enum CodingKeys: String, CodingKey {
        case shippingOptions = "shipping_options"
    }
}

// MARK: - Helper Extensions
extension ShippingOption {
    func formattedAmount(currencyCode: String) -> String {
        // Check if we have a calculated price first
        if let calculatedPrice = calculatedPrice {
            return formatPrice(calculatedPrice.calculatedAmount, currencyCode: calculatedPrice.currencyCode)
        }
        
        // Check if we have a specific price for this currency
        if let prices = prices,
           let price = prices.first(where: { $0.currencyCode.lowercased() == currencyCode.lowercased() }) {
            return formatPrice(price.amount, currencyCode: price.currencyCode)
        }
        
        // Fall back to the base amount
        guard let amount = amount else {
            return "Contact for pricing"
        }
        return formatPrice(amount, currencyCode: currencyCode)
    }
    
    var formattedAmount: String {
        // Check if we have a calculated price first
        if let calculatedPrice = calculatedPrice {
            return formatPrice(calculatedPrice.calculatedAmount, currencyCode: calculatedPrice.currencyCode)
        }
        
        // Check if we have any prices
        if let prices = prices, let firstPrice = prices.first {
            return formatPrice(firstPrice.amount, currencyCode: firstPrice.currencyCode)
        }
        
        // Fall back to the base amount
        guard let amount = amount else {
            return "Contact for pricing"
        }
        return formatPrice(amount, currencyCode: "USD")
    }
    
    var displayName: String {
        return name
    }
    
    var priceTypeDisplay: String {
        switch priceType.lowercased() {
        case "flat_rate", "flat":
            return "Flat Rate"
        case "calculated":
            return "Calculated"
        case "free":
            return "Free"
        default:
            return priceType.capitalized
        }
    }
    
    var isFree: Bool {
        // Check calculated price first
        if let calculatedPrice = calculatedPrice {
            return calculatedPrice.calculatedAmount == 0
        }
        
        // Check prices array
        if let prices = prices {
            return prices.allSatisfy { $0.amount == 0 }
        }
        
        // Check base amount
        return amount == 0 || priceType.lowercased() == "free"
    }
    
    var isCalculated: Bool {
        return priceType.lowercased() == "calculated"
    }
    
    var providerName: String {
        // Use provider name if available
        if let provider = provider {
            return provider.id.capitalized
        }
        
        // Fall back to provider ID
        guard let providerId = providerId else {
            return "Standard"
        }
        
        // Map common provider IDs to display names
        switch providerId.lowercased() {
        case "manual":
            return "Manual"
        case "webshipper":
            return "Webshipper"
        case "fulfillment-manual":
            return "Manual Fulfillment"
        case "ups":
            return "UPS"
        case "fedex":
            return "FedEx"
        case "dhl":
            return "DHL"
        case "usps":
            return "USPS"
        default:
            return providerId.capitalized
        }
    }
    
    var isProviderEnabled: Bool {
        return provider?.isEnabled ?? true
    }
    
    var typeLabel: String? {
        return type?.label
    }
    
    var typeDescription: String? {
        return type?.description
    }
    
    var typeCode: String? {
        return type?.code
    }
    
    var estimatedDelivery: String? {
        // Try to extract delivery information from data or metadata
        if let data = data {
            if let delivery = data["estimated_delivery"] as? String {
                return delivery
            }
            if let delivery = data["delivery_time"] as? String {
                return delivery
            }
            if let delivery = data["transit_time"] as? String {
                return delivery
            }
        }
        
        if let metadata = metadata {
            if let delivery = metadata["estimated_delivery"] as? String {
                return delivery
            }
            if let delivery = metadata["delivery_time"] as? String {
                return delivery
            }
            if let delivery = metadata["transit_time"] as? String {
                return delivery
            }
        }
        
        return nil
    }
    
    var description: String? {
        // Try type description first
        if let typeDesc = type?.description, !typeDesc.isEmpty {
            return typeDesc
        }
        
        // Try to extract description from data or metadata
        if let data = data {
            if let desc = data["description"] as? String {
                return desc
            }
        }
        
        if let metadata = metadata {
            if let desc = metadata["description"] as? String {
                return desc
            }
        }
        
        return nil
    }
    
    var hasInsufficientInventory: Bool {
        return insufficientInventory ?? false
    }
    
    var isAvailable: Bool {
        return !hasInsufficientInventory && isProviderEnabled
    }
    
    var availabilityStatus: String {
        if hasInsufficientInventory {
            return "Insufficient Inventory"
        } else if !isProviderEnabled {
            return "Provider Disabled"
        } else {
            return "Available"
        }
    }
    
    var availabilityColor: Color {
        if hasInsufficientInventory {
            return .red
        } else if !isProviderEnabled {
            return .orange
        } else {
            return .green
        }
    }
}

// MARK: - Price Extensions
extension ShippingPrice {
    func formattedAmount() -> String {
        return formatPrice(amount, currencyCode: currencyCode)
    }
}

extension CalculatedPrice {
    func formattedCalculatedAmount() -> String {
        return formatPrice(calculatedAmount, currencyCode: currencyCode)
    }
    
    func formattedOriginalAmount() -> String {
        return formatPrice(originalAmount, currencyCode: currencyCode)
    }
    
    func formattedOriginalAmountWithTax() -> String? {
        guard let amount = originalAmountWithTax else { return nil }
        return formatPrice(amount, currencyCode: currencyCode)
    }
    
    func formattedOriginalAmountWithoutTax() -> String? {
        guard let amount = originalAmountWithoutTax else { return nil }
        return formatPrice(amount, currencyCode: currencyCode)
    }
}

// Import Color for availability status
import SwiftUI