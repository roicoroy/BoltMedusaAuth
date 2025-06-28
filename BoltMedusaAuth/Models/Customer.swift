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
    let metadata: AnyCodable?
    
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
}

// Helper struct to handle Any type in JSON
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            let codableArray = array.map { AnyCodable($0) }
            try container.encode(codableArray)
        case let dictionary as [String: Any]:
            let codableDictionary = dictionary.mapValues { AnyCodable($0) }
            try container.encode(codableDictionary)
        default:
            try container.encodeNil()
        }
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