//
//  CartView.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 28/06/2025.
//

import SwiftUI

struct CartView: View {
    @EnvironmentObject var cartService: CartService
    @EnvironmentObject var regionService: RegionService
    @State private var showingCheckout = false
    @State private var showingRegionSelector = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Region Header (if no region selected)
                if !regionService.hasSelectedRegion {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Region Required")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Please select a shopping region to view your cart")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        Button(action: {
                            showingRegionSelector = true
                        }) {
                            Text("Select Region")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .padding()
                }
                
                if cartService.isLoading && cartService.currentCart == nil {
                    // Loading state for initial cart creation
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading cart...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let cart = cartService.currentCart {
                    if cart.isEmpty {
                        // Empty cart state
                        VStack(spacing: 20) {
                            Image(systemName: "cart")
                                .font(.system(size: 80))
                                .foregroundColor(.gray)
                            
                            Text("Your cart is empty")
                                .font(.title2)
                                .fontWeight(.medium)
                            
                            Text("Add some products to get started")
                                .foregroundColor(.secondary)
                            
                            if let selectedRegion = regionService.selectedRegion {
                                VStack(spacing: 8) {
                                    HStack {
                                        Text("Shopping in:")
                                            .foregroundColor(.secondary)
                                        Text(selectedRegion.flagEmoji)
                                        Text(selectedRegion.name)
                                            .fontWeight(.medium)
                                        Text("(\(selectedRegion.formattedCurrency))")
                                            .foregroundColor(.secondary)
                                    }
                                    .font(.caption)
                                    
                                    Button("Change Region") {
                                        showingRegionSelector = true
                                    }
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Cart with items
                        VStack(spacing: 0) {
                            // Current region display
                            if let selectedRegion = regionService.selectedRegion {
                                HStack {
                                    Text("Shopping in:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(selectedRegion.flagEmoji)
                                    Text(selectedRegion.name)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Text("(\(selectedRegion.formattedCurrency))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Button("Change") {
                                        showingRegionSelector = true
                                    }
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                            }
                            
                            // Cart items list
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(cart.items ?? []) { item in
                                        CartItemRow(
                                            item: item,
                                            onQuantityChange: { newQuantity in
                                                if newQuantity > 0 {
                                                    cartService.updateLineItem(
                                                        lineItemId: item.id,
                                                        quantity: newQuantity
                                                    )
                                                } else {
                                                    cartService.removeLineItem(lineItemId: item.id)
                                                }
                                            },
                                            onRemove: {
                                                cartService.removeLineItem(lineItemId: item.id)
                                            }
                                        )
                                    }
                                }
                                .padding()
                            }
                            
                            Divider()
                            
                            // Cart summary
                            CartSummaryView(cart: cart)
                            
                            // Checkout button
                            Button(action: {
                                showingCheckout = true
                            }) {
                                HStack {
                                    Text("Proceed to Checkout")
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    Text(cart.formattedTotal)
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .padding()
                        }
                    }
                } else if regionService.hasSelectedRegion {
                    // No cart state but region is selected
                    VStack(spacing: 20) {
                        Image(systemName: "cart.badge.questionmark")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        
                        Text("No cart found")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Start shopping to create a cart")
                            .foregroundColor(.secondary)
                        
                        if let selectedRegion = regionService.selectedRegion {
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Shopping in:")
                                        .foregroundColor(.secondary)
                                    Text(selectedRegion.flagEmoji)
                                    Text(selectedRegion.name)
                                        .fontWeight(.medium)
                                    Text("(\(selectedRegion.formattedCurrency))")
                                        .foregroundColor(.secondary)
                                }
                                .font(.caption)
                                
                                Button("Create Cart") {
                                    cartService.createCartIfNeeded(regionId: selectedRegion.id)
                                }
                                .foregroundColor(.blue)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // No region selected and no cart
                    VStack(spacing: 20) {
                        Image(systemName: "globe")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        
                        Text("Select a Region")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Choose your shopping region to get started")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Select Region") {
                            showingRegionSelector = true
                        }
                        .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // Error message
                if let errorMessage = cartService.errorMessage {
                    VStack {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("Retry") {
                            cartService.refreshCart()
                        }
                        .foregroundColor(.blue)
                    }
                    .background(Color(.systemGray6))
                }
            }
            .navigationTitle("Shopping Cart")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                cartService.refreshCart()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let cart = cartService.currentCart, !cart.isEmpty {
                        Button("Clear") {
                            cartService.clearCart()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCheckout) {
            CheckoutView(cart: cartService.currentCart)
        }
        .sheet(isPresented: $showingRegionSelector) {
            RegionSelectorView(regionService: regionService)
        }
    }
}

struct CartItemRow: View {
    let item: CartLineItem
    let onQuantityChange: (Int) -> Void
    let onRemove: () -> Void
    
    @State private var quantity: Int
    
    init(item: CartLineItem, onQuantityChange: @escaping (Int) -> Void, onRemove: @escaping () -> Void) {
        self.item = item
        self.onQuantityChange = onQuantityChange
        self.onRemove = onRemove
        self._quantity = State(initialValue: item.quantity)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Product image
            AsyncImage(url: URL(string: item.displayImage ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 80, height: 80)
            .clipped()
            .cornerRadius(8)
            
            // Product info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                if let subtitle = item.displaySubtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                if let sku = item.variantSku {
                    Text("SKU: \(sku)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(item.formattedUnitPrice)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if item.quantity > 1 {
                        Text("× \(item.quantity)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(item.formattedTotal)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
            
            Spacer()
            
            // Quantity controls
            VStack(spacing: 8) {
                // Remove button
                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                // Quantity stepper
                HStack(spacing: 8) {
                    Button(action: {
                        if quantity > 1 {
                            quantity -= 1
                            onQuantityChange(quantity)
                        }
                    }) {
                        Image(systemName: "minus.circle")
                            .foregroundColor(quantity > 1 ? .blue : .gray)
                    }
                    .disabled(quantity <= 1)
                    
                    Text("\(quantity)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(minWidth: 20)
                    
                    Button(action: {
                        quantity += 1
                        onQuantityChange(quantity)
                    }) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .onChange(of: item.quantity) { newValue in
            quantity = newValue
        }
    }
}

struct CartSummaryView: View {
    let cart: Cart
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Cart Summary")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 8) {
                SummaryRow(title: "Subtotal", value: cart.formattedSubtotal)
                
                if cart.taxTotal > 0 {
                    SummaryRow(title: "Tax", value: cart.formattedTaxTotal)
                }
                
                if cart.shippingTotal > 0 {
                    SummaryRow(title: "Shipping", value: cart.formattedShippingTotal)
                }
                
                if cart.discountTotal > 0 {
                    SummaryRow(title: "Discount", value: "-\(cart.formattedDiscountTotal)", valueColor: .green)
                }
                
                Divider()
                
                HStack {
                    Text("Total")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Text(cart.formattedTotal)
                        .font(.headline)
                        .fontWeight(.bold)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

struct SummaryRow: View {
    let title: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
        }
    }
}

struct CheckoutView: View {
    let cart: Cart?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "creditcard")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Checkout")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Checkout functionality would be implemented here")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                if let cart = cart {
                    Text("Total: \(cart.formattedTotal)")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Checkout")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct RegionSelectorView: View {
    @ObservedObject var regionService: RegionService
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if regionService.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading regions...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if regionService.regions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "globe")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No regions available")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Button("Retry") {
                            regionService.refreshRegions()
                        }
                        .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(regionService.regions) { region in
                            RegionRow(
                                region: region,
                                isSelected: regionService.selectedRegion?.id == region.id
                            ) {
                                regionService.selectRegion(region)
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                }
                
                if let errorMessage = regionService.errorMessage {
                    VStack {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("Retry") {
                            regionService.refreshRegions()
                        }
                        .foregroundColor(.blue)
                    }
                    .background(Color(.systemGray6))
                }
            }
            .navigationTitle("Select Region")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct RegionRow: View {
    let region: Region
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(region.flagEmoji)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(region.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(region.formattedCurrency)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if !region.countryNames.isEmpty && region.countryNames != "No countries" {
                        Text(region.countryNames)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CartView()
        .environmentObject(CartService())
        .environmentObject(RegionService())
}