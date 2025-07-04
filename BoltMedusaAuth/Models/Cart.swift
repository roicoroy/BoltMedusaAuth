//
//  Cart.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 28/06/2025.
//

import Foundation

// MARK: - Cart Models
public struct Cart: Codable, Identifiable {
    public let id: String
    public let currencyCode: String
    public let customerId: String?
    public let email: String?
    public let regionId: String?
    public let createdAt: String?
    public let updatedAt: String?
    public let completedAt: String?
    public let total: Int
    public let subtotal: Int
    public let taxTotal: Int
    public let discountTotal: Int
    public let discountSubtotal: Int
    public let discountTaxTotal: Int
    public let originalTotal: Int
    public let originalTaxTotal: Int
    public let itemTotal: Int
    public let itemSubtotal: Int
    public let itemTaxTotal: Int
    public let originalItemTotal: Int
    public let originalItemSubtotal: Int
    public let originalItemTaxTotal: Int
    public let shippingTotal: Int
    public let shippingSubtotal: Int
    public let shippingTaxTotal: Int
    public let originalShippingTaxTotal: Int
    public let originalShippingSubtotal: Int
    public let originalShippingTotal: Int
    public let creditLineSubtotal: Int
    public let creditLineTaxTotal: Int
    public let creditLineTotal: Int
    public let metadata: [String: Any]?
    public let salesChannelId: String?
    public let items: [CartLineItem]?
    public let promotions: [CartPromotion]?
    public let region: CartRegion?
    public let shippingAddress: CartAddress?
    public let billingAddress: CartAddress?
    public var paymentCollection: PaymentCollection? // Added paymentCollection

    enum CodingKeys: String, CodingKey {
        case id, email, metadata, items, promotions, region
        case currencyCode = "currency_code"
        case customerId = "customer_id"
        case regionId = "region_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case completedAt = "completed_at"
        case total, subtotal
        case taxTotal = "tax_total"
        case discountTotal = "discount_total"
        case discountSubtotal = "discount_subtotal"
        case discountTaxTotal = "discount_tax_total"
        case originalTotal = "original_total"
        case originalTaxTotal = "original_tax_total"
        case itemTotal = "item_total"
        case itemSubtotal = "item_subtotal"
        case itemTaxTotal = "item_tax_total"
        case originalItemTotal = "original_item_total"
        case originalItemSubtotal = "original_item_subtotal"
        case originalItemTaxTotal = "original_item_tax_total"
        case shippingTotal = "shipping_total"
        case shippingSubtotal = "shipping_subtotal"
        case shippingTaxTotal = "shipping_tax_total"
        case originalShippingTaxTotal = "original_shipping_tax_total"
        case originalShippingSubtotal = "original_shipping_subtotal"
        case originalShippingTotal = "original_shipping_total"
        case creditLineSubtotal = "credit_line_subtotal"
        case creditLineTaxTotal = "credit_line_tax_total"
        case creditLineTotal = "credit_line_total"
        case salesChannelId = "sales_channel_id"
        case shippingAddress = "shipping_address"
        case billingAddress = "billing_address"
        case paymentCollection = "payment_collection" // Added paymentCollection
    }

    // Custom decoder to handle flexible numeric types and exact API response structure
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required fields
        id = try container.decode(String.self, forKey: .id)
        currencyCode = try container.decode(String.self, forKey: .currencyCode)

        // Handle flexible numeric types for all price fields
        total = try Cart.decodeFlexibleInt(from: container, forKey: .total) ?? 0
        subtotal = try Cart.decodeFlexibleInt(from: container, forKey: .subtotal) ?? 0
        taxTotal = try Cart.decodeFlexibleInt(from: container, forKey: .taxTotal) ?? 0
        discountTotal = try Cart.decodeFlexibleInt(from: container, forKey: .discountTotal) ?? 0
        discountSubtotal = try Cart.decodeFlexibleInt(from: container, forKey: .discountSubtotal) ?? 0
        discountTaxTotal = try Cart.decodeFlexibleInt(from: container, forKey: .discountTaxTotal) ?? 0
        originalTotal = try Cart.decodeFlexibleInt(from: container, forKey: .originalTotal) ?? 0
        originalTaxTotal = try Cart.decodeFlexibleInt(from: container, forKey: .originalTaxTotal) ?? 0
        itemTotal = try Cart.decodeFlexibleInt(from: container, forKey: .itemTotal) ?? 0
        itemSubtotal = try Cart.decodeFlexibleInt(from: container, forKey: .itemSubtotal) ?? 0
        itemTaxTotal = try Cart.decodeFlexibleInt(from: container, forKey: .itemTaxTotal) ?? 0
        originalItemTotal = try Cart.decodeFlexibleInt(from: container, forKey: .originalItemTotal) ?? 0
        originalItemSubtotal = try Cart.decodeFlexibleInt(from: container, forKey: .originalItemSubtotal) ?? 0
        originalItemTaxTotal = try Cart.decodeFlexibleInt(from: container, forKey: .originalItemTaxTotal) ?? 0
        shippingTotal = try Cart.decodeFlexibleInt(from: container, forKey: .shippingTotal) ?? 0
        shippingSubtotal = try Cart.decodeFlexibleInt(from: container, forKey: .shippingSubtotal) ?? 0
        shippingTaxTotal = try Cart.decodeFlexibleInt(from: container, forKey: .shippingTaxTotal) ?? 0
        originalShippingTaxTotal = try Cart.decodeFlexibleInt(from: container, forKey: .originalShippingTaxTotal) ?? 0
        originalShippingSubtotal = try Cart.decodeFlexibleInt(from: container, forKey: .originalShippingSubtotal) ?? 0
        originalShippingTotal = try Cart.decodeFlexibleInt(from: container, forKey: .originalShippingTotal) ?? 0
        creditLineSubtotal = try Cart.decodeFlexibleInt(from: container, forKey: .creditLineSubtotal) ?? 0
        creditLineTaxTotal = try Cart.decodeFlexibleInt(from: container, forKey: .creditLineTaxTotal) ?? 0
        creditLineTotal = try Cart.decodeFlexibleInt(from: container, forKey: .creditLineTotal) ?? 0
        
        // Optional fields
        customerId = try container.decodeIfPresent(String.self, forKey: .customerId)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        regionId = try container.decodeIfPresent(String.self, forKey: .regionId)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        completedAt = try container.decodeIfPresent(String.self, forKey: .completedAt)
        salesChannelId = try container.decodeIfPresent(String.self, forKey: .salesChannelId)
        
        // Arrays and objects
        items = try container.decodeIfPresent([CartLineItem].self, forKey: .items)
        promotions = try container.decodeIfPresent([CartPromotion].self, forKey: .promotions)
        region = try container.decodeIfPresent(CartRegion.self, forKey: .region)
        shippingAddress = try container.decodeIfPresent(CartAddress.self, forKey: .shippingAddress)
        billingAddress = try container.decodeIfPresent(CartAddress.self, forKey: .billingAddress)
        paymentCollection = try container.decodeIfPresent(PaymentCollection.self, forKey: .paymentCollection) // Decoded paymentCollection
        
        // Handle metadata as flexible dictionary - can be null or object
        if container.contains(.metadata) {
            if let metadataDict = try? container.decode([String: AnyCodable].self, forKey: .metadata) {
                metadata = metadataDict.mapValues { $0.value }
            } else {
                metadata = nil
            }
        } else {
            metadata = nil
        }
    }
    
    // Helper method to decode flexible numeric types (Int, Double, String)
    private static func decodeFlexibleInt(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Int? {
        // Try to decode as Int first
        if let intValue = try? container.decodeIfPresent(Int.self, forKey: key) {
            return intValue
        }
        
        // Try to decode as Double and convert to Int (multiply by 100 for cents)
        if let doubleValue = try? container.decodeIfPresent(Double.self, forKey: key) {
            // Convert to cents (multiply by 100 and round)
            return Int(round(doubleValue * 100))
        }
        
        // Try to decode as String and convert
        if let stringValue = try? container.decodeIfPresent(String.self, forKey: key) {
            if let doubleValue = Double(stringValue) {
                // Convert to cents (multiply by 100 and round)
                return Int(round(doubleValue * 100))
            }
            if let intValue = Int(stringValue) {
                return intValue
            }
        }
        
        // If all fail, return nil (will use default value of 0)
        return nil
    }
    
    // Custom encoder
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(currencyCode, forKey: .currencyCode)
        try container.encode(total, forKey: .total)
        try container.encode(subtotal, forKey: .subtotal)
        try container.encode(taxTotal, forKey: .taxTotal)
        try container.encode(discountTotal, forKey: .discountTotal)
        try container.encode(discountSubtotal, forKey: .discountSubtotal)
        try container.encode(discountTaxTotal, forKey: .discountTaxTotal)
        try container.encode(originalTotal, forKey: .originalTotal)
        try container.encode(originalTaxTotal, forKey: .originalTaxTotal)
        try container.encode(itemTotal, forKey: .itemTotal)
        try container.encode(itemSubtotal, forKey: .itemSubtotal)
        try container.encode(itemTaxTotal, forKey: .itemTaxTotal)
        try container.encode(originalItemTotal, forKey: .originalItemTotal)
        try container.encode(originalItemSubtotal, forKey: .originalItemSubtotal)
        try container.encode(originalItemTaxTotal, forKey: .originalItemTaxTotal)
        try container.encode(shippingTotal, forKey: .shippingTotal)
        try container.encode(shippingSubtotal, forKey: .shippingSubtotal)
        try container.encode(shippingTaxTotal, forKey: .shippingTaxTotal)
        try container.encode(originalShippingTaxTotal, forKey: .originalShippingTaxTotal)
        try container.encode(originalShippingSubtotal, forKey: .originalShippingSubtotal)
        try container.encode(originalShippingTotal, forKey: .originalShippingTotal)
        
        try container.encodeIfPresent(customerId, forKey: .customerId)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(regionId, forKey: .regionId)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(completedAt, forKey: .completedAt)
        try container.encodeIfPresent(salesChannelId, forKey: .salesChannelId)
        try container.encodeIfPresent(items, forKey: .items)
        try container.encodeIfPresent(promotions, forKey: .promotions)
        try container.encodeIfPresent(region, forKey: .region)
        try container.encodeIfPresent(shippingAddress, forKey: .shippingAddress)
        try container.encodeIfPresent(billingAddress, forKey: .billingAddress)
        try container.encodeIfPresent(paymentCollection, forKey: .paymentCollection) // Encoded paymentCollection
        
        // Skip metadata encoding for simplicity
    }
}

// MARK: - Helper struct for flexible JSON decoding
public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if container.decodeNil() {
            value = NSNull()
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.typeMismatch(AnyCodable.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let bool = value as? Bool {
            try container.encode(bool)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let string = value as? String {
            try container.encode(string)
        } else if value is NSNull {
            try container.encodeNil()
        } else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}

// MARK: - Cart Address Model
public struct CartAddress: Codable, Identifiable {
    public let id: String?
    public let firstName: String?
    public let lastName: String?
    public let company: String?
    public let address1: String?
    public let address2: String?
    public let city: String?
    public let countryCode: String?
    public let province: String?
    public let postalCode: String?
    public let phone: String?
    public let metadata: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case id, company, city, phone, metadata
        case firstName = "first_name"
        case lastName = "last_name"
        case address1 = "address_1"
        case address2 = "address_2"
        case countryCode = "country_code"
        case province
        case postalCode = "postal_code"
    }
    
    // Custom decoder to handle flexible metadata
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(String.self, forKey: .id)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        company = try container.decodeIfPresent(String.self, forKey: .company)
        address1 = try container.decodeIfPresent(String.self, forKey: .address1)
        address2 = try container.decodeIfPresent(String.self, forKey: .address2)
        city = try container.decodeIfPresent(String.self, forKey: .city)
        countryCode = try container.decodeIfPresent(String.self, forKey: .countryCode)
        province = try container.decodeIfPresent(String.self, forKey: .province)
        postalCode = try container.decodeIfPresent(String.self, forKey: .postalCode)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        
        // Handle metadata as flexible dictionary
        if container.contains(.metadata) {
            if let metadataDict = try? container.decode([String: AnyCodable].self, forKey: .metadata) {
                metadata = metadataDict.mapValues { $0.value }
            } else {
                metadata = nil
            }
        } else {
            metadata = nil
        }
    }
    
    // Custom encoder
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(firstName, forKey: .firstName)
        try container.encodeIfPresent(lastName, forKey: .lastName)
        try container.encodeIfPresent(company, forKey: .company)
        try container.encodeIfPresent(address1, forKey: .address1)
        try container.encodeIfPresent(address2, forKey: .address2)
        try container.encodeIfPresent(city, forKey: .city)
        try container.encodeIfPresent(countryCode, forKey: .countryCode)
        try container.encodeIfPresent(province, forKey: .province)
        try container.encodeIfPresent(postalCode, forKey: .postalCode)
        try container.encodeIfPresent(phone, forKey: .phone)
        
        // Skip metadata encoding for simplicity
    }
}

public struct CartRegion: Codable, Identifiable {
    public let id: String
    public let name: String
    public let currencyCode: String
    public let automaticTaxes: Bool
    public let countries: [CartCountry]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, countries
        case currencyCode = "currency_code"
        case automaticTaxes = "automatic_taxes"
    }
}

public struct CartCountry: Codable, Identifiable {
    public let iso2: String
    public let iso3: String
    public let numCode: String
    public let name: String
    public let displayName: String
    public let regionId: String
    public let metadata: String?
    public let createdAt: String?
    public let updatedAt: String?
    public let deletedAt: String?
    
    public var id: String { iso2 }
    
    enum CodingKeys: String, CodingKey {
        case name, metadata
        case iso2 = "iso_2"
        case iso3 = "iso_3"
        case numCode = "num_code"
        case displayName = "display_name"
        case regionId = "region_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}

public struct CartPromotion: Codable, Identifiable {
    public let id: String
    public let code: String?
    public let isAutomatic: Bool?
    public let applicationMethod: PromotionApplicationMethod?

    enum CodingKeys: String, CodingKey {
        case id, code
        case isAutomatic = "is_automatic"
        case applicationMethod = "application_method"
    }
}

public struct PromotionApplicationMethod: Codable {
    public let value: Int?
    public let type: String?
    public let currencyCode: String?

    enum CodingKeys: String, CodingKey {
        case value, type
        case currencyCode = "currency_code"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        currencyCode = try container.decodeIfPresent(String.self, forKey: .currencyCode)
        value = try decodeFlexibleInt(from: container, forKey: .value)
    }
}

public struct CartLineItem: Codable, Identifiable {
    public let id: String
    public let thumbnail: String?
    public let variantId: String
    public let productId: String
    public let productTypeId: String?
    public let productTitle: String?
    public let productDescription: String?
    public let productSubtitle: String?
    public let productType: String?
    public let productCollection: String?
    public let productHandle: String?
    public let variantSku: String?
    public let variantBarcode: String?
    public let variantTitle: String?
    public let requiresShipping: Bool
    public let metadata: [String: Any]?
    public let createdAt: String?
    public let updatedAt: String?
    public let title: String
    public let quantity: Int
    public let unitPrice: Int
    public let compareAtUnitPrice: Int?
    public let isTaxInclusive: Bool
    public let taxLines: [TaxLine]?
    public let adjustments: [Adjustment]?
    public let product: CartProduct?
    
    enum CodingKeys: String, CodingKey {
        case id, thumbnail, title, quantity, metadata, product
        case variantId = "variant_id"
        case productId = "product_id"
        case productTypeId = "product_type_id"
        case productTitle = "product_title"
        case productDescription = "product_description"
        case productSubtitle = "product_subtitle"
        case productType = "product_type"
        case productCollection = "product_collection"
        case productHandle = "product_handle"
        case variantSku = "variant_sku"
        case variantBarcode = "variant_barcode"
        case variantTitle = "variant_title"
        case requiresShipping = "requires_shipping"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case unitPrice = "unit_price"
        case compareAtUnitPrice = "compare_at_unit_price"
        case isTaxInclusive = "is_tax_inclusive"
        case taxLines = "tax_lines"
        case adjustments
    }
    
    // Custom decoder to handle flexible numeric types and exact API response structure
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        variantId = try container.decode(String.self, forKey: .variantId)
        productId = try container.decode(String.self, forKey: .productId)
        quantity = try container.decode(Int.self, forKey: .quantity)
        requiresShipping = try container.decode(Bool.self, forKey: .requiresShipping)
        isTaxInclusive = try container.decode(Bool.self, forKey: .isTaxInclusive)
        
        // Handle flexible numeric types for price fields
        unitPrice = try CartLineItem.decodeFlexibleInt(from: container, forKey: .unitPrice) ?? 0
        compareAtUnitPrice = try CartLineItem.decodeFlexibleInt(from: container, forKey: .compareAtUnitPrice)
        
        // Optional fields
        thumbnail = try container.decodeIfPresent(String.self, forKey: .thumbnail)
        productTypeId = try container.decodeIfPresent(String.self, forKey: .productTypeId)
        productTitle = try container.decodeIfPresent(String.self, forKey: .productTitle)
        productDescription = try container.decodeIfPresent(String.self, forKey: .productDescription)
        productSubtitle = try container.decodeIfPresent(String.self, forKey: .productSubtitle)
        productType = try container.decodeIfPresent(String.self, forKey: .productType)
        productCollection = try container.decodeIfPresent(String.self, forKey: .productCollection)
        productHandle = try container.decodeIfPresent(String.self, forKey: .productHandle)
        variantSku = try container.decodeIfPresent(String.self, forKey: .variantSku)
        variantBarcode = try container.decodeIfPresent(String.self, forKey: .variantBarcode)
        variantTitle = try container.decodeIfPresent(String.self, forKey: .variantTitle)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        taxLines = try container.decodeIfPresent([TaxLine].self, forKey: .taxLines)
        adjustments = try container.decodeIfPresent([Adjustment].self, forKey: .adjustments)
        product = try container.decodeIfPresent(CartProduct.self, forKey: .product)
        
        // Handle metadata as flexible dictionary
        if container.contains(.metadata) {
            if let metadataDict = try? container.decode([String: AnyCodable].self, forKey: .metadata) {
                metadata = metadataDict.mapValues { $0.value }
            } else {
                metadata = nil
            }
        } else {
            metadata = nil
        }
    }
    
    // Helper method to decode flexible numeric types (Int, Double, String)
    private static func decodeFlexibleInt(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Int? {
        // Try to decode as Int first
        if let intValue = try? container.decodeIfPresent(Int.self, forKey: key) {
            return intValue
        }
        
        // Try to decode as Double and convert to Int (multiply by 100 for cents)
        if let doubleValue = try? container.decodeIfPresent(Double.self, forKey: key) {
            // Convert to cents (multiply by 100 and round)
            return Int(round(doubleValue * 100))
        }
        
        // Try to decode as String and convert
        if let stringValue = try? container.decodeIfPresent(String.self, forKey: key) {
            if let doubleValue = Double(stringValue) {
                // Convert to cents (multiply by 100 and round)
                return Int(round(doubleValue * 100))
            }
            if let intValue = Int(stringValue) {
                return intValue
            }
        }
        
        // If all fail, return nil
        return nil
    }
    
    // Custom encoder
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(variantId, forKey: .variantId)
        try container.encode(productId, forKey: .productId)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(unitPrice, forKey: .unitPrice)
        try container.encode(requiresShipping, forKey: .requiresShipping)
        try container.encode(isTaxInclusive, forKey: .isTaxInclusive)
        
        try container.encodeIfPresent(thumbnail, forKey: .thumbnail)
        try container.encodeIfPresent(productTypeId, forKey: .productTypeId)
        try container.encodeIfPresent(productTitle, forKey: .productTitle)
        try container.encodeIfPresent(productDescription, forKey: .productDescription)
        try container.encodeIfPresent(productSubtitle, forKey: .productSubtitle)
        try container.encodeIfPresent(productType, forKey: .productType)
        try container.encodeIfPresent(productCollection, forKey: .productCollection)
        try container.encodeIfPresent(productHandle, forKey: .productHandle)
        try container.encodeIfPresent(variantSku, forKey: .variantSku)
        try container.encodeIfPresent(variantBarcode, forKey: .variantBarcode)
        try container.encodeIfPresent(variantTitle, forKey: .variantTitle)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(compareAtUnitPrice, forKey: .compareAtUnitPrice)
        try container.encodeIfPresent(taxLines, forKey: .taxLines)
        try container.encodeIfPresent(adjustments, forKey: .adjustments)
        try container.encodeIfPresent(product, forKey: .product)
        
        // Skip metadata encoding for simplicity
    }
}

public struct TaxLine: Codable {
    // Add tax line properties as needed
}

public struct Adjustment: Codable {
    // Add adjustment properties as needed
}

public struct CartProduct: Codable, Identifiable {
    public let id: String
    public let collectionId: String?
    public let typeId: String?
    public let categories: [ProductCategory]?
    public let tags: [ProductTag]?
    
    enum CodingKeys: String, CodingKey {
        case id, categories, tags
        case collectionId = "collection_id"
        case typeId = "type_id"
    }
}



public struct ProductTag: Codable, Identifiable {
    public let id: String
}

// MARK: - API Request/Response Models
public struct CartResponse: Codable {
    public let cart: Cart
}

public struct CreateCartRequest: Codable {
    public let regionId: String
    
    enum CodingKeys: String, CodingKey {
        case regionId = "region_id"
    }
}

public struct AddLineItemRequest: Codable {
    public let variantId: String
    public let quantity: Int
    
    enum CodingKeys: String, CodingKey {
        case variantId = "variant_id"
        case quantity
    }
}

public struct UpdateLineItemRequest: Codable {
    public let quantity: Int
}

// MARK: - Helper Extensions
extension Cart {
    public func formattedTotal(currencyCode: String? = nil) -> String {
        return formatPrice(total, currencyCode: currencyCode ?? self.currencyCode)
    }
    
    public func formattedSubtotal(currencyCode: String? = nil) -> String {
        return formatPrice(subtotal, currencyCode: currencyCode ?? self.currencyCode)
    }
    
    public func formattedTaxTotal(currencyCode: String? = nil) -> String {
        return formatPrice(taxTotal, currencyCode: currencyCode ?? self.currencyCode)
    }
    
    public func formattedShippingTotal(currencyCode: String? = nil) -> String {
        return formatPrice(shippingTotal, currencyCode: currencyCode ?? self.currencyCode)
    }
    
    public func formattedDiscountTotal(currencyCode: String? = nil) -> String {
        return formatPrice(discountTotal, currencyCode: currencyCode ?? self.currencyCode)
    }
    
    public var formattedTotal: String {
        return formatPrice(total, currencyCode: currencyCode)
    }
    
    public var formattedSubtotal: String {
        return formatPrice(subtotal, currencyCode: currencyCode)
    }
    
    public var formattedTaxTotal: String {
        return formatPrice(taxTotal, currencyCode: currencyCode)
    }
    
    public var formattedShippingTotal: String {
        return formatPrice(shippingTotal, currencyCode: currencyCode)
    }
    
    public var formattedDiscountTotal: String {
        return formatPrice(discountTotal, currencyCode: currencyCode)
    }
    
    public var itemCount: Int {
        return items?.reduce(0) { $0 + $1.quantity } ?? 0
    }
    
    public var isEmpty: Bool {
        return items?.isEmpty ?? true
    }
    
    public var isAssociatedWithCustomer: Bool {
        return customerId != nil
    }
    
    public var customerStatus: String {
        if let customerId = customerId {
            return "Customer: \(customerId)"
        } else {
            return "Anonymous Cart"
        }
    }
    
    public var hasShippingAddress: Bool {
        return shippingAddress != nil
    }
    
    public var hasBillingAddress: Bool {
        return billingAddress != nil
    }
    
    public var isReadyForCheckout: Bool {
        return !isEmpty && hasShippingAddress && hasBillingAddress
    }
}

extension CartLineItem {
    public func formattedUnitPrice(currencyCode: String) -> String {
        return formatPrice(unitPrice, currencyCode: currencyCode)
    }
    
    public func formattedTotal(currencyCode: String) -> String {
        // Calculate total since it's not provided in the API response
        let calculatedTotal = unitPrice * quantity
        return formatPrice(calculatedTotal, currencyCode: currencyCode)
    }
    
    public func formattedSubtotal(currencyCode: String) -> String {
        // Calculate subtotal since it's not provided in the API response
        let calculatedSubtotal = unitPrice * quantity
        return formatPrice(calculatedSubtotal, currencyCode: currencyCode)
    }
    
    public var formattedUnitPrice: String {
        return formatPrice(unitPrice, currencyCode: "USD")
    }
    
    public var formattedTotal: String {
        // Calculate total since it's not provided in the API response
        let calculatedTotal = unitPrice * quantity
        return formatPrice(calculatedTotal, currencyCode: "USD")
    }
    
    public var formattedSubtotal: String {
        // Calculate subtotal since it's not provided in the API response
        let calculatedSubtotal = unitPrice * quantity
        return formatPrice(calculatedSubtotal, currencyCode: "USD")
    }
    
    public var calculatedTotal: Int {
        // Calculate total since it's not provided in the API response
        return unitPrice * quantity
    }
    
    public var calculatedSubtotal: Int {
        // Calculate subtotal since it's not provided in the API response
        return unitPrice * quantity
    }
    
    public var displayImage: String? {
        return thumbnail
    }
    
    public var displayTitle: String {
        return productTitle ?? title
    }
    
    public var displaySubtitle: String? {
        if let variantTitle = variantTitle, variantTitle != title {
            return variantTitle
        }
        return productSubtitle
    }
}

extension CartAddress {
    public var fullName: String {
        let components = [firstName, lastName].compactMap { $0 }
        return components.joined(separator: " ")
    }
    
    public var fullAddress: String {
        var components: [String] = []
        
        if let address1 = address1 {
            components.append(address1)
        }
        
        if let address2 = address2 {
            components.append(address2)
        }
        
        let provinceString = province ?? ""
        if let city = city, let postalCode = postalCode {
            components.append("\(city), \(provinceString) \(postalCode)")
        }
        
        if let countryCode = countryCode {
            components.append(countryCode.uppercased())
        }
        
        return components.joined(separator: "\n")
    }
    
    public var singleLineAddress: String {
        var components: [String] = []
        
        if let address1 = address1 {
            components.append(address1)
        }
        
        if let address2 = address2 {
            components.append(address2)
        }
        
        let provinceString = province ?? ""
        if let city = city, let postalCode = postalCode, let countryCode = countryCode {
            components.append("\(city), \(provinceString) \(postalCode), \(countryCode.uppercased())")
        }
        
        return components.joined(separator: ", ")
    }
}
