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
    
    enum CodingKeys: String, CodingKey {
        case id, email, phone
        case firstName = "first_name"
        case lastName = "last_name"
        case billingAddressId = "billing_address_id"
        case hasAccount = "has_account"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
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