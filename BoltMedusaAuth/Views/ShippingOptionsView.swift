//
//  ShippingOptionsView.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 01/07/2025.
//

import SwiftUI

struct ShippingOptionsView: View {
    let cart: Cart
    @StateObject private var shippingService = ShippingService()
    @EnvironmentObject var cartService: CartService
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedOptionId: String?
    @State private var isAddingShippingMethod = false
    @State private var showingSuccessAlert = false
    @State private var successMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header Info
                CartInfoHeader(cart: cart)
                
                // Main Content
                if shippingService.isLoading {
                    LoadingShippingOptionsView()
                } else if shippingService.shippingOptions.isEmpty && shippingService.errorMessage == nil {
                    EmptyShippingOptionsView(
                        onRetry: {
                            shippingService.fetchShippingOptions(for: cart.id)
                        }
                    )
                } else if !shippingService.shippingOptions.isEmpty {
                    ShippingOptionsListView(
                        shippingOptions: shippingService.shippingOptions,
                        currencyCode: cart.currencyCode,
                        selectedOptionId: $selectedOptionId,
                        onSelectOption: { optionId in
                            selectedOptionId = optionId
                        }
                    )
                }
                
                // Error Message
                if let errorMessage = shippingService.errorMessage {
                    ErrorMessageView(
                        message: errorMessage,
                        onRetry: {
                            shippingService.fetchShippingOptions(for: cart.id)
                        }
                    )
                }
                
                // Add Shipping Method Button
                if let selectedOptionId = selectedOptionId {
                    AddShippingMethodButton(
                        selectedOptionId: selectedOptionId,
                        isLoading: isAddingShippingMethod,
                        onAddShippingMethod: {
                            addShippingMethodToCart(optionId: selectedOptionId)
                        }
                    )
                }
                
                Spacer()
            }
            .navigationTitle("Shipping Options")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Refresh") {
                    shippingService.fetchShippingOptions(for: cart.id)
                }
                .disabled(shippingService.isLoading)
            )
        }
        .onAppear {
            shippingService.fetchShippingOptions(for: cart.id)
        }
        .alert("Shipping Method Added", isPresented: $showingSuccessAlert) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text(successMessage)
        }
    }
    
    private func addShippingMethodToCart(optionId: String) {
        isAddingShippingMethod = true
        
        cartService.addShippingMethodToCart(optionId: optionId) { success in
            DispatchQueue.main.async {
                self.isAddingShippingMethod = false
                
                if success {
                    // Find the selected option to show its name
                    let selectedOption = self.shippingService.shippingOptions.first { $0.id == optionId }
                    let optionName = selectedOption?.displayName ?? "shipping method"
                    
                    self.successMessage = "\(optionName) has been added to your cart. Your cart total has been updated."
                    self.showingSuccessAlert = true
                } else {
                    // Error is already handled by cartService.errorMessage
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct CartInfoHeader: View {
    let cart: Cart
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cart Information")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("Cart ID:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(cart.id)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Currency")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(cart.currencyCode.uppercased())
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(cart.itemCount)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 4) {
                    Text("Subtotal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(cart.formattedSubtotal)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(cart.formattedTotal)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding()
    }
}

struct LoadingShippingOptionsView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading shipping options...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyShippingOptionsView: View {
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "truck")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Shipping Options Available")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("No shipping options were found for this cart. This might be because:")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("• No shipping address is set")
                Text("• No shipping methods are configured")
                Text("• Cart is not eligible for shipping")
                Text("• All items are digital products")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            Button("Retry") {
                onRetry()
            }
            .foregroundColor(.blue)
            .padding(.top)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ShippingOptionsListView: View {
    let shippingOptions: [ShippingOption]
    let currencyCode: String
    @Binding var selectedOptionId: String?
    let onSelectOption: (String) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(shippingOptions) { option in
                    ShippingOptionCard(
                        option: option,
                        currencyCode: currencyCode,
                        isSelected: selectedOptionId == option.id,
                        onTap: {
                            onSelectOption(option.id)
                        }
                    )
                }
            }
            .padding()
        }
    }
}

struct ShippingOptionCard: View {
    let option: ShippingOption
    let currencyCode: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with name and price
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(option.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 8) {
                            Text(option.priceTypeDisplay)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(priceTypeColor.opacity(0.2))
                                .foregroundColor(priceTypeColor)
                                .cornerRadius(4)
                            
                            if let typeLabel = option.typeLabel {
                                Text(typeLabel)
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(option.formattedAmount(currencyCode: currencyCode))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(option.isFree ? .green : .primary)
                        
                        if option.isFree {
                            Text("FREE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                // Provider and delivery info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "building.2")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Provider: \(option.providerName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let estimatedDelivery = option.estimatedDelivery {
                            HStack {
                                Image(systemName: "clock")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Delivery: \(estimatedDelivery)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if let typeCode = option.typeCode {
                            HStack {
                                Image(systemName: "barcode")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Code: \(typeCode)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Selection indicator
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    } else {
                        Image(systemName: "circle")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                
                // Description if available
                if let description = option.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                
                // Status badges
                HStack {
                    Text(option.availabilityStatus)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(option.availabilityColor.opacity(0.2))
                        .foregroundColor(option.availabilityColor)
                        .cornerRadius(3)
                    
                    if !option.isProviderEnabled {
                        Text("Provider Disabled")
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(3)
                    }
                    
                    if option.hasInsufficientInventory {
                        Text("Low Inventory")
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(3)
                    }
                    
                    Spacer()
                }
                
                // Calculated price details if available
                if let calculatedPrice = option.calculatedPrice {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Price Breakdown:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("Calculated Amount:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(calculatedPrice.formattedCalculatedAmount())
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("Original Amount:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(calculatedPrice.formattedOriginalAmount())
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        if let withTax = calculatedPrice.formattedOriginalAmountWithTax() {
                            HStack {
                                Text("With Tax:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(withTax)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        if let withoutTax = calculatedPrice.formattedOriginalAmountWithoutTax() {
                            HStack {
                                Text("Without Tax:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(withoutTax)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                // Technical details (collapsible)
                DisclosureGroup("Technical Details") {
                    VStack(alignment: .leading, spacing: 4) {
                        DetailRow(title: "ID", value: option.id)
                        DetailRow(title: "Price Type", value: option.priceType)
                        
                        if let amount = option.amount {
                            DetailRow(title: "Amount (cents)", value: "\(amount)")
                        }
                        
                        if let serviceZoneId = option.serviceZoneId {
                            DetailRow(title: "Service Zone ID", value: serviceZoneId)
                        }
                        
                        if let providerId = option.providerId {
                            DetailRow(title: "Provider ID", value: providerId)
                        }
                        
                        if let shippingProfileId = option.shippingProfileId {
                            DetailRow(title: "Shipping Profile ID", value: shippingProfileId)
                        }
                        
                        if let provider = option.provider {
                            DetailRow(title: "Provider Enabled", value: "\(provider.isEnabled)")
                        }
                        
                        if let type = option.type {
                            DetailRow(title: "Type ID", value: type.id)
                            if let code = type.code {
                                DetailRow(title: "Type Code", value: code)
                            }
                        }
                        
                        if let createdAt = option.createdAt {
                            DetailRow(title: "Created", value: formatDate(createdAt))
                        }
                        
                        if let updatedAt = option.updatedAt {
                            DetailRow(title: "Updated", value: formatDate(updatedAt))
                        }
                        
                        // Data and metadata
                        if let data = option.data, !data.isEmpty {
                            Text("Data:")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                            
                            ForEach(Array(data.keys.sorted()), id: \.self) { key in
                                DetailRow(title: key, value: "\(data[key] ?? "nil")")
                            }
                        }
                        
                        if let metadata = option.metadata, !metadata.isEmpty {
                            Text("Metadata:")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                            
                            ForEach(Array(metadata.keys.sorted()), id: \.self) { key in
                                DetailRow(title: key, value: "\(metadata[key] ?? "nil")")
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var priceTypeColor: Color {
        switch option.priceType.lowercased() {
        case "free":
            return .green
        case "flat_rate", "flat":
            return .blue
        case "calculated":
            return .orange
        default:
            return .gray
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .short
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

struct AddShippingMethodButton: View {
    let selectedOptionId: String
    let isLoading: Bool
    let onAddShippingMethod: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Divider()
            
            Button(action: onAddShippingMethod) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    
                    Image(systemName: "plus.circle")
                    Text("Add Shipping Method to Cart")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isLoading)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color(.systemBackground))
    }
}

struct ErrorMessageView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.red)
                Text(message)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
            }
            
            Button("Retry") {
                onRetry()
            }
            .foregroundColor(.blue)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding()
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text("\(title):")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    // Create a sample cart for preview
    let sampleCart = Cart(
        id: "cart_123",
        currencyCode: "GBP",
        customerId: nil,
        email: nil,
        regionId: "reg_123",
        createdAt: nil,
        updatedAt: nil,
        completedAt: nil,
        total: 2500,
        subtotal: 2000,
        taxTotal: 400,
        discountTotal: 0,
        discountSubtotal: 0,
        discountTaxTotal: 0,
        originalTotal: 2500,
        originalTaxTotal: 400,
        itemTotal: 2000,
        itemSubtotal: 2000,
        itemTaxTotal: 400,
        originalItemTotal: 2000,
        originalItemSubtotal: 2000,
        originalItemTaxTotal: 400,
        shippingTotal: 100,
        shippingSubtotal: 100,
        shippingTaxTotal: 0,
        originalShippingTaxTotal: 0,
        originalShippingSubtotal: 100,
        originalShippingTotal: 100,
        metadata: nil,
        salesChannelId: nil,
        items: [],
        promotions: nil,
        region: nil,
        shippingAddress: nil,
        billingAddress: nil
    )
    
    ShippingOptionsView(cart: sampleCart)
        .environmentObject(CartService())
}