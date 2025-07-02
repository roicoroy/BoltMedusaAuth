//
//  OrderDetailView.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 02/07/2025.
//

import SwiftUI

struct OrderDetailView: View {
    let order: Order
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Order Summary
                OrderSummarySection(order: order)

                // Order Items
                OrderItemsSection(order: order)

                // Shipping Details
                OrderShippingDetailsSection(order: order)

                // Payment Details
                OrderPaymentDetailsSection(order: order)

                // Dates
                OrderDatesSection(order: order)
            }
            .padding()
        }
        .navigationTitle("Order #\(order.id.prefix(8))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

// MARK: - Sub-sections

struct OrderSummarySection: View {
    let order: Order

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Order Summary")
                .font(.headline)
                .fontWeight(.semibold)

            DetailRow(title: "Status", value: order.displayStatus)
            DetailRow(title: "Payment Status", value: order.displayPaymentStatus)
            DetailRow(title: "Fulfillment Status", value: order.displayFulfillmentStatus)
            DetailRow(title: "Total", value: order.formattedTotal)
            DetailRow(title: "Subtotal", value: order.formattedSubtotal)
            DetailRow(title: "Shipping", value: order.formattedShippingTotal)
            DetailRow(title: "Tax", value: order.formattedTaxTotal)
            
            if let discount = order.discountTotal, discount > 0 {
                DetailRow(title: "Discount", value: "-\(order.formattedDiscountTotal)")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct OrderItemsSection: View {
    let order: Order

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Items")
                .font(.headline)
                .fontWeight(.semibold)

            if let items = order.items, !items.isEmpty {
                ForEach(items) { item in
                    HStack(alignment: .top, spacing: 10) {
                        AsyncImage(url: URL(string: item.thumbnail ?? "")) {
                            image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .frame(width: 60, height: 60)
                                .overlay(Image(systemName: "photo").foregroundColor(.gray))
                        }
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            if let variantTitle = item.variantTitle {
                                Text(variantTitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Text("Qty: \(item.quantity)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text(item.formattedTotal(currencyCode: order.currencyCode))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
            } else {
                Text("No items found for this order.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct OrderShippingDetailsSection: View {
    let order: Order

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Shipping Details")
                .font(.headline)
                .fontWeight(.semibold)

            if let shippingMethods = order.shippingMethods, !shippingMethods.isEmpty {
                ForEach(shippingMethods) { method in
                    DetailRow(title: "Method", value: method.name)
                    DetailRow(title: "Amount", value: method.formattedAmount)
                }
            } else {
                Text("No shipping details available.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct OrderPaymentDetailsSection: View {
    let order: Order

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Payment Details")
                .font(.headline)
                .fontWeight(.semibold)

            DetailRow(title: "Payment Status", value: order.displayPaymentStatus)
            if let paidTotal = order.summary?.paidTotal {
                DetailRow(title: "Paid Total", value: formatPrice(paidTotal, currencyCode: order.currencyCode))
            }
            if let refundedTotal = order.summary?.refundedTotal {
                DetailRow(title: "Refunded Total", value: formatPrice(refundedTotal, currencyCode: order.currencyCode))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct OrderDatesSection: View {
    let order: Order

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Dates")
                .font(.headline)
                .fontWeight(.semibold)

            if let createdAt = order.createdAt {
                DetailRow(title: "Created At", value: formatDate(createdAt))
            }
            if let updatedAt = order.updatedAt {
                DetailRow(title: "Updated At", value: formatDate(updatedAt))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

// Re-using DetailRow from ProductsView or defining it here if not global
// struct DetailRow: View {
//    let title: String
//    let value: String
//    var valueColor: Color = .primary
//    
//    var body: some View {
//        HStack {
//            Text(title)
//                .font(.subheadline)
//                .foregroundColor(.secondary)
//            
//            Spacer()
//            
//            Text(value)
//                .font(.subheadline)
//                .fontWeight(.medium)
//                .foregroundColor(valueColor)
//        }
//    }
// }

#Preview {
    let sampleOrder = Order(
        id: "order_123",
        regionId: "reg_123",
        customerId: "cus_123",
        salesChannelId: "sc_123",
        email: "test@example.com",
        currencyCode: "usd",
        items: [
            OrderLineItem(
                id: "item_1",
                title: "Sample Product",
                subtitle: "Red, Large",
                thumbnail: "https://medusajs.com/_next/image?url=%2Fimages%2Fproducts%2Fmedusa-extravagant-sweatshirt-black.png&w=1920&q=75",
                variantId: "var_1",
                productId: "prod_1",
                productTitle: "Sample Product",
                productDescription: "A very nice sample product.",
                productSubtitle: nil,
                productType: "Apparel",
                productCollection: "Summer Collection",
                productHandle: "sample-product",
                variantSku: "SP001-RL",
                variantBarcode: nil,
                variantTitle: "Red / Large",
                variantOptionValues: ["Color": "Red", "Size": "Large"],
                requiresShipping: true,
                isDiscountable: true,
                isTaxInclusive: false,
                unitPrice: 10000,
                quantity: 1,
                detail: nil,
                createdAt: nil,
                updatedAt: nil,
                metadata: nil,
                originalTotal: nil,
                originalSubtotal: nil,
                originalTaxTotal: nil,
                itemTotal: nil,
                itemSubtotal: nil,
                itemTaxTotal: nil,
                total: 10000,
                subtotal: 10000,
                taxTotal: 0,
                discountTotal: 0,
                discountTaxTotal: 0,
                refundableTotal: nil,
                refundableTotalPerUnit: nil,
                productTypeId: nil
            )
        ],
        shippingMethods: [
            OrderShippingMethod(
                id: "sm_1",
                orderId: "order_123",
                name: "Standard Shipping",
                amount: 500,
                isTaxInclusive: false,
                shippingOptionId: "so_1",
                data: nil,
                metadata: nil,
                originalTotal: nil,
                originalSubtotal: nil,
                originalTaxTotal: nil,
                total: nil,
                subtotal: nil,
                taxTotal: nil,
                discountTotal: nil,
                discountTaxTotal: nil,
                createdAt: nil,
                updatedAt: nil
            )
        ],
        paymentStatus: "captured",
        fulfillmentStatus: "fulfilled",
        summary: OrderSummary(
            paidTotal: 10500,
            refundedTotal: 0,
            pendingDifference: 0,
            currentOrderTotal: 10500,
            originalOrderTotal: 10500,
            transactionTotal: 10500,
            accountingTotal: 10500
        ),
        createdAt: "2023-01-01T10:00:00Z",
        updatedAt: "2023-01-01T11:00:00Z",
        originalItemTotal: nil,
        originalItemSubtotal: nil,
        originalItemTaxTotal: nil,
        itemTotal: nil,
        itemSubtotal: nil,
        itemTaxTotal: nil,
        originalTotal: nil,
        originalSubtotal: nil,
        originalTaxTotal: nil,
        total: 10500,
        subtotal: 10000,
        taxTotal: 0,
        discountTotal: 0,
        discountTaxTotal: 0,
        giftCardTotal: 0,
        giftCardTaxTotal: 0,
        shippingTotal: 500,
        shippingSubtotal: 500,
        shippingTaxTotal: 0,
        originalShippingTotal: nil,
        originalShippingSubtotal: nil,
        originalShippingTaxTotal: nil,
        status: "completed",
        creditLineTotal: 0
    )
    
    OrderDetailView(order: sampleOrder)
}
