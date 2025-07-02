
//
//  Product.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 28/06/2025.
//

import Foundation
import SwiftUI

// MARK: - Product Models
public struct Product: Codable, Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let description: String?
    public let handle: String?
    public let isGiftcard: Bool
    public let status: ProductStatus?
    public let images: [ProductImage]?
    public let thumbnail: String?
    public let options: [ProductOption]?
    public let variants: [ProductVariant]?
    public let collection: ProductCollection?
    public let collectionId: String?
    public let type: ProductType?
    public let typeId: String?
    public let weight: Int?
    public let length: Int?
    public let height: Int?
    public let width: Int?
    public let hsCode: String?
    public let originCountry: String?
    public let midCode: String?
    public let material: String?
    public let discountable: Bool?
    public let externalId: String?
    public let createdAt: String
    public let updatedAt: String
    public let deletedAt: String?
    public let metadata: [String: AnyCodable]?
    public let tags: [ProductTag]?
    public let salesChannels: [ProductSalesChannel]?
    
    public enum CodingKeys: String, CodingKey {
        case id, title, subtitle, description, handle, images, thumbnail, options, variants, collection, type, weight, length, height, width, material, discountable, metadata, tags, salesChannels
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
    
    public init(from decoder: Decoder) throws {
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
        tags = try container.decodeIfPresent([ProductTag].self, forKey: .tags)
        salesChannels = try container.decodeIfPresent([ProductSalesChannel].self, forKey: .salesChannels)
        
        // Handle flexible numeric types (can be string or int)
        weight = Self.decodeFlexibleInt(from: container, forKey: .weight)
        length = Self.decodeFlexibleInt(from: container, forKey: .length)
        height = Self.decodeFlexibleInt(from: container, forKey: .height)
        width = Self.decodeFlexibleInt(from: container, forKey: .width)

        if container.contains(.metadata) {
            if let metadataDict = try? container.decode([String: AnyCodable].self, forKey: .metadata) {
                metadata = metadataDict
            } else {
                metadata = nil
            }
        } else {
            metadata = nil
        }
    }
    
    private static func decodeFlexibleInt(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) -> Int? {
        if let intValue = try? container.decodeIfPresent(Int.self, forKey: key) {
            return intValue
        }
        if let stringValue = try? container.decodeIfPresent(String.self, forKey: key) {
            return Int(stringValue)
        }
        return nil
    }
}

public enum ProductStatus: String, Codable {
    case draft = "draft"
    case proposed = "proposed"
    case published = "published"
    case rejected = "rejected"
}

public struct ProductImage: Codable, Identifiable {
    public let id: String
    public let url: String
    public let rank: Int?
    public let createdAt: String?
    public let updatedAt: String?
    public let deletedAt: String?
    public let metadata: [String: AnyCodable]?
    
    public enum CodingKeys: String, CodingKey {
        case id, url, rank, metadata
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        url = try container.decode(String.self, forKey: .url)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        deletedAt = try container.decodeIfPresent(String.self, forKey: .deletedAt)
        
        if let intValue = try? container.decodeIfPresent(Int.self, forKey: .rank) {
            rank = intValue
        } else if let stringValue = try? container.decodeIfPresent(String.self, forKey: .rank) {
            rank = Int(stringValue)
        } else {
            rank = nil
        }

        if container.contains(.metadata) {
            if let metadataDict = try? container.decode([String: AnyCodable].self, forKey: .metadata) {
                metadata = metadataDict
            } else {
                metadata = nil
            }
        } else {
            metadata = nil
        }
    }
}

public struct ProductOption: Codable, Identifiable {
    public let id: String
    public let title: String
    public let values: [ProductOptionValue]?
    public let productId: String?
    public let createdAt: String?
    public let updatedAt: String?
    public let deletedAt: String?
    public let metadata: [String: AnyCodable]?
    
    public enum CodingKeys: String, CodingKey {
        case id, title, values, metadata
        case productId = "product_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        values = try container.decodeIfPresent([ProductOptionValue].self, forKey: .values)
        productId = try container.decodeIfPresent(String.self, forKey: .productId)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        deletedAt = try container.decodeIfPresent(String.self, forKey: .deletedAt)

        if container.contains(.metadata) {
            if let metadataDict = try? container.decode([String: AnyCodable].self, forKey: .metadata) {
                metadata = metadataDict
            } else {
                metadata = nil
            }
        } else {
            metadata = nil
        }
    }
}

public struct ProductOptionValue: Codable, Identifiable {
    public let id: String
    public let value: String
    public let optionId: String?
    public let variantId: String?
    public let createdAt: String?
    public let updatedAt: String?
    public let deletedAt: String?
    public let metadata: [String: AnyCodable]?
    
    public enum CodingKeys: String, CodingKey {
        case id, value, metadata
        case optionId = "option_id"
        case variantId = "variant_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        value = try container.decode(String.self, forKey: .value)
        optionId = try container.decodeIfPresent(String.self, forKey: .optionId)
        variantId = try container.decodeIfPresent(String.self, forKey: .variantId)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        deletedAt = try container.decodeIfPresent(String.self, forKey: .deletedAt)

        if container.contains(.metadata) {
            if let metadataDict = try? container.decode([String: AnyCodable].self, forKey: .metadata) {
                metadata = metadataDict
            } else {
                metadata = nil
            }
        } else {
            metadata = nil
        }
    }
}

public struct ProductVariant: Codable, Identifiable {
    public let id: String
    public let title: String
    public let productId: String?
    public let sku: String?
    public let barcode: String?
    public let ean: String?
    public let upc: String?
    public let inventoryQuantity: Int
    public let allowBackorder: Bool
    public let manageInventory: Bool
    public let hsCode: String?
    public let originCountry: String?
    public let midCode: String?
    public let material: String?
    public let weight: Int?
    public let length: Int?
    public let height: Int?
    public let width: Int?
    public let options: [ProductOptionValue]?
    public let prices: [ProductVariantPrice]?
    public let createdAt: String
    public let updatedAt: String
    public let deletedAt: String?
    public let metadata: [String: AnyCodable]?
    
    public enum CodingKeys: String, CodingKey {
        case id, title, sku, barcode, ean, upc, inventoryQuantity, allowBackorder, manageInventory, material, weight, length, height, width, options, prices, metadata
        case productId = "product_id"
        case hsCode = "hs_code"
        case originCountry = "origin_country"
        case midCode = "mid_code"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        productId = try container.decodeIfPresent(String.self, forKey: .productId)
        sku = try container.decodeIfPresent(String.self, forKey: .sku)
        barcode = try container.decodeIfPresent(String.self, forKey: .barcode)
        ean = try container.decodeIfPresent(String.self, forKey: .ean)
        upc = try container.decodeIfPresent(String.self, forKey: .upc)
        
        inventoryQuantity = try Self.decodeFlexibleInt(from: container, forKey: .inventoryQuantity) ?? 0
        
        allowBackorder = try Self.decodeFlexibleBool(from: container, forKey: .allowBackorder) ?? false
        manageInventory = try Self.decodeFlexibleBool(from: container, forKey: .manageInventory) ?? false
        
        hsCode = try container.decodeIfPresent(String.self, forKey: .hsCode)
        originCountry = try container.decodeIfPresent(String.self, forKey: .originCountry)
        midCode = try container.decodeIfPresent(String.self, forKey: .midCode)
        material = try container.decodeIfPresent(String.self, forKey: .material)
        
        weight = Self.decodeFlexibleInt(from: container, forKey: .weight)
        length = Self.decodeFlexibleInt(from: container, forKey: .length)
        height = Self.decodeFlexibleInt(from: container, forKey: .height)
        width = Self.decodeFlexibleInt(from: container, forKey: .width)
        
        options = try container.decodeIfPresent([ProductOptionValue].self, forKey: .options)
        prices = try container.decodeIfPresent([ProductVariantPrice].self, forKey: .prices)
        
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        deletedAt = try container.decodeIfPresent(String.self, forKey: .deletedAt)

        if container.contains(.metadata) {
            if let metadataDict = try? container.decode([String: AnyCodable].self, forKey: .metadata) {
                metadata = metadataDict
            } else {
                metadata = nil
            }
        } else {
            metadata = nil
        }
    }
    
    private static func decodeFlexibleInt(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) -> Int? {
        if let intValue = try? container.decodeIfPresent(Int.self, forKey: key) {
            return intValue
        }
        if let stringValue = try? container.decodeIfPresent(String.self, forKey: key) {
            return Int(stringValue)
        }
        return nil
    }
    
    private static func decodeFlexibleBool(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) -> Bool? {
        if let boolValue = try? container.decodeIfPresent(Bool.self, forKey: key) {
            return boolValue
        }
        if let stringValue = try? container.decodeIfPresent(String.self, forKey: key) {
            return stringValue.lowercased() == "true" || stringValue == "1"
        }
        if let intValue = try? container.decodeIfPresent(Int.self, forKey: key) {
            return intValue != 0
        }
        return nil
    }
}

public struct ProductVariantPrice: Codable, Identifiable {
    public let id: String
    public let currencyCode: String?
    public let amount: Int
    public let variantId: String
    public let regionId: String?
    public let createdAt: String
    public let updatedAt: String
    public let deletedAt: String?
    public let metadata: [String: AnyCodable]?
    
    public enum CodingKeys: String, CodingKey {
        case id, amount, metadata
        case currencyCode = "currency_code"
        case variantId = "variant_id"
        case regionId = "region_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        currencyCode = try container.decodeIfPresent(String.self, forKey: .currencyCode)
        amount = try container.decode(Int.self, forKey: .amount)
        variantId = try container.decode(String.self, forKey: .variantId)
        regionId = try container.decodeIfPresent(String.self, forKey: .regionId)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        deletedAt = try container.decodeIfPresent(String.self, forKey: .deletedAt)

        if container.contains(.metadata) {
            if let metadataDict = try? container.decode([String: AnyCodable].self, forKey: .metadata) {
                metadata = metadataDict
            } else {
                metadata = nil
            }
        } else {
            metadata = nil
        }
    }
}

public struct ProductCollection: Codable, Identifiable {
    public let id: String
    public let title: String
    public let handle: String?
    public let createdAt: String?
    public let updatedAt: String?
    public let deletedAt: String?
    public let metadata: [String: AnyCodable]?
    
    public enum CodingKeys: String, CodingKey {
        case id, title, handle, metadata
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        handle = try container.decodeIfPresent(String.self, forKey: .handle)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        deletedAt = try container.decodeIfPresent(String.self, forKey: .deletedAt)

        if container.contains(.metadata) {
            if let metadataDict = try? container.decode([String: AnyCodable].self, forKey: .metadata) {
                metadata = metadataDict
            } else {
                metadata = nil
            }
        } else {
            metadata = nil
        }
    }
}

public struct ProductType: Codable, Identifiable {
    public let id: String
    public let value: String
    public let createdAt: String?
    public let updatedAt: String?
    public let deletedAt: String?
    public let metadata: [String: AnyCodable]?
    
    public enum CodingKeys: String, CodingKey {
        case id, value, metadata
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        value = try container.decode(String.self, forKey: .value)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        deletedAt = try container.decodeIfPresent(String.self, forKey: .deletedAt)

        if container.contains(.metadata) {
            if let metadataDict = try? container.decode([String: AnyCodable].self, forKey: .metadata) {
                metadata = metadataDict
            } else {
                metadata = nil
            }
        } else {
            metadata = nil
        }
    }
}

public struct ProductTag: Codable, Identifiable {
    public let id: String
    public let value: String
    public let createdAt: String
    public let updatedAt: String
    public let deletedAt: String?
    public let metadata: [String: AnyCodable]?

    public enum CodingKeys: String, CodingKey {
        case id, value, metadata
        case createdAt = "created_at"
        case updatedAt = "updated_ات"
        case deletedAt = "deleted_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        value = try container.decode(String.self, forKey: .value)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        deletedAt = try container.decodeIfPresent(String.self, forKey: .deletedAt)

        if container.contains(.metadata) {
            if let metadataDict = try? container.decode([String: AnyCodable].self, forKey: .metadata) {
                metadata = metadataDict
            } else {
                metadata = nil
            }
        } else {
            metadata = nil
        }
    }
}

public struct ProductSalesChannel: Codable, Identifiable {
    public let id: String
    public let name: String
    public let description: String?
    public let createdAt: String
    public let updatedAt: String
    public let deletedAt: String?
    public let metadata: [String: AnyCodable]?

    public enum CodingKeys: String, CodingKey {
        case id, name, description, metadata
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        deletedAt = try container.decodeIfPresent(String.self, forKey: .deletedAt)

        if container.contains(.metadata) {
            if let metadataDict = try? container.decode([String: AnyCodable].self, forKey: .metadata) {
                metadata = metadataDict
            } else {
                metadata = nil
            }
        } else {
            metadata = nil
        }
    }
}

// MARK: - API Response Models
public struct ProductsResponse: Codable {
    public let products: [Product]
    public let count: Int
    public let offset: Int
    public let limit: Int
}

public struct ProductResponse: Codable {
    public let product: Product
}

// MARK: - Helper Extensions
extension Product {
    public func displayPrice(currencyCode: String) -> String {
        guard let variant = variants?.first,
              let price = variant.prices?.first(where: { $0.currencyCode?.lowercased() == currencyCode.lowercased() }) else {
            return "N/A"
        }
        return formatPrice(price.amount, currencyCode: currencyCode)
    }
    
    public var displayImage: String? {
        return thumbnail ?? images?.first?.url
    }
    
    public var isAvailable: Bool {
        return variants?.contains(where: { $0.inventoryQuantity > 0 }) ?? false
    }
    
    public var displayStatus: String {
        return status?.rawValue.capitalized ?? "Unknown"
    }
}

extension ProductVariant {
    public func displayPrice(currencyCode: String) -> String {
        guard let price = prices?.first(where: { $0.currencyCode?.lowercased() == currencyCode.lowercased() }) else {
            return "N/A"
        }
        return formatPrice(price.amount, currencyCode: currencyCode)
    }
    
    public var isInStock: Bool {
        return inventoryQuantity > 0
    }
    
    public var stockStatus: String {
        if isInStock {
            return "In Stock"
        } else if allowBackorder {
            return "Available for Backorder"
        } else {
            return "Out of Stock"
        }
    }
    
    public var stockStatusColor: Color {
        if isInStock {
            return .green
        } else if allowBackorder {
            return .orange
        } else {
            return .red
        }
    }
}

extension ProductImage {
    public var displayUrl: String {
        return url
    }
}
