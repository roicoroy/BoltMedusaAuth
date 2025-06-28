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
    @State private var showingCountrySelector = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Country Selector Header (same as ProductsView)
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Shopping Country")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                showingCountrySelector = true
                            }) {
                                HStack {
                                    if let selectedCountry = regionService.selectedCountry {
                                        Text(selectedCountry.flagEmoji)
                                        Text(selectedCountry.label)
                                            .fontWeight(.medium)
                                        Text("(\(selectedCountry.formattedCurrency))")
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("Select Country")
                                            .foregroundColor(.blue)
                                    }
                                    
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        if regionService.isLoading || cartService.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .padding()
                .background(Color(.systemBackground))
                
                // Cart Content
                if !regionService.hasSelectedRegion {
                    // No country selected state
                    VStack(spacing: 20) {
                        Image(systemName: "globe")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        
                        Text("Select a Country")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Choose your shopping country to view your cart")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Select Country") {
                            showingCountrySelector = true
                        }
                        .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if cartService.isLoading && cartService.currentCart == nil {
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
                            
                            if let selectedCountry = regionService.selectedCountry {
                                VStack(spacing: 8) {
                                    HStack {
                                        Text("Shopping in:")
                                            .foregroundColor(.secondary)
                                        Text(selectedCountry.flagEmoji)
                                        Text(selectedCountry.label)
                                            .fontWeight(.medium)
                                        Text("(\(selectedCountry.formattedCurrency))")
                                            .foregroundColor(.secondary)
                                    }
                                    .font(.caption)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Cart with items
                        VStack(spacing: 0) {
                            // Cart items list
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(cart.items ?? []) { item in
                                        CartItemRow(
                                            item: item,
                                            currencyCode: cart.currencyCode,
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
                            
                            // Cart summary with customer info and addresses
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
                    // No cart state but country is selected
                    VStack(spacing: 20) {
                        Image(systemName: "cart.badge.questionmark")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        
                        Text("No cart found")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Start shopping to create a cart")
                            .foregroundColor(.secondary)
                        
                        if let selectedCountry = regionService.selectedCountry {
                            Button("Create Cart") {
                                cartService.createCartIfNeeded(regionId: selectedCountry.regionId)
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // Error messages
                VStack {
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
                    
                    if let errorMessage = regionService.errorMessage {
                        VStack {
                            Text("Region Error: \(errorMessage)")
                                .foregroundColor(.red)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .padding()
                            
                            Button("Retry Regions") {
                                regionService.refreshRegions()
                            }
                            .foregroundColor(.blue)
                        }
                        .background(Color(.systemGray6))
                    }
                }
            }
            .navigationTitle("Shopping Cart")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                cartService.refreshCart()
                regionService.refreshRegions()
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
        .sheet(isPresented: $showingCountrySelector) {
            CountrySelectorView(regionService: regionService)
        }
        .onChange(of: regionService.selectedCountry) { newCountry in
            // When country changes, update cart region if cart exists
            if let newCountry = newCountry {
                print("Country changed in CartView to: \(newCountry.label) (\(newCountry.currencyCode))")
                
                if cartService.currentCart != nil {
                    // Cart exists, update its region
                    cartService.createCartIfNeeded(regionId: newCountry.regionId) { success in
                        if success {
                            print("Cart updated for new country successfully")
                        } else {
                            print("Failed to update cart for new country")
                        }
                    }
                }
            }
        }
    }
}

struct CartItemRow: View {
    let item: CartLineItem
    let currencyCode: String
    let onQuantityChange: (Int) -> Void
    let onRemove: () -> Void
    
    @State private var quantity: Int
    
    init(item: CartLineItem, currencyCode: String, onQuantityChange: @escaping (Int) -> Void, onRemove: @escaping () -> Void) {
        self.item = item
        self.currencyCode = currencyCode
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
                    Text(item.formattedUnitPrice(currencyCode: currencyCode))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if item.quantity > 1 {
                        Text("× \(item.quantity)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(item.formattedTotal(currencyCode: currencyCode))
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
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        VStack(spacing: 16) {
            // Customer Information Section
            CustomerInfoSection(cart: cart)
            
            // Shipping Address Section
            ShippingAddressSection(cart: cart)
            
            // Billing Address Section
            BillingAddressSection(cart: cart)
            
            // Price Summary Section
            PriceSummarySection(cart: cart)
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

struct CustomerInfoSection: View {
    let cart: Cart
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.circle")
                    .foregroundColor(.blue)
                Text("Customer Information")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 8) {
                if cart.isAssociatedWithCustomer {
                    // Cart has customer association
                    if let customer = authService.currentCustomer {
                        // We have full customer details
                        CustomerDetailRow(title: "Name", value: "\(customer.firstName ?? "") \(customer.lastName ?? "")".trimmingCharacters(in: .whitespaces))
                        CustomerDetailRow(title: "Email", value: customer.email)
                        
                        if let phone = customer.phone {
                            CustomerDetailRow(title: "Phone", value: phone)
                        }
                        
                        if let company = customer.companyName {
                            CustomerDetailRow(title: "Company", value: company)
                        }
                        
                        CustomerDetailRow(title: "Customer ID", value: customer.id)
                        CustomerDetailRow(title: "Status", value: "Authenticated", valueColor: .green)
                    } else if let customerId = cart.customerId {
                        // Cart has customer ID but we don't have full details
                        CustomerDetailRow(title: "Customer ID", value: customerId)
                        CustomerDetailRow(title: "Status", value: "Authenticated", valueColor: .green)
                        
                        if let email = cart.email {
                            CustomerDetailRow(title: "Email", value: email)
                        }
                    }
                } else {
                    // Anonymous cart
                    CustomerDetailRow(title: "Status", value: "Anonymous Cart", valueColor: .orange)
                    CustomerDetailRow(title: "Cart ID", value: cart.id)
                    
                    if let email = cart.email {
                        CustomerDetailRow(title: "Email", value: email)
                    }
                    
                    // Suggestion to log in
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Sign in to save your cart and access faster checkout")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct ShippingAddressSection: View {
    let cart: Cart
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "truck.box")
                    .foregroundColor(.green)
                Text("Shipping Address")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                
                Button("Edit") {
                    // TODO: Implement shipping address editing
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if let shippingAddress = cart.shippingAddress {
                AddressDisplayView(address: shippingAddress, type: .shipping)
            } else {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "location.slash")
                            .foregroundColor(.gray)
                        Text("No shipping address set")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    Button("Add Shipping Address") {
                        // TODO: Implement add shipping address
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct BillingAddressSection: View {
    let cart: Cart
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "creditcard")
                    .foregroundColor(.purple)
                Text("Billing Address")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                
                Button("Edit") {
                    // TODO: Implement billing address editing
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if let billingAddress = cart.billingAddress {
                AddressDisplayView(address: billingAddress, type: .billing)
            } else {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "location.slash")
                            .foregroundColor(.gray)
                        Text("No billing address set")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    Button("Add Billing Address") {
                        // TODO: Implement add billing address
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button("Same as shipping address") {
                        // TODO: Implement copy shipping to billing
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct PriceSummarySection: View {
    let cart: Cart
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "dollarsign.circle")
                    .foregroundColor(.blue)
                Text("Order Summary")
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
                
                // Additional cart info
                HStack {
                    Text("Items: \(cart.itemCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Currency: \(cart.currencyCode.uppercased())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Views

struct CustomerDetailRow: View {
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

struct AddressDisplayView: View {
    let address: CartAddress
    let type: AddressType
    
    enum AddressType {
        case shipping, billing
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let firstName = address.firstName, let lastName = address.lastName {
                Text("\(firstName) \(lastName)")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            if let company = address.company {
                Text(company)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(address.address1)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let address2 = address.address2 {
                Text(address2)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("\(address.city), \(address.province ?? "") \(address.postalCode)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(address.countryCode.uppercased())
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let phone = address.phone {
                HStack {
                    Image(systemName: "phone")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(phone)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
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

#Preview {
    CartView()
        .environmentObject(CartService())
        .environmentObject(RegionService())
        .environmentObject(AuthService())
}