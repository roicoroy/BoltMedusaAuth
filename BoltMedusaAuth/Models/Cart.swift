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
    let originalItemTotal: Int
    let originalItemSubtotal: Int
    let originalItemTaxTotal: Int
    let itemTotal: Int
    let itemSubtotal: Int
    let itemTaxTotal: Int
    let originalTotal: Int
    let originalSubtotal: Int
    let originalTaxTotal: Int
    let total: Int
    let subtotal: Int
    let taxTotal: Int
    let discountTotal: Int
    let discountTaxTotal: Int
    let giftCardTotal: Int
    let giftCardTaxTotal: Int
    let shippingTotal: Int
    let shippingSubtotal: Int
    let shippingTaxTotal: Int
    let originalShippingTotal: Int
    let originalShippingSubtotal: Int
    let originalShippingTaxTotal: Int
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
}

struct CartPromotion: Codable, Identifiable {
    let id: String
}

struct CartLineItem: Codable, Identifiable {
    let id: String
    let cartId: String
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
    let isDiscountable: Bool
    let isGiftCard: Bool
    let shouldMerge: Bool
    let allowDiscounts: Bool
    let hasShipping: Bool
    let isTaxInclusive: Bool
    let originalTotal: Int
    let originalSubtotal: Int
    let originalTaxTotal: Int
    let itemTotal: Int
    let itemSubtotal: Int
    let itemTaxTotal: Int
    let total: Int
    let subtotal: Int
    let taxTotal: Int
    let discountTotal: Int
    let discountTaxTotal: Int
    let refundableTotal: Int?
    let refundableSubtotal: Int?
    let refundableTaxTotal: Int?
    let createdAt: String
    let updatedAt: String
    
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
    
    private func formatPrice(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode.uppercased()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        let decimalAmount = Double(amount) / 100.0
        return formatter.string(from: NSNumber(value: decimalAmount)) ?? "$0.00"
    }
}

extension CartLineItem {
    var formattedUnitPrice: String {
        return formatPrice(unitPrice)
    }
    
    var formattedTotal: String {
        return formatPrice(total)
    }
    
    var formattedSubtotal: String {
        return formatPrice(subtotal)
    }
    
    private func formatPrice(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD" // Default to USD, could be made dynamic
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        let decimalAmount = Double(amount) / 100.0
        return formatter.string(from: NSNumber(value: decimalAmount)) ?? "$0.00"
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