//
//  Product.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 28/06/2025.
//

import Foundation

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
    let inventoryQuantity: Int
    let allowBackorder: Bool
    let manageInventory: Bool
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
        case id, title, sku, barcode, ean, upc, weight, length, height, width, material, options, metadata
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
}

// MARK: - Updated Product Category Model (matching your schema exactly)
struct ProductCategory: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let handle: String?
    let rank: Int?
    let parentCategoryId: String?
    let parentCategory: ProductCategory?
    let categoryChildren: [ProductCategory]?
    let products: [Product]?
    let createdAt: String
    let updatedAt: String
    let deletedAt: String?
    let metadata: [String: AnyCodable]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, handle, rank, products, metadata
        case parentCategoryId = "parent_category_id"
        case parentCategory = "parent_category"
        case categoryChildren = "category_children"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
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
        return variant.inventoryQuantity > 0 || variant.allowBackorder
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
        return inventoryQuantity > 0
    }
    
    var stockStatus: String {
        if inventoryQuantory > 0 {
            return "\(inventoryQuantity) in stock"
        } else if allowBackorder {
            return "Backorder available"
        } else {
            return "Out of stock"
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
        return categoryChildren?.isEmpty == false
    }
    
    var productCount: Int {
        return products?.count ?? 0
    }
    
    var displayName: String {
        return name
    }
    
    var isTopLevel: Bool {
        return parentCategoryId == nil
    }
}