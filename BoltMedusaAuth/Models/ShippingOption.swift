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
    let amount: Int?
    let isReturn: Bool
    let adminOnly: Bool
    let providerId: String?
    let data: [String: Any]?
    let includes_tax: Bool?
    let createdAt: String?
    let updatedAt: String?
    let deletedAt: String?
    let metadata: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, amount, data, metadata
        case priceType = "price_type"
        case isReturn = "is_return"
        case adminOnly = "admin_only"
        case providerId = "provider_id"
        case includes_tax
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
        amount = try container.decodeIfPresent(Int.self, forKey: .amount)
        isReturn = try container.decode(Bool.self, forKey: .isReturn)
        adminOnly = try container.decode(Bool.self, forKey: .adminOnly)
        providerId = try container.decodeIfPresent(String.self, forKey: .providerId)
        includes_tax = try container.decodeIfPresent(Bool.self, forKey: .includes_tax)
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
        try container.encodeIfPresent(amount, forKey: .amount)
        try container.encode(isReturn, forKey: .isReturn)
        try container.encode(adminOnly, forKey: .adminOnly)
        try container.encodeIfPresent(providerId, forKey: .providerId)
        try container.encodeIfPresent(includes_tax, forKey: .includes_tax)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(deletedAt, forKey: .deletedAt)
        
        // Skip data and metadata encoding for simplicity
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
        guard let amount = amount else {
            return "Contact for pricing"
        }
        return formatPrice(amount, currencyCode: currencyCode)
    }
    
    var formattedAmount: String {
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
        case "flat_rate":
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
        return amount == 0 || priceType.lowercased() == "free"
    }
    
    var isCalculated: Bool {
        return priceType.lowercased() == "calculated"
    }
    
    var providerName: String {
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
        default:
            return providerId.capitalized
        }
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
        }
        
        if let metadata = metadata {
            if let delivery = metadata["estimated_delivery"] as? String {
                return delivery
            }
            if let delivery = metadata["delivery_time"] as? String {
                return delivery
            }
        }
        
        return nil
    }
    
    var description: String? {
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
}