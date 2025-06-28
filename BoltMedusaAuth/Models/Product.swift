//
//  Product.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 28/06/2025.
//

import Foundation
import SwiftUI

// MARK: - Product Models
struct Product: Codable, Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let description: String?
    let handle: String?
    let isGiftcard: Bool
    let status: ProductStatus?
    let images: [ProductImage]?
    let thumbnail: String?
    let options: [ProductOption]?
    let variants: [ProductVariant]?
    let collection: ProductCollection?
    let collectionId: String?
    let type: ProductType?
    let typeId: String?
    let weight: Int?
    let length: Int?
    let height: Int?
    let width: Int?
    let hsCode: String?
    let originCountry: String?
    let midCode: String?
    let material: String?
    let discountable: Bool?
    let externalId: String?
    let createdAt: String
    let updatedAt: String
    let deletedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, subtitle, description, handle, images, thumbnail, options, variants, collection, type, weight, length, height, width, material, discountable
        case isGiftcard = "is_giftcard"
        case status
        case collectionId = "collection_id"
        case typeId = "type_id"
        case hsCode = "hs_code"
        case originCountry = "origin_country"
        case midCode = "mid_code"
        case externalId = "external_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
    
    // Custom decoder to handle flexible numeric types
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        handle = try container.decodeIfPresent(String.self, forKey: .handle)
        isGiftcard = try container.decode(Bool.self, forKey: .isGiftcard)
        status = try container.decodeIfPresent(ProductStatus.self, forKey: .status)
        images = try container.decodeIfPresent([ProductImage].self, forKey: .images)
        thumbnail = try container.decodeIfPresent(String.self, forKey: .thumbnail)
        options = try container.decodeIfPresent([ProductOption].self, forKey: .options)
        variants = try container.decodeIfPresent([ProductVariant].self, forKey: .variants)
        collection = try container.decodeIfPresent(ProductCollection.self, forKey: .collection)
        collectionId = try container.decodeIfPresent(String.self, forKey: .collectionId)
        type = try container.decodeIfPresent(ProductType.self, forKey: .type)
        typeId = try container.decodeIfPresent(String.self, forKey: .typeId)
        hsCode = try container.decodeIfPresent(String.self, forKey: .hsCode)
        originCountry = try container.decodeIfPresent(String.self, forKey: .originCountry)
        midCode = try container.decodeIfPresent(String.self, forKey: .midCode)
        material = try container.decodeIfPresent(String.self, forKey: .material)
        discountable = try container.decodeIfPresent(Bool.self, forKey: .discountable)
        externalId = try container.decodeIfPresent(String.self, forKey: .externalId)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        deletedAt = try container.decodeIfPresent(String.self, forKey: .deletedAt)
        
        // Handle flexible numeric types (can be string or int)
        weight = Self.decodeFlexibleInt(from: container, forKey: .weight)
        length = Self.decodeFlexibleInt(from: container, forKey: .length)
        height = Self.decodeFlexibleInt(from: container, forKey: .height)
        width = Self.decodeFlexibleInt(from: container, forKey: .width)
    }
    
    private static func decodeFlexibleInt(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) -> Int? {
        // Try to decode as Int first
        if let intValue = try? container.decodeIfPresent(Int.self, forKey: key) {
            return intValue
        }
        // If that fails, try to decode as String and convert
        if let stringValue = try? container.decodeIfPresent(String.self, forKey: key) {
            return Int(stringValue)
        }
        // If both fail, return nil
        return nil
    }
}

enum ProductStatus: String, Codable {
    case draft = "draft"
    case proposed = "proposed"
    case published = "published"
    case rejected = "rejected"
}

struct ProductImage: Codable, Identifiable {
    let id: String
    let url: String
    let rank: Int?
    let createdAt: String?
    let updatedAt: String?
    let deletedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, url, rank
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
    
    // Custom decoder to handle flexible rank type
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        url = try container.decode(String.self, forKey: .url)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        deletedAt = try container.decodeIfPresent(String.self, forKey: .deletedAt)
        
        // Handle flexible rank type
        if let intValue = try? container.decodeIfPresent(Int.self, forKey: .rank) {
            rank = intValue
        } else if let stringValue = try? container.decodeIfPresent(String.self, forKey: .rank) {
            rank = Int(stringValue)
        } else {
            rank = nil
        }
    }
}

struct ProductOption: Codable, Identifiable {
    let id: String
    let title: String
    let values: [ProductOptionValue]?
    let productId: String?
    let createdAt: String?
    let updatedAt: String?
    let deletedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, values
        case productId = "product_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}

struct ProductOptionValue: Codable, Identifiable {
    let id: String
    let value: String
    let optionId: String?
    let createdAt: String?
    let updatedAt: String?
    let deletedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, value
        case optionId = "option_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}

struct ProductVariant: Codable, Identifiable {
    let id: String
    let title: String
    let productId: String?
    let sku: String?
    let barcode: String?
    let ean: String?
    let upc: String?
    let allowBackorder: Bool?
    let manageInventory: Bool?
    let hsCode: String?
    let originCountry: String?
    let midCode: String?
    let material: String?
    let weight: Int?
    let length: Int?
    let height: Int?
    let width: Int?
    let options: [ProductOptionValue]?
    let createdAt: String
    let updatedAt: String
    let deletedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, sku, barcode, ean, upc, material, options
        case productId = "product_id"
        case allowBackorder = "allow_backorder"
        case manageInventory = "manage_inventory"
        case hsCode = "hs_code"
        case originCountry = "origin_country"
        case midCode = "mid_code"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case weight, length, height, width
    }
    
    // Custom decoder to handle flexible numeric types
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        productId = try container.decodeIfPresent(String.self, forKey: .productId)
        sku = try container.decodeIfPresent(String.self, forKey: .sku)
        barcode = try container.decodeIfPresent(String.self, forKey: .barcode)
        ean = try container.decodeIfPresent(String.self, forKey: .ean)
        upc = try container.decodeIfPresent(String.self, forKey: .upc)
        hsCode = try container.decodeIfPresent(String.self, forKey: .hsCode)
        originCountry = try container.decodeIfPresent(String.self, forKey: .originCountry)
        midCode = try container.decodeIfPresent(String.self, forKey: .midCode)
        material = try container.decodeIfPresent(String.self, forKey: .material)
        options = try container.decodeIfPresent([ProductOptionValue].self, forKey: .options)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        deletedAt = try container.decodeIfPresent(String.self, forKey: .deletedAt)
        
        // Handle flexible numeric types
        weight = Self.decodeFlexibleInt(from: container, forKey: .weight)
        length = Self.decodeFlexibleInt(from: container, forKey: .length)
        height = Self.decodeFlexibleInt(from: container, forKey: .height)
        width = Self.decodeFlexibleInt(from: container, forKey: .width)
        
        // Handle flexible boolean types
        allowBackorder = Self.decodeFlexibleBool(from: container, forKey: .allowBackorder)
        manageInventory = Self.decodeFlexibleBool(from: container, forKey: .manageInventory)
    }
    
    private static func decodeFlexibleInt(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) -> Int? {
        // Try to decode as Int first
        if let intValue = try? container.decodeIfPresent(Int.self, forKey: key) {
            return intValue
        }
        // If that fails, try to decode as String and convert
        if let stringValue = try? container.decodeIfPresent(String.self, forKey: key) {
            return Int(stringValue)
        }
        // If both fail, return nil
        return nil
    }
    
    private static func decodeFlexibleBool(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) -> Bool? {
        // Try to decode as Bool first
        if let boolValue = try? container.decodeIfPresent(Bool.self, forKey: key) {
            return boolValue
        }
        // If that fails, try to decode as String and convert
        if let stringValue = try? container.decodeIfPresent(String.self, forKey: key) {
            return stringValue.lowercased() == "true" || stringValue == "1"
        }
        // If that fails, try to decode as Int and convert
        if let intValue = try? container.decodeIfPresent(Int.self, forKey: key) {
            return intValue != 0
        }
        // If all fail, return nil
        return nil
    }
}

struct ProductCollection: Codable, Identifiable {
    let id: String
    let title: String
    let handle: String?
    let createdAt: String?
    let updatedAt: String?
    let deletedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, handle
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}

struct ProductType: Codable, Identifiable {
    let id: String
    let value: String
    let createdAt: String?
    let updatedAt: String?
    let deletedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, value
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}

// MARK: - API Response Models
struct ProductsResponse: Codable {
    let products: [Product]
    let count: Int
    let offset: Int
    let limit: Int
}

struct ProductResponse: Codable {
    let product: Product
}

// MARK: - Helper Extensions
extension Product {
    func displayPrice(currencyCode: String) -> String {
        // Since we don't have calculated prices in this schema,
        // we'll show a placeholder with the correct currency
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode.uppercased()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        // Return a placeholder price formatted in the correct currency
        return formatter.string(from: NSNumber(value: 0.00)) ?? "\(currencyCode.uppercased()) 0.00"
    }
    
    var displayPrice: String {
        // Default fallback for when currency is not available
        return "Price available on request"
    }
    
    var displayImage: String? {
        return thumbnail ?? images?.first?.url
    }
    
    var isAvailable: Bool {
        // Without inventory quantity, we'll base availability on backorder settings
        guard let variant = variants?.first else { return true }
        return variant.allowBackorder ?? true
    }
    
    var displayStatus: String {
        return status?.rawValue.capitalized ?? "Unknown"
    }
}

extension ProductVariant {
    func displayPrice(currencyCode: String) -> String {
        // Since we don't have calculated prices in this schema,
        // we'll show a placeholder with the correct currency
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode.uppercased()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        // Return a placeholder price formatted in the correct currency
        return formatter.string(from: NSNumber(value: 0.00)) ?? "\(currencyCode.uppercased()) 0.00"
    }
    
    var displayPrice: String {
        // Default fallback for when currency is not available
        return "Price available on request"
    }
    
    var isInStock: Bool {
        // Without inventory quantity, we'll assume in stock if backorder is allowed
        return allowBackorder ?? true
    }
    
    var stockStatus: String {
        if allowBackorder == true {
            return "Available"
        } else if manageInventory == true {
            return "Contact for availability"
        } else {
            return "Available"
        }
    }
    
    var stockStatusColor: Color {
        if allowBackorder == true {
            return .green
        } else if manageInventory == true {
            return .orange
        } else {
            return .green
        }
    }
}

extension ProductImage {
    var displayUrl: String {
        return url
    }
}