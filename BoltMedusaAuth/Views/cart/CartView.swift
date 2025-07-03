//
//  CartView.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 28/06/2025.
//

import SwiftUI

struct CartView: View {
    @EnvironmentObject var cartService: CartServiceReview
    @EnvironmentObject var regionService: RegionService
    @EnvironmentObject var authService: AuthService
    @Environment(\.presentationMode) var presentationMode
    @State private var showingCheckout = false
    @State private var showingCountrySelector = false
    @State private var showingShippingAddressSelector = false
    @State private var showingBillingAddressSelector = false
    @State private var showingAddAddress = false
    @State private var showingShippingOptions = false
    @State private var showingPaymentProviders = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Main scrollable content
                ScrollView {
                    VStack(spacing: 16) {
                        if !regionService.hasSelectedRegion {
                            // No country selected state
                            NoCountrySelectedView(showingCountrySelector: $showingCountrySelector)
                        } else if cartService.isLoading && cartService.currentCart == nil {
                            // Loading state for initial cart creation
                            LoadingCartView()
                        } else if let cart = cartService.currentCart {
                            if cart.isEmpty {
                                // Empty cart state
                                EmptyCartView(regionService: regionService)
                            } else {
                                // Cart with items
                                CartContentView(
                                    cart: cart,
                                    cartService: cartService,
                                    authService: authService,
                                    showingCheckout: $showingCheckout,
                                    showingShippingAddressSelector: $showingShippingAddressSelector,
                                    showingBillingAddressSelector: $showingBillingAddressSelector,
                                    showingAddAddress: $showingAddAddress,
                                    showingShippingOptions: $showingShippingOptions,
                                    showingPaymentProviders: $showingPaymentProviders
                                )
                            }
                        } else if regionService.hasSelectedRegion {
                            // No cart state but country is selected
                            NoCartView(
                                regionService: regionService,
                                cartService: cartService
                            )
                        }
                        
                        // Error messages
                        CartErrorMessagesView(
                            cartService: cartService,
                            regionService: regionService
                        )
                        
                        // Add some bottom padding
                        Spacer(minLength: 20)
                    }
                    .padding(.vertical)
                }
                .refreshable {
                    cartService.refreshCart()
                    regionService.refreshRegions()
                }
            }
            .navigationTitle("Shopping Cart")
            .navigationBarTitleDisplayMode(.large)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    HStack {
//                        if let cart = cartService.currentCart, !cart.isEmpty {
//                            Button("Clear") {
//                                cartService.clearCart()
//                            }
//                            .foregroundColor(.red)
//                        }
//                    }
//                }
//            }
            
        }
        .sheet(isPresented: $showingCheckout) {
            CheckoutView(cart: cartService.currentCart)
        }
        .sheet(isPresented: $showingCountrySelector) {
            SharedCountrySelectorView(regionService: regionService)
        }
        .sheet(isPresented: $showingShippingAddressSelector) {
            AddressSelectorView(
                title: "Select Shipping Address",
                addressType: .shipping,
                authService: _authService,
                cartService: _cartService
            )
        }
        .sheet(isPresented: $showingBillingAddressSelector) {
            AddressSelectorView(
                title: "Select Billing Address",
                addressType: .billing,
                authService: _authService,
                cartService: _cartService
            )
        }
        .sheet(isPresented: $showingAddAddress) {
            AddAddressView()
                .onDisappear {
                    // Refresh customer profile after address is added
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        authService.fetchCustomerProfile()
                    }
                }
        }
        .sheet(isPresented: $showingShippingOptions) {
            if let cart = cartService.currentCart {
                ShippingOptionsView(cart: cart)
                    .environmentObject(cartService)
            }
        }
        .sheet(isPresented: $showingPaymentProviders) {
            if let cart = cartService.currentCart {
                PaymentProvidersView(cart: cart)
            }
        }
        
        .onChange(of: authService.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                // When user logs in, refresh cart to get customer association
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    cartService.refreshCart()
                }
            }
        }
    }
}

// MARK: - Cart-Specific Supporting Views

struct NoCountrySelectedView: View {
    @Binding var showingCountrySelector: Bool
    
    var body: some View {
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
        .padding()
    }
}

struct LoadingCartView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading cart...")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct EmptyCartView: View {
    @ObservedObject var regionService: RegionService
    
    var body: some View {
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
        .padding()
    }
}

struct CartContentView: View {
    let cart: Cart
    @ObservedObject var cartService: CartServiceReview
    @ObservedObject var authService: AuthService
    @Binding var showingCheckout: Bool
    @Binding var showingShippingAddressSelector: Bool
    @Binding var showingBillingAddressSelector: Bool
    @Binding var showingAddAddress: Bool
    @Binding var showingShippingOptions: Bool
    @Binding var showingPaymentProviders: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Cart items
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
            .padding(.horizontal)
            
            // Cart summary with customer info and addresses
            CartSummaryView(
                cart: cart,
                authService: authService, cartService:  CartServiceReview(),
                showingShippingAddressSelector: $showingShippingAddressSelector,
                showingBillingAddressSelector: $showingBillingAddressSelector,
                showingAddAddress: $showingAddAddress,
                showingShippingOptions: $showingShippingOptions,
                showingPaymentProviders: $showingPaymentProviders
            )
            .padding(.horizontal)
            

            // Stripe Payment Button (conditional)
            if let clientSecret = cart.paymentCollection?.paymentSessions?.first?.data?["client_secret"]?.value as? String {
                NavigationLink(destination: StripePaymentView()) {
                    Text("Pay with Stripe")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
        }
    }
}

struct NoCartView: View {
    @ObservedObject var regionService: RegionService
    @ObservedObject var cartService: CartServiceReview
    
    var body: some View {
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
        .padding()
    }
}

struct CartErrorMessagesView: View {
    @ObservedObject var cartService: CartServiceReview
    @ObservedObject var regionService: RegionService
    
    var body: some View {
        VStack(spacing: 8) {
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
                .cornerRadius(8)
                .padding(.horizontal)
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
                .cornerRadius(8)
                .padding(.horizontal)
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
    @ObservedObject var authService: AuthService
    @ObservedObject var cartService: CartServiceReview
    @Binding var showingShippingAddressSelector: Bool
    @Binding var showingBillingAddressSelector: Bool
    @Binding var showingAddAddress: Bool
    @Binding var showingShippingOptions: Bool
    @Binding var showingPaymentProviders: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Customer Information Section
            CustomerInfoSection(cart: cart, authService: authService)
            
            // Shipping Address Section
            ShippingAddressSection(
                cart: cart,
                authService: authService,
                showingShippingAddressSelector: $showingShippingAddressSelector,
                showingAddAddress: $showingAddAddress
            )
            
            // Billing Address Section
            BillingAddressSection(
                cart: cart,
                authService: authService,
                showingBillingAddressSelector: $showingBillingAddressSelector,
                showingAddAddress: $showingAddAddress
            )
            
            // Shipping Options Section
            ShippingOptionsSection(
                cart: cart,
                showingShippingOptions: $showingShippingOptions
            )
            
            // Payment Providers Section
            PaymentProvidersSection(
                cart: cart,
                showingPaymentProviders: $showingPaymentProviders
            )
            
            // Promotions Selection Section
            PromotionSelectionView(cart: cart, cartService: cartService)
            
            // Price Summary Section
            PriceSummarySection(cart: cart)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CustomerInfoSection: View {
    let cart: Cart
    @ObservedObject var authService: AuthService
    
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
    @ObservedObject var authService: AuthService
    @Binding var showingShippingAddressSelector: Bool
    @Binding var showingAddAddress: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "truck.box")
                    .foregroundColor(.green)
                Text("Shipping Address")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if let shippingAddress = cart.shippingAddress {
                AddressDisplayView(address: shippingAddress, type: .shipping)
                
                // Change address button
                if authService.isAuthenticated {
                    Button("Change Shipping Address") {
                        showingShippingAddressSelector = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "location.slash")
                            .foregroundColor(.gray)
                        Text("No shipping address set")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    if authService.isAuthenticated {
                        if let customer = authService.currentCustomer,
                           let addresses = customer.addresses,
                           !addresses.isEmpty {
                            Button("Select Shipping Address") {
                                showingShippingAddressSelector = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Button("Add Shipping Address") {
                                showingAddAddress = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } else {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text("Sign in to add and save addresses")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        .padding(.top, 4)
                    }
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
    @ObservedObject var authService: AuthService
    @Binding var showingBillingAddressSelector: Bool
    @Binding var showingAddAddress: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "creditcard")
                    .foregroundColor(.purple)
                Text("Billing Address")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if let billingAddress = cart.billingAddress {
                AddressDisplayView(address: billingAddress, type: .billing)
                
                // Change address button
                if authService.isAuthenticated {
                    Button("Change Billing Address") {
                        showingBillingAddressSelector = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "location.slash")
                            .foregroundColor(.gray)
                        Text("No billing address set")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    if authService.isAuthenticated {
                        if let customer = authService.currentCustomer,
                           let addresses = customer.addresses,
                           !addresses.isEmpty {
                            Button("Select Billing Address") {
                                showingBillingAddressSelector = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            if cart.hasShippingAddress {
                                Button("Same as shipping address") {
                                    // TODO: Implement copy shipping to billing
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        } else {
                            Button("Add Billing Address") {
                                showingAddAddress = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } else {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text("Sign in to add and save addresses")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct ShippingOptionsSection: View {
    let cart: Cart
    @Binding var showingShippingOptions: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "truck.box")
                    .foregroundColor(.orange)
                Text("Shipping Options")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 8) {
                // Show current shipping total if > 0
                if cart.shippingTotal > 0 {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("Shipping method selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(cart.formattedShippingTotal)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                } else {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text("Select a shipping method to see delivery options")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                
                Button("View Shipping Options") {
                    showingShippingOptions = true
                }
                .font(.caption)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct PaymentProvidersSection: View {
    let cart: Cart
    @Binding var showingPaymentProviders: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "creditcard.circle")
                    .foregroundColor(.purple)
                Text("Payment Providers")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text("View available payment methods for this region")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                if let regionId = cart.regionId {
                    HStack {
                        Text("Region ID:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(regionId)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                }
                
                Button("View Payment Providers") {
                    showingPaymentProviders = true
                }
                .font(.caption)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity, alignment: .leading)
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
                    SummaryRow(title: "Shipping", value: cart.formattedShippingTotal, valueColor: .green)
                } else {
                    SummaryRow(title: "Shipping", value: "Not selected", valueColor: .orange)
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
                
                // Shipping status indicator
                if cart.shippingTotal > 0 {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption2)
                        Text("Shipping method selected")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Spacer()
                    }
                } else {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption2)
                        Text("Select shipping method to complete order")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct PromotionSelectionView: View {
    let cart: Cart
    @ObservedObject var cartService: CartServiceReview
    @State private var selectedPromotionCode: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "tag")
                    .foregroundColor(.pink)
                Text("Promotions")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if let promotions = cart.promotions, !promotions.isEmpty {
                Picker("Select Promotion", selection: $selectedPromotionCode) {
                    Text("None").tag(nil as String?)
                    ForEach(promotions) { promotion in
                        Text(promotion.code ?? promotion.id).tag(promotion.code ?? promotion.id as String?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: selectedPromotionCode) { newCode in
                    if let newCode = newCode, let cartId = cart.id as? String {
                        cartService.applyPromotion(cartId: cartId, promoCode: newCode) { success in
                            if success {
                                // Promotion applied, cart will refresh automatically
                            } else {
                                // Error message is already set in cartService
                            }
                        }
                    }
                }
            } else {
                Text("No promotions available for this cart.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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
            
            if let company = address.company, !company.isEmpty {
                Text(company)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(address.address1 ?? "")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let address2 = address.address2, !address2.isEmpty {
                Text(address2)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("\(address.city), \(address.province ?? "") \(address.postalCode)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(address.countryCode?.uppercased() ?? "")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let phone = address.phone, !phone.isEmpty {
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Address Selector View

struct AddressSelectorView: View {
    let title: String
    let addressType: AddressType
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var cartService: CartServiceReview
    @Environment(\.presentationMode) var presentationMode
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    enum AddressType {
        case shipping, billing
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if let customer = authService.currentCustomer,
                   let addresses = customer.addresses,
                   !addresses.isEmpty {
                    
                    List {
                        ForEach(addresses) { address in
                            AddressSelectorRow(
                                address: address,
                                addressType: addressType
                            ) {
                                selectAddress(address)
                            }
                        }
                    }
                    
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "location.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Addresses Found")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Add an address to your profile first")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                    }
                    .padding()
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    isLoading ? AnyView(ProgressView().scaleEffect(0.8)) : AnyView(EmptyView())
                }
            }
        }
    }
    
    private func selectAddress(_ address: Address) {
        guard let cart = cartService.currentCart else {
            errorMessage = "No cart found"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let completion: (Bool) -> Void = { success in
            DispatchQueue.main.async {
                self.isLoading = false
                if success {
                    // Refresh cart to show updated address
                    self.cartService.refreshCart()
                    self.presentationMode.wrappedValue.dismiss()
                } else {
                    self.errorMessage = "Failed to set address"
                }
            }
        }
        
        switch addressType {
        case .shipping:
            cartService.addShippingAddressFromCustomerAddress(addressId: address.id, completion: completion)
        case .billing:
            cartService.addBillingAddressFromCustomerAddress(addressId: address.id, completion: completion)
        }
    }
}

struct AddressSelectorRow: View {
    let address: Address
    let addressType: AddressSelectorView.AddressType
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if let addressName = address.addressName {
                        Text(addressName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    } else {
                        Text("Address")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    // Show default badges
                    HStack(spacing: 4) {
                        if addressType == .shipping && address.isDefaultShipping {
                            Text("Default")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(4)
                        }
                        
                        if addressType == .billing && address.isDefaultBilling {
                            Text("Default")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    if let company = address.company, !company.isEmpty {
                        Text(company)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let firstName = address.firstName, let lastName = address.lastName {
                        Text("\(firstName) \(lastName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(address.address1)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let address2 = address.address2, !address2.isEmpty {
                        Text(address2)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("\(address.city), \(address.province ?? "") \(address.postalCode)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(address.countryCode.uppercased())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let phone = address.phone, !phone.isEmpty {
                        HStack {
                            Image(systemName: "phone")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(phone)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CartView()
        .environmentObject(CartServiceReview())
        .environmentObject(RegionService())
        .environmentObject(AuthService())
}
