//
//  PaymentProvider.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 01/07/2025.
//

import Foundation
import SwiftUI

// MARK: - Payment Provider Models
struct PaymentProvider: Codable, Identifiable {
    let id: String
    let name: String?
    let description: String?
    let isEnabled: Bool?
    let metadata: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, metadata
        case isEnabled = "is_enabled"
    }
    
    // Custom decoder to handle flexible metadata
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled)
        
        // Handle metadata as flexible dictionary
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
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(isEnabled, forKey: .isEnabled)
        
        // Skip metadata encoding for simplicity
    }
}

// MARK: - API Response Models
struct PaymentProvidersResponse: Codable {
    let paymentProviders: [PaymentProvider]
    let limit: Int
    let offset: Int
    let count: Int
    
    enum CodingKeys: String, CodingKey {
        case limit, offset, count
        case paymentProviders = "payment_providers"
    }
}

// MARK: - Helper Extensions
extension PaymentProvider {
    var displayName: String {
        return name ?? id.capitalized
    }
    
    var displayDescription: String {
        return description ?? "Payment provider"
    }
    
    var providerType: PaymentProviderType {
        let lowercaseId = id.lowercased()
        
        if lowercaseId.contains("stripe") {
            return .stripe
        } else if lowercaseId.contains("paypal") {
            return .paypal
        } else if lowercaseId.contains("manual") {
            return .manual
        } else if lowercaseId.contains("klarna") {
            return .klarna
        } else if lowercaseId.contains("apple") || lowercaseId.contains("applepay") {
            return .applePay
        } else if lowercaseId.contains("google") || lowercaseId.contains("googlepay") {
            return .googlePay
        } else if lowercaseId.contains("razorpay") {
            return .razorpay
        } else if lowercaseId.contains("square") {
            return .square
        } else if lowercaseId.contains("adyen") {
            return .adyen
        } else {
            return .other
        }
    }
    
    var iconName: String {
        switch providerType {
        case .stripe:
            return "creditcard"
        case .paypal:
            return "dollarsign.circle"
        case .manual:
            return "hand.raised"
        case .klarna:
            return "k.circle"
        case .applePay:
            return "applelogo"
        case .googlePay:
            return "g.circle"
        case .razorpay:
            return "r.circle"
        case .square:
            return "square"
        case .adyen:
            return "a.circle"
        case .other:
            return "creditcard.circle"
        }
    }
    
    var iconColor: Color {
        switch providerType {
        case .stripe:
            return .purple
        case .paypal:
            return .blue
        case .manual:
            return .orange
        case .klarna:
            return .pink
        case .applePay:
            return .black
        case .googlePay:
            return .green
        case .razorpay:
            return .blue
        case .square:
            return .black
        case .adyen:
            return .green
        case .other:
            return .gray
        }
    }
    
    var isAvailable: Bool {
        return isEnabled ?? true
    }
    
    var statusText: String {
        if isAvailable {
            return "Available"
        } else {
            return "Disabled"
        }
    }
    
    var statusColor: Color {
        return isAvailable ? .green : .red
    }
    
    var supportedMethods: [String] {
        switch providerType {
        case .stripe:
            return ["Credit Card", "Debit Card", "Apple Pay", "Google Pay"]
        case .paypal:
            return ["PayPal Account", "Credit Card", "Debit Card"]
        case .manual:
            return ["Cash", "Bank Transfer", "Check"]
        case .klarna:
            return ["Pay Later", "Pay in 3", "Financing"]
        case .applePay:
            return ["Apple Pay", "Touch ID", "Face ID"]
        case .googlePay:
            return ["Google Pay", "Android Pay"]
        case .razorpay:
            return ["UPI", "Net Banking", "Wallets", "Cards"]
        case .square:
            return ["Credit Card", "Debit Card", "Cash App"]
        case .adyen:
            return ["Credit Card", "Debit Card", "Local Payment Methods"]
        case .other:
            return ["Various Payment Methods"]
        }
    }
}

enum PaymentProviderType {
    case stripe
    case paypal
    case manual
    case klarna
    case applePay
    case googlePay
    case razorpay
    case square
    case adyen
    case other
}
