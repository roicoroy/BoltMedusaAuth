
//
//  Order.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 02/07/2025.
//

import Foundation

public struct OrderResponse: Codable {
    public let order: Order

    enum CodingKeys: String, CodingKey {
        case order
    }
}

// MARK: - Top Level Order Response

public struct OrdersResponse: Codable {
    public let limit: Int
    public let offset: Int
    public let count: Int
    public let orders: [Order]
}

// MARK: - Order Model

public struct Order: Codable, Identifiable {
    public let id: String
    public let regionId: String?
    public let customerId: String?
    public let salesChannelId: String?
    public let email: String?
    public let currencyCode: String
    public let items: [OrderLineItem]?
    public let shippingMethods: [OrderShippingMethod]?
    public let paymentStatus: String?
    public let fulfillmentStatus: String?
    public let summary: OrderSummary?
    public let createdAt: String?
    public let updatedAt: String?
    public let originalItemTotal: Int?
    public let originalItemSubtotal: Int?
    public let originalItemTaxTotal: Int?
    public let itemTotal: Int?
    public let itemSubtotal: Int?
    public let itemTaxTotal: Int?
    public let originalTotal: Int?
    public let originalSubtotal: Int?
    public let originalTaxTotal: Int?
    public let total: Int?
    public let subtotal: Int?
    public let taxTotal: Int?
    public let discountTotal: Int?
    public let discountTaxTotal: Int?
    public let giftCardTotal: Int?
    public let giftCardTaxTotal: Int?
    public let shippingTotal: Int?
    public let shippingSubtotal: Int?
    public let shippingTaxTotal: Int?
    public let originalShippingTotal: Int?
    public let originalShippingSubtotal: Int?
    public let originalShippingTaxTotal: Int?
    public let status: String?
    public let creditLineTotal: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case regionId = "region_id"
        case customerId = "customer_id"
        case salesChannelId = "sales_channel_id"
        case email
        case currencyCode = "currency_code"
        case items
        case shippingMethods = "shipping_methods"
        case paymentStatus = "payment_status"
        case fulfillmentStatus = "fulfillment_status"
        case summary
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case originalItemTotal = "original_item_total"
        case originalItemSubtotal = "original_item_subtotal"
        case originalItemTaxTotal = "original_item_tax_total"
        case itemTotal = "item_total"
        case itemSubtotal = "item_subtotal"
        case itemTaxTotal = "item_tax_total"
        case originalTotal = "original_total"
        case originalSubtotal = "original_subtotal"
        case originalTaxTotal = "original_tax_total"
        case total
        case subtotal
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
        case status
        case creditLineTotal = "credit_line_total"
    }
    
    // Helper for formatted total
    public var formattedTotal: String {
        formatPrice(Int(total ?? 0), currencyCode: currencyCode)
    }
    
    public var formattedSubtotal: String {
        formatPrice(Int(subtotal ?? 0), currencyCode: currencyCode)
    }
    
    public var formattedShippingTotal: String {
        formatPrice(Int(shippingTotal ?? 0), currencyCode: currencyCode)
    }
    
    public var formattedTaxTotal: String {
        formatPrice(Int(taxTotal ?? 0), currencyCode: currencyCode)
    }
    
    public var formattedDiscountTotal: String {
        formatPrice(Int(discountTotal ?? 0), currencyCode: currencyCode)
    }
    
    public var displayStatus: String {
        status?.replacingOccurrences(of: "_", with: " ").capitalized ?? "N/A"
    }
    
    public var displayPaymentStatus: String {
        paymentStatus?.replacingOccurrences(of: "_", with: " ").capitalized ?? "N/A"
    }
    
    public var displayFulfillmentStatus: String {
        fulfillmentStatus?.replacingOccurrences(of: "_", with: " ").capitalized ?? "N/A"
    }
}

// MARK: - OrderLineItem Model

public struct OrderLineItem: Codable, Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let thumbnail: String?
    public let variantId: String?
    public let productId: String?
    public let productTitle: String?
    public let productDescription: String?
    public let productSubtitle: String?
    public let productType: String?
    public let productCollection: String?
    public let productHandle: String?
    public let variantSku: String?
    public let variantBarcode: String?
    public let variantTitle: String?
    public let variantOptionValues: [String: String]?
    public let requiresShipping: Bool
    public let isDiscountable: Bool
    public let isTaxInclusive: Bool
    public let unitPrice: Int
    public let quantity: Int
    public let detail: OrderLineItemDetail?
    public let createdAt: String?
    public let updatedAt: String?
    public let metadata: [String: AnyCodable]?
    public let originalTotal: Int?
    public let originalSubtotal: Int?
    public let originalTaxTotal: Int?
    public let itemTotal: Int?
    public let itemSubtotal: Int?
    public let itemTaxTotal: Int?
    public let total: Int?
    public let subtotal: Int?
    public let taxTotal: Int?
    public let discountTotal: Int?
    public let discountTaxTotal: Int?
    public let refundableTotal: Int?
    public let refundableTotalPerUnit: Int?
    public let productTypeId: String?

    enum CodingKeys: String, CodingKey {
        case id, title, subtitle, thumbnail
        case variantId = "variant_id"
        case productId = "product_id"
        case productTitle = "product_title"
        case productDescription = "product_description"
        case productSubtitle = "product_subtitle"
        case productType = "product_type"
        case productCollection = "product_collection"
        case productHandle = "product_handle"
        case variantSku = "variant_sku"
        case variantBarcode = "variant_barcode"
        case variantTitle = "variant_title"
        case variantOptionValues = "variant_option_values"
        case requiresShipping = "requires_shipping"
        case isDiscountable = "is_discountable"
        case isTaxInclusive = "is_tax_inclusive"
        case unitPrice = "unit_price"
        case quantity, detail
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case metadata
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
        case refundableTotalPerUnit = "refundable_total_per_unit"
        case productTypeId = "product_type_id"
    }
    
    public var displayTitle: String {
        title
    }
    
    public var displayImage: String? {
        thumbnail
    }
    
    public func formattedUnitPrice(currencyCode: String) -> String {
        formatPrice(unitPrice, currencyCode: currencyCode)
    }
    
    public func formattedTotal(currencyCode: String) -> String {
        formatPrice(Int(total ?? 0), currencyCode: currencyCode)
    }
}

// MARK: - OrderLineItemDetail Model

public struct OrderLineItemDetail: Codable, Identifiable {
    public let id: String
    public let itemId: String
    public let quantity: Int
    public let fulfilledQuantity: Int?
    public let deliveredQuantity: Int?
    public let shippedQuantity: Int?
    public let returnRequestedQuantity: Int?
    public let returnReceivedQuantity: Int?
    public let returnDismissedQuantity: Int?
    public let writtenOffQuantity: Int?
    public let metadata: [String: AnyCodable]?
    public let createdAt: String?
    public let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case itemId = "item_id"
        case quantity
        case fulfilledQuantity = "fulfilled_quantity"
        case deliveredQuantity = "delivered_quantity"
        case shippedQuantity = "shipped_quantity"
        case returnRequestedQuantity = "return_requested_quantity"
        case returnReceivedQuantity = "return_received_quantity"
        case returnDismissedQuantity = "return_dismissed_quantity"
        case writtenOffQuantity = "written_off_quantity"
        case metadata
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - OrderShippingMethod Model

public struct OrderShippingMethod: Codable, Identifiable {
    public let id: String
    public let orderId: String?
    public let name: String
    public let amount: Int
    public let isTaxInclusive: Bool
    public let shippingOptionId: String?
    public let data: [String: AnyCodable]?
    public let metadata: [String: AnyCodable]?
    public let originalTotal: Int?
    public let originalSubtotal: Int?
    public let originalTaxTotal: Int?
    public let total: Int?
    public let subtotal: Int?
    public let taxTotal: Int?
    public let discountTotal: Int?
    public let discountTaxTotal: Int?
    public let createdAt: String?
    public let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case orderId = "order_id"
        case name, amount
        case isTaxInclusive = "is_tax_inclusive"
        case shippingOptionId = "shipping_option_id"
        case data, metadata
        case originalTotal = "original_total"
        case originalSubtotal = "original_subtotal"
        case originalTaxTotal = "original_tax_total"
        case total, subtotal
        case taxTotal = "tax_total"
        case discountTotal = "discount_total"
        case discountTaxTotal = "discount_tax_total"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    public var formattedAmount: String {
        // Assuming currency code is available from the parent Order
        // For simplicity, we'll use a placeholder or require it from context
        formatPrice(amount, currencyCode: "USD") // Placeholder, ideally from Order
    }
}

// MARK: - OrderSummary Model

public struct OrderSummary: Codable {
    public let paidTotal: Int?
    public let refundedTotal: Int?
    public let pendingDifference: Int?
    public let currentOrderTotal: Int?
    public let originalOrderTotal: Int?
    public let transactionTotal: Int?
    public let accountingTotal: Int?

    enum CodingKeys: String, CodingKey {
        case paidTotal = "paid_total"
        case refundedTotal = "refunded_total"
        case pendingDifference = "pending_difference"
        case currentOrderTotal = "current_order_total"
        case originalOrderTotal = "original_order_total"
        case transactionTotal = "transaction_total"
        case accountingTotal = "accounting_total"
    }
}
