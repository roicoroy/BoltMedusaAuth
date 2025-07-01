
//
//  PaymentSession.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 01/07/2025.
//

import Foundation

public struct PaymentSession: Codable, Identifiable {
    public let id: String
    public let currencyCode: String?
    public let providerId: String?
    public let data: [String: AnyCodable]? // Use AnyCodable for flexible data
    public let context: [String: AnyCodable]?
    public let status: String?
    public let authorizedAt: String?
    public let paymentCollectionId: String?
    public let metadata: [String: AnyCodable]?
    public let rawAmount: RawAmount?
    public let createdAt: String?
    public let updatedAt: String?
    public let deletedAt: String?
    public let amount: Double

    enum CodingKeys: String, CodingKey {
        case id
        case currencyCode = "currency_code"
        case providerId = "provider_id"
        case data, context, status
        case authorizedAt = "authorized_at"
        case paymentCollectionId = "payment_collection_id"
        case metadata
        case rawAmount = "raw_amount"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case amount
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        currencyCode = try container.decodeIfPresent(String.self, forKey: .currencyCode)
        providerId = try container.decodeIfPresent(String.self, forKey: .providerId)
        data = try container.decodeIfPresent([String: AnyCodable].self, forKey: .data)
        context = try container.decodeIfPresent([String: AnyCodable].self, forKey: .context)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        authorizedAt = try container.decodeIfPresent(String.self, forKey: .authorizedAt)
        paymentCollectionId = try container.decodeIfPresent(String.self, forKey: .paymentCollectionId)
        metadata = try container.decodeIfPresent([String: AnyCodable].self, forKey: .metadata)
        rawAmount = try container.decodeIfPresent(RawAmount.self, forKey: .rawAmount)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        deletedAt = try container.decodeIfPresent(String.self, forKey: .deletedAt)
        amount = try container.decode(Double.self, forKey: .amount)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(currencyCode, forKey: .currencyCode)
        try container.encodeIfPresent(providerId, forKey: .providerId)
        try container.encodeIfPresent(data, forKey: .data)
        try container.encodeIfPresent(context, forKey: .context)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(authorizedAt, forKey: .authorizedAt)
        try container.encodeIfPresent(paymentCollectionId, forKey: .paymentCollectionId)
        try container.encodeIfPresent(metadata, forKey: .metadata)
        try container.encodeIfPresent(rawAmount, forKey: .rawAmount)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(deletedAt, forKey: .deletedAt)
        try container.encode(amount, forKey: .amount)
    }
}

public struct RawAmount: Codable {
    public let value: String
    public let precision: Int
}
