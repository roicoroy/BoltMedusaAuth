//
//  PaymentCollection.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 01/07/2025.
//

import Foundation
import SwiftUI

// MARK: - Payment Collection Models
public struct PaymentCollection: Codable, Identifiable {
    public let id: String
    public let currencyCode: String
    public let amount: Int
    public let status: String?
    public let paymentProviders: [PaymentCollectionProvider]?
    public let paymentSessions: [PaymentSession]?
    public let metadata: [String: AnyCodable]?
    public let createdAt: String?
    public let updatedAt: String?
    public let completedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, amount, status, metadata
        case currencyCode = "currency_code"
        case paymentProviders = "payment_providers"
        case paymentSessions = "payment_sessions"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case completedAt = "completed_at"
    }
    
    // Custom decoder to handle flexible metadata
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        currencyCode = try container.decode(String.self, forKey: .currencyCode)
        amount = try decodeFlexibleInt(from: container, forKey: .amount) ?? 0
        status = try container.decodeIfPresent(String.self, forKey: .status)
        paymentProviders = try container.decodeIfPresent([PaymentCollectionProvider].self, forKey: .paymentProviders)
        paymentSessions = try container.decodeIfPresent([PaymentSession].self, forKey: .paymentSessions)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        completedAt = try container.decodeIfPresent(String.self, forKey: .completedAt)
        
        // Handle metadata as flexible dictionary
        if container.contains(.metadata) {
            if let metadataDict = try? container.decode([String: AnyCodable].self, forKey: .metadata) {
                metadata = metadataDict
            } else {
                metadata = nil
            }
        } else {
            metadata = nil
        }
    }
    
    // Custom encoder
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(currencyCode, forKey: .currencyCode)
        try container.encode(amount, forKey: .amount)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(paymentProviders, forKey: .paymentProviders)
        try container.encodeIfPresent(paymentSessions, forKey: .paymentSessions)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(completedAt, forKey: .completedAt)
        
        // Skip metadata encoding for simplicity
    }
}

public struct PaymentCollectionProvider: Codable, Identifiable {
    public let id: String
    public let name: String?
    public let isEnabled: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case isEnabled = "is_enabled"
    }
}

// MARK: - API Request/Response Models
public struct CreatePaymentCollectionRequest: Codable {
    public let cartId: String
    
    enum CodingKeys: String, CodingKey {
        case cartId = "cart_id"
    }
}

public struct PaymentCollectionResponse: Codable {
    public let paymentCollection: PaymentCollection
    
    enum CodingKeys: String, CodingKey {
        case paymentCollection = "payment_collection"
    }
}

// MARK: - Helper Extensions
extension PaymentCollection {
    public func formattedAmount() -> String {
        return formatPrice(amount, currencyCode: currencyCode)
    }
    
    
    public var displayStatus: String {
        return (status ?? "").capitalized
    }
    
    public var statusColor: Color {
        switch (status ?? "").lowercased() {
        case "pending", "requires_action":
            return .orange
        case "completed", "succeeded":
            return .green
        case "canceled", "cancelled", "failed":
            return .red
        case "processing":
            return .blue
        default:
            return .gray
        }
    }
    
    public var isCompleted: Bool {
        return (status ?? "").lowercased() == "completed" || (status ?? "").lowercased() == "succeeded"
    }
    
    public var isPending: Bool {
        return (status ?? "").lowercased() == "pending" || (status ?? "").lowercased() == "requires_action"
    }
    
    public var isFailed: Bool {
        return (status ?? "").lowercased() == "failed" || (status ?? "").lowercased() == "canceled" || (status ?? "").lowercased() == "cancelled"
    }
    
    public var isProcessing: Bool {
        return (status ?? "").lowercased() == "processing"
    }
    
    public var providerCount: Int {
        return paymentProviders?.count ?? 0
    }
    
    public var providerNames: String {
        guard let providers = paymentProviders, !providers.isEmpty else {
            return "No providers"
        }
        
        return providers.compactMap { $0.name ?? $0.id }.joined(separator: ", ")
    }
    
    public var enabledProviders: [PaymentCollectionProvider] {
        return paymentProviders?.filter { $0.isEnabled ?? true } ?? []
    }
    
    public var disabledProviders: [PaymentCollectionProvider] {
        return paymentProviders?.filter { !($0.isEnabled ?? true) } ?? []
    }
    
    public var hasEnabledProviders: Bool {
        return !enabledProviders.isEmpty
    }
    
    public var createdDate: Date? {
        guard let createdAt = createdAt else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: createdAt)
    }
    
    public var updatedDate: Date? {
        guard let updatedAt = updatedAt else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: updatedAt)
    }
    
    public var completedDate: Date? {
        guard let completedAt = completedAt else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: completedAt)
    }
    
    public func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    public var formattedCreatedDate: String {
        return formattedDate(createdDate)
    }
    
    public var formattedUpdatedDate: String {
        return formattedDate(updatedDate)
    }
    
    public var formattedCompletedDate: String {
        return formattedDate(completedDate)
    }
}

extension PaymentCollectionProvider {
    public var displayName: String {
        return name ?? id.capitalized
    }
    
    public var isAvailable: Bool {
        return isEnabled ?? true
    }
    
    public var statusText: String {
        return isAvailable ? "Enabled" : "Disabled"
    }
    
    public var statusColor: Color {
        return isAvailable ? .green : .red
    }
}
