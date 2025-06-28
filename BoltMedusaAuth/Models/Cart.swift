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
    let originalItemTotal: Int?
    let originalItemSubtotal: Int?
    let originalItemTaxTotal: Int?
    let itemTotal: Int?
    let itemSubtotal: Int?
    let itemTaxTotal: Int?
    let originalTotal: Int?
    let originalSubtotal: Int?
    let originalTaxTotal: Int?
    let total: Int
    let subtotal: Int
    let taxTotal: Int?
    let discountTotal: Int?
    let discountTaxTotal: Int?
    let giftCardTotal: Int?
    let giftCardTaxTotal: Int?
    let shippingTotal: Int?
    let shippingSubtotal: Int?
    let shippingTaxTotal: Int?
    let originalShippingTotal: Int?
    let originalShippingSubtotal: Int?
    let originalShippingTaxTotal: Int?
    let promotions: [CartPromotion]?
    let items: [CartLineItem]?
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, promotions, items
        case currencyCode = "currency_code"
        case originalItemTotal = "original_item_total"
        case originalItemSubtotal = "original_item_subtotal"
        case originalItemTaxTotal = "original_item_tax_total"
        case itemTotal = "item_total"
        case itemSubtotal = "item_subtotal"
        case itemTaxTotal = "item_tax_total"
        case originalTotal = "original_total"
        case originalSubtotal = "original_subtotal"
        case originalTaxTotal = "original_tax_total"
        case total, subtotal
        case taxTotal = "tax_total"
        case discountTotal = "discount_total"
        case discountTaxTotal = "discount_tax_total"
        case giftCardTotal = "gift_card_total"
        case giftCardTaxTotal = "gift_card_tax_total"
        case shippingTotal = "shipping_total"
        case shippingSubtotal = "shipping_subtotal"
        case shippingTaxTotal = "shipping_tax_total"
        case originalShippingTotal = "original_shipping_total"
        case originalShippingSubtotal = "original_shipping_subtotal"
        case originalShippingTaxTotal = "original_shipping_tax_total"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Custom decoder to handle missing optional fields gracefully
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Essential required fields
        id = try container.decode(String.self, forKey: .id)
        currencyCode = try container.decode(String.self, forKey: .currencyCode)
        total = try container.decode(Int.self, forKey: .total)
        subtotal = try container.decode(Int.self, forKey: .subtotal)
        
        // All other fields are optional since API responses vary
        originalItemTotal = try container.decodeIfPresent(Int.self, forKey: .originalItemTotal)
        originalItemSubtotal = try container.decodeIfPresent(Int.self, forKey: .originalItemSubtotal)
        originalItemTaxTotal = try container.decodeIfPresent(Int.self, forKey: .originalItemTaxTotal)
        itemTotal = try container.decodeIfPresent(Int.self, forKey: .itemTotal)
        itemSubtotal = try container.decodeIfPresent(Int.self, forKey: .itemSubtotal)
        itemTaxTotal = try container.decodeIfPresent(Int.self, forKey: .itemTaxTotal)
        originalTotal = try container.decodeIfPresent(Int.self, forKey: .originalTotal)
        originalSubtotal = try container.decodeIfPresent(Int.self, forKey: .originalSubtotal)
        originalTaxTotal = try container.decodeIfPresent(Int.self, forKey: .originalTaxTotal)
        taxTotal = try container.decodeIfPresent(Int.self, forKey: .taxTotal)
        discountTotal = try container.decodeIfPresent(Int.self, forKey: .discountTotal)
        discountTaxTotal = try container.decodeIfPresent(Int.self, forKey: .discountTaxTotal)
        giftCardTotal = try container.decodeIfPresent(Int.self, forKey: .giftCardTotal)
        giftCardTaxTotal = try container.decodeIfPresent(Int.self, forKey: .giftCardTaxTotal)
        shippingTotal = try container.decodeIfPresent(Int.self, forKey: .shippingTotal)
        shippingSubtotal = try container.decodeIfPresent(Int.self, forKey: .shippingSubtotal)
        shippingTaxTotal = try container.decodeIfPresent(Int.self, forKey: .shippingTaxTotal)
        originalShippingTotal = try container.decodeIfPresent(Int.self, forKey: .originalShippingTotal)
        originalShippingSubtotal = try container.decodeIfPresent(Int.self, forKey: .originalShippingSubtotal)
        originalShippingTaxTotal = try container.decodeIfPresent(Int.self, forKey: .originalShippingTaxTotal)
        
        // Arrays and optional fields
        promotions = try container.decodeIfPresent([CartPromotion].self, forKey: .promotions)
        items = try container.decodeIfPresent([CartLineItem].self, forKey: .items)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
    }
}

struct CartPromotion: Codable, Identifiable {
    let id: String
}

struct CartLineItem: Codable, Identifiable {
    let id: String
    let cartId: String?  // Made optional - might not be present in API response
    let title: String
    let subtitle: String?
    let thumbnail: String?
    let variantId: String
    let productId: String
    let productTitle: String?
    let productDescription: String?
    let productSubtitle: String?
    let productType: String?
    let productCollection: String?
    let productHandle: String?
    let variantTitle: String?
    let variantSku: String?
    let quantity: Int
    let unitPrice: Int
    let compareAtUnitPrice: Int?
    let isDiscountable: Bool?
    let isGiftCard: Bool?
    let shouldMerge: Bool?
    let allowDiscounts: Bool?
    let hasShipping: Bool?
    let isTaxInclusive: Bool?
    let originalTotal: Int?
    let originalSubtotal: Int?
    let originalTaxTotal: Int?
    let itemTotal: Int?
    let itemSubtotal: Int?
    let itemTaxTotal: Int?
    let total: Int?  // Made optional - might not be present in API response
    let subtotal: Int?  // Made optional - might not be present in API response
    let taxTotal: Int?
    let discountTotal: Int?
    let discountTaxTotal: Int?
    let refundableTotal: Int?
    let refundableSubtotal: Int?
    let refundableTaxTotal: Int?
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, subtitle, thumbnail, quantity
        case cartId = "cart_id"
        case variantId = "variant_id"
        case productId = "product_id"
        case productTitle = "product_title"
        case productDescription = "product_description"
        case productSubtitle = "product_subtitle"
        case productType = "product_type"
        case productCollection = "product_collection"
        case productHandle = "product_handle"
        case variantTitle = "variant_title"
        case variantSku = "variant_sku"
        case unitPrice = "unit_price"
        case compareAtUnitPrice = "compare_at_unit_price"
        case isDiscountable = "is_discountable"
        case isGiftCard = "is_gift_card"
        case shouldMerge = "should_merge"
        case allowDiscounts = "allow_discounts"
        case hasShipping = "has_shipping"
        case isTaxInclusive = "is_tax_inclusive"
        case originalTotal = "original_total"
        case originalSubtotal = "original_subtotal"
        case originalTaxTotal = "original_tax_total"
        case itemTotal = "item_total"
        case itemSubtotal = "item_subtotal"
        case itemTaxTotal = "item_tax_total"
        case total, subtotal
        case taxTotal = "tax_total"
        case discountTotal = "discount_total"
        case discountTaxTotal = "discount_tax_total"
        case refundableTotal = "refundable_total"
        case refundableSubtotal = "refundable_subtotal"
        case refundableTaxTotal = "refundable_tax_total"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Custom decoder to handle missing optional fields gracefully
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Essential required fields
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        variantId = try container.decode(String.self, forKey: .variantId)
        productId = try container.decode(String.self, forKey: .productId)
        quantity = try container.decode(Int.self, forKey: .quantity)
        unitPrice = try container.decode(Int.self, forKey: .unitPrice)
        
        // total and subtotal are now optional - calculate if missing
        total = try container.decodeIfPresent(Int.self, forKey: .total)
        subtotal = try container.decodeIfPresent(Int.self, forKey: .subtotal)
        
        // cartId is now optional - might not be present in API response
        cartId = try container.decodeIfPresent(String.self, forKey: .cartId)
        
        // All other fields are optional since API responses vary
        subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
        thumbnail = try container.decodeIfPresent(String.self, forKey: .thumbnail)
        productTitle = try container.decodeIfPresent(String.self, forKey: .productTitle)
        productDescription = try container.decodeIfPresent(String.self, forKey: .productDescription)
        productSubtitle = try container.decodeIfPresent(String.self, forKey: .productSubtitle)
        productType = try container.decodeIfPresent(String.self, forKey: .productType)
        productCollection = try container.decodeIfPresent(String.self, forKey: .productCollection)
        productHandle = try container.decodeIfPresent(String.self, forKey: .productHandle)
        variantTitle = try container.decodeIfPresent(String.self, forKey: .variantTitle)
        variantSku = try container.decodeIfPresent(String.self, forKey: .variantSku)
        compareAtUnitPrice = try container.decodeIfPresent(Int.self, forKey: .compareAtUnitPrice)
        isDiscountable = try container.decodeIfPresent(Bool.self, forKey: .isDiscountable)
        isGiftCard = try container.decodeIfPresent(Bool.self, forKey: .isGiftCard)
        shouldMerge = try container.decodeIfPresent(Bool.self, forKey: .shouldMerge)
        allowDiscounts = try container.decodeIfPresent(Bool.self, forKey: .allowDiscounts)
        hasShipping = try container.decodeIfPresent(Bool.self, forKey: .hasShipping)
        isTaxInclusive = try container.decodeIfPresent(Bool.self, forKey: .isTaxInclusive)
        originalTotal = try container.decodeIfPresent(Int.self, forKey: .originalTotal)
        originalSubtotal = try container.decodeIfPresent(Int.self, forKey: .originalSubtotal)
        originalTaxTotal = try container.decodeIfPresent(Int.self, forKey: .originalTaxTotal)
        itemTotal = try container.decodeIfPresent(Int.self, forKey: .itemTotal)
        itemSubtotal = try container.decodeIfPresent(Int.self, forKey: .itemSubtotal)
        itemTaxTotal = try container.decodeIfPresent(Int.self, forKey: .itemTaxTotal)
        taxTotal = try container.decodeIfPresent(Int.self, forKey: .taxTotal)
        discountTotal = try container.decodeIfPresent(Int.self, forKey: .discountTotal)
        discountTaxTotal = try container.decodeIfPresent(Int.self, forKey: .discountTaxTotal)
        refundableTotal = try container.decodeIfPresent(Int.self, forKey: .refundableTotal)
        refundableSubtotal = try container.decodeIfPresent(Int.self, forKey: .refundableSubtotal)
        refundableTaxTotal = try container.decodeIfPresent(Int.self, forKey: .refundableTaxTotal)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
    }
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
        return formatPrice(taxTotal ?? 0, currencyCode: currencyCode ?? self.currencyCode)
    }
    
    func formattedShippingTotal(currencyCode: String? = nil) -> String {
        return formatPrice(shippingTotal ?? 0, currencyCode: currencyCode ?? self.currencyCode)
    }
    
    func formattedDiscountTotal(currencyCode: String? = nil) -> String {
        return formatPrice(discountTotal ?? 0, currencyCode: currencyCode ?? self.currencyCode)
    }
    
    var formattedTotal: String {
        return formatPrice(total)
    }
    
    var formattedSubtotal: String {
        return formatPrice(subtotal)
    }
    
    var formattedTaxTotal: String {
        return formatPrice(taxTotal ?? 0)
    }
    
    var formattedShippingTotal: String {
        return formatPrice(shippingTotal ?? 0)
    }
    
    var formattedDiscountTotal: String {
        return formatPrice(discountTotal ?? 0)
    }
    
    var itemCount: Int {
        return items?.reduce(0) { $0 + $1.quantity } ?? 0
    }
    
    var isEmpty: Bool {
        return items?.isEmpty ?? true
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
        // Calculate total if not provided by API
        let calculatedTotal = total ?? (unitPrice * quantity)
        return formatPrice(calculatedTotal, currencyCode: currencyCode)
    }
    
    func formattedSubtotal(currencyCode: String) -> String {
        // Calculate subtotal if not provided by API
        let calculatedSubtotal = subtotal ?? (unitPrice * quantity)
        return formatPrice(calculatedSubtotal, currencyCode: currencyCode)
    }
    
    var formattedUnitPrice: String {
        return formatPrice(unitPrice)
    }
    
    var formattedTotal: String {
        // Calculate total if not provided by API
        let calculatedTotal = total ?? (unitPrice * quantity)
        return formatPrice(calculatedTotal)
    }
    
    var formattedSubtotal: String {
        // Calculate subtotal if not provided by API
        let calculatedSubtotal = subtotal ?? (unitPrice * quantity)
        return formatPrice(calculatedSubtotal)
    }
    
    var calculatedTotal: Int {
        // Return API total if available, otherwise calculate
        return total ?? (unitPrice * quantity)
    }
    
    var calculatedSubtotal: Int {
        // Return API subtotal if available, otherwise calculate
        return subtotal ?? (unitPrice * quantity)
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
        return productSubtitle ?? subtitle
    }
}