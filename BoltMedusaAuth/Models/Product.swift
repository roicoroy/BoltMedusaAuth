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
    let status: ProductStatus
    let images: [ProductImage]?
    let thumbnail: String?
    let options: [ProductOption]?
    let variants: [ProductVariant]?
    let categories: [ProductCategory]?
    let collection: ProductCollection?
    let collectionId: String?
    let type: ProductType?
    let typeId: String?
    let tags: [ProductTag]?
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
    let metadata: [String: AnyCodable]?
    
    enum CodingKeys: String, CodingKey {
        case id, title, subtitle, description, handle, images, thumbnail, options, variants, categories, collection, type, tags, weight, length, height, width, material, discountable, metadata
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
        status = try container.decode(ProductStatus.self, forKey: .status)
        images = try container.decodeIfPresent([ProductImage].self, forKey: .images)
        thumbnail = try container.decodeIfPresent(String.self, forKey: .thumbnail)
        options = try container.decodeIfPresent([ProductOption].self, forKey: .options)
        variants = try container.decodeIfPresent([ProductVariant].self, forKey: .variants)
        categories = try container.decodeIfPresent([ProductCategory].self, forKey: .categories)
        collection = try container.decodeIfPresent(ProductCollection.self, forKey: .collection)
        collectionId = try container.decodeIfPresent(String.self, forKey: .collectionId)
        type = try container.decodeIfPresent(ProductType.self, forKey: .type)
        typeId = try container.decodeIfPresent(String.self, forKey: .typeId)
        tags = try container.decodeIfPresent([ProductTag].self, forKey: .tags)
        hsCode = try container.decodeIfPresent(String.self, forKey: .hsCode)
        originCountry = try container.decodeIfPresent(String.self, forKey: .originCountry)
        midCode = try container.decodeIfPresent(String.self, forKey: .midCode)
        material = try container.decodeIfPresent(String.self, forKey: .material)
        discountable = try container.decodeIfPresent(Bool.self, forKey: .discountable)
        externalId = try container.decodeIfPresent(String.self, forKey: .externalId)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        deletedAt = try container.decodeIfPresent(String.self, forKey: .deletedAt)
        metadata = try container.decodeIfPresent([String: AnyCodable].self, forKey: .metadata)
        
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
    let metadata: [String: AnyCodable]?
    let createdAt: String
    let updatedAt: String
    let deletedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, url, rank, metadata
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
    
    // Custom decoder to handle flexible rank type
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        url = try container.decode(String.self, forKey: .url)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        deletedAt = try container.decodeIfPresent(String.self, forKey: .deletedAt)
        metadata = try container.decodeIfPresent([String: AnyCodable].self, forKey: .metadata)
        
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
    let createdAt: String
    let updatedAt: String
    let deletedAt: String?
    let metadata: [String: AnyCodable]?
    
    enum CodingKeys: String, CodingKey {
        case id, title, values, metadata
        case productId = "product_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}

struct ProductOptionValue: Codable, Identifiable {
    let id: String
    let value: String
    let optionId: String
    let createdAt: String
    let updatedAt: String
    let deletedAt: String?
    let metadata: [String: AnyCodable]?
    
    enum CodingKeys: String, CodingKey {
        case id, value, metadata
        case optionId = "option_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}

struct ProductVariant: Codable, Identifiable {
    let id: String
    let title: String
    let productId: String
    let sku: String?
    let barcode: String?
    let ean: String?
    let upc: String?
    let variantRank: Int?
    let inventoryQuantity: Int?
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
    let calculatedPrice: CalculatedPrice?
    let createdAt: String
    let updatedAt: String
    let deletedAt: String?
    let metadata: [String: AnyCodable]?
    
    enum CodingKeys: String, CodingKey {
        case id, title, sku, barcode, ean, upc, material, options, metadata
        case productId = "product_id"
        case variantRank = "variant_rank"
        case inventoryQuantity = "inventory_quantity"
        case allowBackorder = "allow_backorder"
        case manageInventory = "manage_inventory"
        case hsCode = "hs_code"
        case originCountry = "origin_country"
        case midCode = "mid_code"
        case calculatedPrice = "calculated_price"
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
        productId = try container.decode(String.self, forKey: .productId)
        sku = try container.decodeIfPresent(String.self, forKey: .sku)
        barcode = try container.decodeIfPresent(String.self, forKey: .barcode)
        ean = try container.decodeIfPresent(String.self, forKey: .ean)
        upc = try container.decodeIfPresent(String.self, forKey: .upc)
        hsCode = try container.decodeIfPresent(String.self, forKey: .hsCode)
        originCountry = try container.decodeIfPresent(String.self, forKey: .originCountry)
        midCode = try container.decodeIfPresent(String.self, forKey: .midCode)
        material = try container.decodeIfPresent(String.self, forKey: .material)
        options = try container.decodeIfPresent([ProductOptionValue].self, forKey: .options)
        calculatedPrice = try container.decodeIfPresent(CalculatedPrice.self, forKey: .calculatedPrice)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        deletedAt = try container.decodeIfPresent(String.self, forKey: .deletedAt)
        metadata = try container.decodeIfPresent([String: AnyCodable].self, forKey: .metadata)
        
        // Handle flexible numeric types
        variantRank = Self.decodeFlexibleInt(from: container, forKey: .variantRank)
        inventoryQuantity = Self.decodeFlexibleInt(from: container, forKey: .inventoryQuantity)
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

struct CalculatedPrice: Codable, Identifiable {
    let id: String
    let isCalculatedPricePriceList: Bool
    let isCalculatedPriceTaxInclusive: Bool
    let calculatedAmount: Int
    let calculatedAmountWithTax: Int
    let calculatedAmountWithoutTax: Int
    let isOriginalPricePriceList: Bool
    let isOriginalPriceTaxInclusive: Bool
    let originalAmount: Int
    let originalAmountWithTax: Int
    let originalAmountWithoutTax: Int
    let currencyCode: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case isCalculatedPricePriceList = "is_calculated_price_price_list"
        case isCalculatedPriceTaxInclusive = "is_calculated_price_tax_inclusive"
        case calculatedAmount = "calculated_amount"
        case calculatedAmountWithTax = "calculated_amount_with_tax"
        case calculatedAmountWithoutTax = "calculated_amount_without_tax"
        case isOriginalPricePriceList = "is_original_price_price_list"
        case isOriginalPriceTaxInclusive = "is_original_price_tax_inclusive"
        case originalAmount = "original_amount"
        case originalAmountWithTax = "original_amount_with_tax"
        case originalAmountWithoutTax = "original_amount_without_tax"
        case currencyCode = "currency_code"
    }
    
    // Custom decoder to handle flexible numeric types
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        isCalculatedPricePriceList = try container.decode(Bool.self, forKey: .isCalculatedPricePriceList)
        isCalculatedPriceTaxInclusive = try container.decode(Bool.self, forKey: .isCalculatedPriceTaxInclusive)
        isOriginalPricePriceList = try container.decode(Bool.self, forKey: .isOriginalPricePriceList)
        isOriginalPriceTaxInclusive = try container.decode(Bool.self, forKey: .isOriginalPriceTaxInclusive)
        currencyCode = try container.decode(String.self, forKey: .currencyCode)
        
        // Handle flexible numeric types for amounts
        calculatedAmount = Self.decodeFlexibleInt(from: container, forKey: .calculatedAmount) ?? 0
        calculatedAmountWithTax = Self.decodeFlexibleInt(from: container, forKey: .calculatedAmountWithTax) ?? 0
        calculatedAmountWithoutTax = Self.decodeFlexibleInt(from: container, forKey: .calculatedAmountWithoutTax) ?? 0
        originalAmount = Self.decodeFlexibleInt(from: container, forKey: .originalAmount) ?? 0
        originalAmountWithTax = Self.decodeFlexibleInt(from: container, forKey: .originalAmountWithTax) ?? 0
        originalAmountWithoutTax = Self.decodeFlexibleInt(from: container, forKey: .originalAmountWithoutTax) ?? 0
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

// MARK: - Fixed Product Category Model (removed circular references)
struct ProductCategory: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let handle: String?
    let rank: Int?
    let parentCategoryId: String?
    let createdAt: String
    let updatedAt: String
    let deletedAt: String?
    let metadata: [String: AnyCodable]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, handle, rank, metadata
        case parentCategoryId = "parent_category_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
    
    // Custom decoder to handle the API response structure and flexible types
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        handle = try container.decodeIfPresent(String.self, forKey: .handle)
        parentCategoryId = try container.decodeIfPresent(String.self, forKey: .parentCategoryId)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        deletedAt = try container.decodeIfPresent(String.self, forKey: .deletedAt)
        metadata = try container.decodeIfPresent([String: AnyCodable].self, forKey: .metadata)
        
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

struct ProductCollection: Codable, Identifiable {
    let id: String
    let title: String
    let handle: String?
    let createdAt: String
    let updatedAt: String
    let deletedAt: String?
    let metadata: [String: AnyCodable]?
    
    enum CodingKeys: String, CodingKey {
        case id, title, handle, metadata
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}

struct ProductType: Codable, Identifiable {
    let id: String
    let value: String
    let createdAt: String
    let updatedAt: String
    let deletedAt: String?
    let metadata: [String: AnyCodable]?
    
    enum CodingKeys: String, CodingKey {
        case id, value, metadata
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}

struct ProductTag: Codable, Identifiable {
    let id: String
    let value: String
    let createdAt: String
    let updatedAt: String
    let deletedAt: String?
    let metadata: [String: AnyCodable]?
    
    enum CodingKeys: String, CodingKey {
        case id, value, metadata
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}

// MARK: - Helper for dynamic metadata
struct AnyCodable: Codable {
    let value: Any
    
    init<T>(_ value: T?) {
        self.value = value ?? ()
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self.value = ()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case is Void:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded")
            throw EncodingError.invalidValue(value, context)
        }
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

struct CategoriesResponse: Codable {
    let productCategories: [ProductCategory]
    let count: Int
    let offset: Int
    let limit: Int
    
    enum CodingKeys: String, CodingKey {
        case count, offset, limit
        case productCategories = "product_categories"
    }
}

struct CategoryResponse: Codable {
    let productCategory: ProductCategory
    
    enum CodingKeys: String, CodingKey {
        case productCategory = "product_category"
    }
}

// MARK: - Helper Extensions
extension Product {
    var displayPrice: String {
        guard let variant = variants?.first,
              let calculatedPrice = variant.calculatedPrice else {
            return "Price not available"
        }
        
        let amount = Double(calculatedPrice.calculatedAmount) / 100.0
        return String(format: "%.2f %@", amount, calculatedPrice.currencyCode.uppercased())
    }
    
    var displayImage: String? {
        return thumbnail ?? images?.first?.url
    }
    
    var isAvailable: Bool {
        guard let variant = variants?.first else { return false }
        return (variant.inventoryQuantity ?? 0) > 0 || (variant.allowBackorder ?? false)
    }
    
    var categoryNames: [String] {
        return categories?.map { $0.name } ?? []
    }
    
    var tagValues: [String] {
        return tags?.map { $0.value } ?? []
    }
}

extension ProductVariant {
    var displayPrice: String {
        guard let calculatedPrice = calculatedPrice else {
            return "Price not available"
        }
        
        let amount = Double(calculatedPrice.calculatedAmount) / 100.0
        return String(format: "%.2f %@", amount, calculatedPrice.currencyCode.uppercased())
    }
    
    var isInStock: Bool {
        return (inventoryQuantity ?? 0) > 0
    }
    
    var stockStatus: String {
        let quantity = inventoryQuantity ?? 0
        if quantity > 0 {
            return "\(quantity) in stock"
        } else if allowBackorder == true {
            return "Backorder available"
        } else {
            return "Out of stock"
        }
    }
    
    var stockStatusColor: Color {
        let quantity = inventoryQuantity ?? 0
        if quantity > 0 {
            return .green
        } else if allowBackorder == true {
            return .orange
        } else {
            return .red
        }
    }
}

extension ProductImage {
    var displayUrl: String {
        return url
    }
}

extension ProductCategory {
    var hasChildren: Bool {
        // This will need to be determined at the service level
        // by checking if any other categories have this category as parent
        return false
    }
    
    var productCount: Int {
        // This will need to be calculated at the service level
        // by counting products that belong to this category
        return 0
    }
    
    var displayName: String {
        return name
    }
    
    var isTopLevel: Bool {
        return parentCategoryId == nil
    }
}