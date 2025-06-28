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
    let profileId: String
    let weight: Int?
    let length: Int?
    let height: Int?
    let width: Int?
    let hsCode: String?
    let originCountry: String?
    let midCode: String?
    let material: String?
    let createdAt: String
    let updatedAt: String
    let deletedAt: String?
    let metadata: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case id, title, subtitle, description, handle, images, thumbnail, options, variants, categories, weight, length, height, width, material, metadata
        case isGiftcard = "is_giftcard"
        case status
        case profileId = "profile_id"
        case hsCode = "hs_code"
        case originCountry = "origin_country"
        case midCode = "mid_code"
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
    let metadata: [String: String]?
    let createdAt: String
    let updatedAt: String
    let deletedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, url, metadata
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}

struct ProductOption: Codable, Identifiable {
    let id: String
    let title: String
    let values: [ProductOptionValue]?
    let productId: String
    let createdAt: String
    let updatedAt: String
    let deletedAt: String?
    let metadata: [String: String]?
    
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
    let variantId: String
    let createdAt: String
    let updatedAt: String
    let deletedAt: String?
    let metadata: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case id, value, metadata
        case optionId = "option_id"
        case variantId = "variant_id"
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
    let prices: [MoneyAmount]?
    let createdAt: String
    let updatedAt: String
    let deletedAt: String?
    let metadata: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case id, title, sku, barcode, ean, upc, weight, length, height, width, material, options, prices, metadata
        case productId = "product_id"
        case variantRank = "variant_rank"
        case inventoryQuantity = "inventory_quantity"
        case allowBackorder = "allow_backorder"
        case manageInventory = "manage_inventory"
        case hsCode = "hs_code"
        case originCountry = "origin_country"
        case midCode = "mid_code"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}

struct MoneyAmount: Codable, Identifiable {
    let id: String
    let currencyCode: String
    let amount: Int
    let minQuantity: Int?
    let maxQuantity: Int?
    let priceListId: String?
    let variantId: String?
    let regionId: String?
    let createdAt: String
    let updatedAt: String
    let deletedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, amount
        case currencyCode = "currency_code"
        case minQuantity = "min_quantity"
        case maxQuantity = "max_quantity"
        case priceListId = "price_list_id"
        case variantId = "variant_id"
        case regionId = "region_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}

struct ProductCategory: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let handle: String?
    let isActive: Bool
    let isInternal: Bool
    let parentCategoryId: String?
    let categoryChildren: [ProductCategory]?
    let rank: Int?
    let createdAt: String
    let updatedAt: String
    let deletedAt: String?
    let metadata: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, handle, rank, metadata
        case isActive = "is_active"
        case isInternal = "is_internal"
        case parentCategoryId = "parent_category_id"
        case categoryChildren = "category_children"
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

// MARK: - Helper Extensions
extension Product {
    var displayPrice: String {
        guard let variant = variants?.first,
              let price = variant.prices?.first else {
            return "Price not available"
        }
        
        let amount = Double(price.amount) / 100.0
        return String(format: "%.2f %@", amount, price.currencyCode.uppercased())
    }
    
    var displayImage: String? {
        return thumbnail ?? images?.first?.url
    }
    
    var isAvailable: Bool {
        guard let variant = variants?.first else { return false }
        return variant.inventoryQuantity > 0 || variant.allowBackorder
    }
}

extension ProductVariant {
    var displayPrice: String {
        guard let price = prices?.first else {
            return "Price not available"
        }
        
        let amount = Double(price.amount) / 100.0
        return String(format: "%.2f %@", amount, price.currencyCode.uppercased())
    }
}