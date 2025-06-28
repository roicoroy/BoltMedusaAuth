//
//  Cart.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 28/06/2025.
//

import Foundation

// MARK: - Cart Models
struct Cart: Codable, Identifiable {
    let id: String
    let currencyCode: String
    let customerId: String?
    let email: String?
    let regionId: String?
    let createdAt: String?
    let updatedAt: String?
    let completedAt: String?
    let total: Int
    let subtotal: Int
    let taxTotal: Int
    let discountTotal: Int
    let discountSubtotal: Int
    let discountTaxTotal: Int
    let originalTotal: Int
    let originalTaxTotal: Int
    let itemTotal: Int
    let itemSubtotal: Int
    let itemTaxTotal: Int
    let originalItemTotal: Int
    let originalItemSubtotal: Int
    let originalItemTaxTotal: Int
    let shippingTotal: Int
    let shippingSubtotal: Int
    let shippingTaxTotal: Int
    let originalShippingTaxTotal: Int
    let originalShippingSubtotal: Int
    let originalShippingTotal: Int
    let metadata: [String: Any]?
    let salesChannelId: String?
    let items: [CartLineItem]?
    let promotions: [CartPromotion]?
    let region: CartRegion?
    let shippingAddress: CartAddress?
    let billingAddress: CartAddress?
    
    enum CodingKeys: String, CodingKey {
        case id, email, metadata, total, subtotal, items, promotions, region
        case currencyCode = "currency_code"
        case customerId = "customer_id"
        case regionId = "region_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case completedAt = "completed_at"
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
        case salesChannelId = "sales_channel_id"
        case shippingAddress = "shipping_address"
        case billingAddress = "billing_address"
    }
    
    // Custom decoder to handle the exact API response structure
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        id = try container.decode(String.self, forKey: .id)
        currencyCode = try container.decode(String.self, forKey: .currencyCode)
        total = try container.decode(Int.self, forKey: .total)
        subtotal = try container.decode(Int.self, forKey: .subtotal)
        
        // Fields that match the API response exactly
        taxTotal = try container.decode(Int.self, forKey: .taxTotal)
        discountTotal = try container.decode(Int.self, forKey: .discountTotal)
        discountSubtotal = try container.decode(Int.self, forKey: .discountSubtotal)
        discountTaxTotal = try container.decode(Int.self, forKey: .discountTaxTotal)
        originalTotal = try container.decode(Int.self, forKey: .originalTotal)
        originalTaxTotal = try container.decode(Int.self, forKey: .originalTaxTotal)
        itemTotal = try container.decode(Int.self, forKey: .itemTotal)
        itemSubtotal = try container.decode(Int.self, forKey: .itemSubtotal)
        itemTaxTotal = try container.decode(Int.self, forKey: .itemTaxTotal)
        originalItemTotal = try container.decode(Int.self, forKey: .originalItemTotal)
        originalItemSubtotal = try container.decode(Int.self, forKey: .originalItemSubtotal)
        originalItemTaxTotal = try container.decode(Int.self, forKey: .originalItemTaxTotal)
        shippingTotal = try container.decode(Int.self, forKey: .shippingTotal)
        shippingSubtotal = try container.decode(Int.self, forKey: .shippingSubtotal)
        shippingTaxTotal = try container.decode(Int.self, forKey: .shippingTaxTotal)
        originalShippingTaxTotal = try container.decode(Int.self, forKey: .originalShippingTaxTotal)
        originalShippingSubtotal = try container.decode(Int.self, forKey: .originalShippingSubtotal)
        originalShippingTotal = try container.decode(Int.self, forKey: .originalShippingTotal)
        
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
    
    // Custom encoder
    func encode(to encoder: Encoder) throws {
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
        
        // Skip metadata encoding for simplicity
    }
}

// MARK: - Cart Address Model
struct CartAddress: Codable, Identifiable {
    let id: String?
    let firstName: String?
    let lastName: String?
    let company: String?
    let address1: String
    let address2: String?
    let city: String
    let countryCode: String
    let province: String?
    let postalCode: String
    let phone: String?
    let metadata: [String: Any]?
    
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
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(String.self, forKey: .id)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        company = try container.decodeIfPresent(String.self, forKey: .company)
        address1 = try container.decode(String.self, forKey: .address1)
        address2 = try container.decodeIfPresent(String.self, forKey: .address2)
        city = try container.decode(String.self, forKey: .city)
        countryCode = try container.decode(String.self, forKey: .countryCode)
        province = try container.decodeIfPresent(String.self, forKey: .province)
        postalCode = try container.decode(String.self, forKey: .postalCode)
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
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(firstName, forKey: .firstName)
        try container.encodeIfPresent(lastName, forKey: .lastName)
        try container.encodeIfPresent(company, forKey: .company)
        try container.encode(address1, forKey: .address1)
        try container.encodeIfPresent(address2, forKey: .address2)
        try container.encode(city, forKey: .city)
        try container.encode(countryCode, forKey: .countryCode)
        try container.encodeIfPresent(province, forKey: .province)
        try container.encode(postalCode, forKey: .postalCode)
        try container.encodeIfPresent(phone, forKey: .phone)
        
        // Skip metadata encoding for simplicity
    }
}

// Helper struct for flexible JSON decoding
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
        } else if container.decodeNil() {
            value = NSNull()
        } else {
            throw DecodingError.typeMismatch(AnyCodable.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
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

struct CartRegion: Codable, Identifiable {
    let id: String
    let name: String
    let currencyCode: String
    let automaticTaxes: Bool
    let countries: [CartCountry]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, countries
        case currencyCode = "currency_code"
        case automaticTaxes = "automatic_taxes"
    }
}

struct CartCountry: Codable, Identifiable {
    let iso2: String
    let iso3: String
    let numCode: String
    let name: String
    let displayName: String
    let regionId: String
    let metadata: String?
    let createdAt: String?
    let updatedAt: String?
    let deletedAt: String?
    
    var id: String { iso2 }
    
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

struct CartPromotion: Codable, Identifiable {
    let id: String
}

struct CartLineItem: Codable, Identifiable {
    let id: String
    let thumbnail: String?
    let variantId: String
    let productId: String
    let productTypeId: String?
    let productTitle: String?
    let productDescription: String?
    let productSubtitle: String?
    let productType: String?
    let productCollection: String?
    let productHandle: String?
    let variantSku: String?
    let variantBarcode: String?
    let variantTitle: String?
    let requiresShipping: Bool
    let metadata: [String: Any]?
    let createdAt: String?
    let updatedAt: String?
    let title: String
    let quantity: Int
    let unitPrice: Int
    let compareAtUnitPrice: Int?
    let isTaxInclusive: Bool
    let taxLines: [TaxLine]?
    let adjustments: [Adjustment]?
    let product: CartProduct?
    
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
    
    // Custom decoder to handle the exact API response structure
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        variantId = try container.decode(String.self, forKey: .variantId)
        productId = try container.decode(String.self, forKey: .productId)
        quantity = try container.decode(Int.self, forKey: .quantity)
        unitPrice = try container.decode(Int.self, forKey: .unitPrice)
        requiresShipping = try container.decode(Bool.self, forKey: .requiresShipping)
        isTaxInclusive = try container.decode(Bool.self, forKey: .isTaxInclusive)
        
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
        compareAtUnitPrice = try container.decodeIfPresent(Int.self, forKey: .compareAtUnitPrice)
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
    
    // Custom encoder
    func encode(to encoder: Encoder) throws {
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

struct TaxLine: Codable {
    // Add tax line properties as needed
}

struct Adjustment: Codable {
    // Add adjustment properties as needed
}

struct CartProduct: Codable, Identifiable {
    let id: String
    let collectionId: String?
    let typeId: String?
    let categories: [ProductCategory]?
    let tags: [ProductTag]?
    
    enum CodingKeys: String, CodingKey {
        case id, categories, tags
        case collectionId = "collection_id"
        case typeId = "type_id"
    }
}

struct ProductCategory: Codable, Identifiable {
    let id: String
}

struct ProductTag: Codable, Identifiable {
    let id: String
}

// MARK: - API Request/Response Models
struct CartResponse: Codable {
    let cart: Cart
}

struct CreateCartRequest: Codable {
    let regionId: String
    
    enum CodingKeys: String, CodingKey {
        case regionId = "region_id"
    }
}

struct AddLineItemRequest: Codable {
    let variantId: String
    let quantity: Int
    
    enum CodingKeys: String, CodingKey {
        case variantId = "variant_id"
        case quantity
    }
}

struct UpdateLineItemRequest: Codable {
    let quantity: Int
}

// MARK: - Helper Extensions
extension Cart {
    func formattedTotal(currencyCode: String? = nil) -> String {
        return formatPrice(total, currencyCode: currencyCode ?? self.currencyCode)
    }
    
    func formattedSubtotal(currencyCode: String? = nil) -> String {
        return formatPrice(subtotal, currencyCode: currencyCode ?? self.currencyCode)
    }
    
    func formattedTaxTotal(currencyCode: String? = nil) -> String {
        return formatPrice(taxTotal, currencyCode: currencyCode ?? self.currencyCode)
    }
    
    func formattedShippingTotal(currencyCode: String? = nil) -> String {
        return formatPrice(shippingTotal, currencyCode: currencyCode ?? self.currencyCode)
    }
    
    func formattedDiscountTotal(currencyCode: String? = nil) -> String {
        return formatPrice(discountTotal, currencyCode: currencyCode ?? self.currencyCode)
    }
    
    var formattedTotal: String {
        return formatPrice(total)
    }
    
    var formattedSubtotal: String {
        return formatPrice(subtotal)
    }
    
    var formattedTaxTotal: String {
        return formatPrice(taxTotal)
    }
    
    var formattedShippingTotal: String {
        return formatPrice(shippingTotal)
    }
    
    var formattedDiscountTotal: String {
        return formatPrice(discountTotal)
    }
    
    var itemCount: Int {
        return items?.reduce(0) { $0 + $1.quantity } ?? 0
    }
    
    var isEmpty: Bool {
        return items?.isEmpty ?? true
    }
    
    var isAssociatedWithCustomer: Bool {
        return customerId != nil
    }
    
    var customerStatus: String {
        if let customerId = customerId {
            return "Customer: \(customerId)"
        } else {
            return "Anonymous Cart"
        }
    }
    
    var hasShippingAddress: Bool {
        return shippingAddress != nil
    }
    
    var hasBillingAddress: Bool {
        return billingAddress != nil
    }
    
    var isReadyForCheckout: Bool {
        return !isEmpty && hasShippingAddress && hasBillingAddress
    }
    
    private func formatPrice(_ amount: Int, currencyCode: String? = nil) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = (currencyCode ?? self.currencyCode).uppercased()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        let decimalAmount = Double(amount) / 100.0
        return formatter.string(from: NSNumber(value: decimalAmount)) ?? "\((currencyCode ?? self.currencyCode).uppercased()) 0.00"
    }
}

extension CartLineItem {
    func formattedUnitPrice(currencyCode: String) -> String {
        return formatPrice(unitPrice, currencyCode: currencyCode)
    }
    
    func formattedTotal(currencyCode: String) -> String {
        // Calculate total since it's not provided in the API response
        let calculatedTotal = unitPrice * quantity
        return formatPrice(calculatedTotal, currencyCode: currencyCode)
    }
    
    func formattedSubtotal(currencyCode: String) -> String {
        // Calculate subtotal since it's not provided in the API response
        let calculatedSubtotal = unitPrice * quantity
        return formatPrice(calculatedSubtotal, currencyCode: currencyCode)
    }
    
    var formattedUnitPrice: String {
        return formatPrice(unitPrice)
    }
    
    var formattedTotal: String {
        // Calculate total since it's not provided in the API response
        let calculatedTotal = unitPrice * quantity
        return formatPrice(calculatedTotal)
    }
    
    var formattedSubtotal: String {
        // Calculate subtotal since it's not provided in the API response
        let calculatedSubtotal = unitPrice * quantity
        return formatPrice(calculatedSubtotal)
    }
    
    var calculatedTotal: Int {
        // Calculate total since it's not provided in the API response
        return unitPrice * quantity
    }
    
    var calculatedSubtotal: Int {
        // Calculate subtotal since it's not provided in the API response
        return unitPrice * quantity
    }
    
    private func formatPrice(_ amount: Int, currencyCode: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode.uppercased()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        let decimalAmount = Double(amount) / 100.0
        return formatter.string(from: NSNumber(value: decimalAmount)) ?? "\(currencyCode.uppercased()) 0.00"
    }
    
    var displayImage: String? {
        return thumbnail
    }
    
    var displayTitle: String {
        return productTitle ?? title
    }
    
    var displaySubtitle: String? {
        if let variantTitle = variantTitle, variantTitle != title {
            return variantTitle
        }
        return productSubtitle
    }
}

extension CartAddress {
    var fullName: String {
        let components = [firstName, lastName].compactMap { $0 }
        return components.joined(separator: " ")
    }
    
    var fullAddress: String {
        var components = [address1]
        
        if let address2 = address2 {
            components.append(address2)
        }
        
        components.append("\(city), \(province ?? "") \(postalCode)")
        components.append(countryCode.uppercased())
        
        return components.joined(separator: "\n")
    }
    
    var singleLineAddress: String {
        var components = [address1]
        
        if let address2 = address2 {
            components.append(address2)
        }
        
        components.append("\(city), \(province ?? "") \(postalCode), \(countryCode.uppercased())")
        
        return components.joined(separator: ", ")
    }
}