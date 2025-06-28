//
//  Address.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 28/06/2025.
//

import Foundation

struct Address: Codable, Identifiable {
    let id: String
    let addressName: String?
    let isDefaultShipping: Bool
    let isDefaultBilling: Bool
    let customerId: String
    let company: String?
    let firstName: String?
    let lastName: String?
    let address1: String
    let address2: String?
    let city: String
    let countryCode: String
    let province: String?
    let postalCode: String
    let phone: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, company, city, phone
        case addressName = "address_name"
        case isDefaultShipping = "is_default_shipping"
        case isDefaultBilling = "is_default_billing"
        case customerId = "customer_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case address1 = "address_1"
        case address2 = "address_2"
        case countryCode = "country_code"
        case province
        case postalCode = "postal_code"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct AddressRequest: Codable {
    let addressName: String?
    let isDefaultShipping: Bool?
    let isDefaultBilling: Bool?
    let company: String?
    let firstName: String?
    let lastName: String?
    let address1: String
    let address2: String?
    let city: String
    let countryCode: String
    let province: String?
    let postalCode: String
    let phone: String?
    
    enum CodingKeys: String, CodingKey {
        case company, city, phone, province
        case addressName = "address_name"
        case isDefaultShipping = "is_default_shipping"
        case isDefaultBilling = "is_default_billing"
        case firstName = "first_name"
        case lastName = "last_name"
        case address1 = "address_1"
        case address2 = "address_2"
        case countryCode = "country_code"
        case postalCode = "postal_code"
    }
}

struct AddressResponse: Codable {
    let address: Address
}