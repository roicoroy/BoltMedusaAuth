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
    let defaultBillingAddressId: String?
    let defaultShippingAddressId: String?
    let companyName: String?
    let firstName: String?
    let lastName: String?
    let addresses: [Address]?
    let phone: String?
    let createdAt: String
    let updatedAt: String
    let deletedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, email, addresses, phone
        case defaultBillingAddressId = "default_billing_address_id"
        case defaultShippingAddressId = "default_shipping_address_id"
        case companyName = "company_name"
        case firstName = "first_name"
        case lastName = "last_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}

// Step 1: Auth Registration Payload
struct AuthRegisterPayload: Codable {
    let firstName: String
    let lastName: String
    let email: String
    let password: String?
    let phone: String
    
    enum CodingKeys: String, CodingKey {
        case email, password, phone
        case firstName = "first_name"
        case lastName = "last_name"
    }
}

// Step 2: Customer Creation Payload (using JWT token)
struct CustomerCreationPayload: Codable {
    let email: String
    let firstName: String
    let lastName: String
    let phone: String
    
    enum CodingKeys: String, CodingKey {
        case email, phone
        case firstName = "first_name"
        case lastName = "last_name"
    }
}

// Step 3: Login Payload
struct CustomerLoginRequest: Codable {
    let email: String
    let password: String
}

struct CustomerUpdateRequest: Codable {
    let email: String?
    let firstName: String?
    let lastName: String?
    let phone: String?
    let companyName: String?
    
    enum CodingKeys: String, CodingKey {
        case email, phone
        case firstName = "first_name"
        case lastName = "last_name"
        case companyName = "company_name"
    }
}

// Auth Response (contains JWT token)
struct AuthRegisterResponse: Codable {
    let token: String
}

// Customer Response
struct CustomerResponse: Codable {
    let customer: Customer
}

// Simplified Login Response - handles different possible response structures
struct LoginResponse: Codable {
    let customer: Customer?
    let token: String?
    
    // Custom decoder to handle different response structures
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try to decode token first
        self.token = try? container.decodeIfPresent(String.self, forKey: .token)
        
        // Try to decode customer from "customer" key first
        if let customerData = try? container.decodeIfPresent(Customer.self, forKey: .customer) {
            self.customer = customerData
        } else {
            // If that fails, try to decode the entire response as a Customer
            self.customer = try? Customer(from: decoder)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case customer, token
    }
}

// Alternative response structure for cases where customer is at root level
struct DirectCustomerResponse: Codable {
    let id: String
    let email: String
    let defaultBillingAddressId: String?
    let defaultShippingAddressId: String?
    let companyName: String?
    let firstName: String?
    let lastName: String?
    let addresses: [Address]?
    let phone: String?
    let createdAt: String
    let updatedAt: String
    let deletedAt: String?
    let token: String?
    
    enum CodingKeys: String, CodingKey {
        case id, email, addresses, phone, token
        case defaultBillingAddressId = "default_billing_address_id"
        case defaultShippingAddressId = "default_shipping_address_id"
        case companyName = "company_name"
        case firstName = "first_name"
        case lastName = "last_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
    
    // Convert to Customer
    var asCustomer: Customer {
        return Customer(
            id: id,
            email: email,
            defaultBillingAddressId: defaultBillingAddressId,
            defaultShippingAddressId: defaultShippingAddressId,
            companyName: companyName,
            firstName: firstName,
            lastName: lastName,
            addresses: addresses,
            phone: phone,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt
        )
    }
}