//
//  Customer.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 28/06/2025.
//

import Foundation

struct Customer: Codable, Identifiable {
    let id: String
    let email: String
    let firstName: String?
    let lastName: String?
    let billingAddressId: String?
    let phone: String?
    let hasAccount: Bool
    let createdAt: String
    let updatedAt: String
    let deletedAt: String?
    let metadata: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case id, email, phone, metadata
        case firstName = "first_name"
        case lastName = "last_name"
        case billingAddressId = "billing_address_id"
        case hasAccount = "has_account"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        billingAddressId = try container.decodeIfPresent(String.self, forKey: .billingAddressId)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        hasAccount = try container.decode(Bool.self, forKey: .hasAccount)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        deletedAt = try container.decodeIfPresent(String.self, forKey: .deletedAt)
        
        // Handle metadata as optional dictionary
        if let metadataValue = try? container.decodeIfPresent([String: Any].self, forKey: .metadata) {
            metadata = metadataValue
        } else {
            metadata = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encodeIfPresent(firstName, forKey: .firstName)
        try container.encodeIfPresent(lastName, forKey: .lastName)
        try container.encodeIfPresent(billingAddressId, forKey: .billingAddressId)
        try container.encodeIfPresent(phone, forKey: .phone)
        try container.encode(hasAccount, forKey: .hasAccount)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(deletedAt, forKey: .deletedAt)
    }
}

struct CustomerRegistrationRequest: Codable {
    let email: String
    let password: String
    let firstName: String?
    let lastName: String?
    let phone: String?
    
    enum CodingKeys: String, CodingKey {
        case email, password, phone
        case firstName = "first_name"
        case lastName = "last_name"
    }
}

struct CustomerLoginRequest: Codable {
    let email: String
    let password: String
}

struct AuthResponse: Codable {
    let customer: Customer
    let token: String?
}

struct MedusaResponse<T: Codable>: Codable {
    let customer: T?
    let token: String?
}