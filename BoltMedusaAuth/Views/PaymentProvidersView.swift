//
//  PaymentProvidersView.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 01/07/2025.
//

import SwiftUI

struct PaymentProvidersView: View {
    let cart: Cart
    @StateObject private var paymentProvidersService = PaymentProvidersService()
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedProviderId: String?
    @State private var isCreatingPaymentCollection = false
    @State private var showingSuccessAlert = false
    @State private var successMessage = ""
    @EnvironmentObject var cartService: CartService // Added EnvironmentObject
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Info
//            PaymentCartInfoHeader(cart: cart)
            
            // Main Content
            if paymentProvidersService.isLoading {
                LoadingPaymentProvidersView()
            } else if paymentProvidersService.paymentProviders.isEmpty && paymentProvidersService.errorMessage == nil {
                EmptyPaymentProvidersView(
                    onRetry: {
                        paymentProvidersService.fetchPaymentProviders(for: cart)
                    }
                )
            } else if !paymentProvidersService.paymentProviders.isEmpty {
                PaymentProvidersListView(
                    paymentProviders: paymentProvidersService.paymentProviders,
                    selectedProviderId: $selectedProviderId,
                    onSelectProvider: { providerId in
                        selectedProviderId = providerId
                        logProviderSelection(providerId: providerId)
                        // Update cart with selected payment provider
                        if let paymentCollectionId = cart.paymentCollection?.id {
                            cartService.updateCartPaymentProvider(cartId: cart.id, paymentCollectionId: paymentCollectionId, providerId: providerId) { success in
                                if success {
                                    print("💳 ✅ Cart payment provider updated successfully.")
                                } else {
                                    print("💳 ❌ Failed to update cart payment provider.")
                                }
                            }
                        } else {
                            print("💳 ❌ Payment collection is nil, cannot update payment provider.")
                        }
                    }
                )
            }
            
            // Error Message
            if let errorMessage = paymentProvidersService.errorMessage {
                PaymentErrorMessageView(
                    message: errorMessage,
                    onRetry: {
                        paymentProvidersService.fetchPaymentProviders(for: cart)
                    }
                )
            }
            
            // Create Payment Collection Button
            if let selectedProviderId = selectedProviderId, selectedProviderId == "pp_stripe_stripe" {
                CreatePaymentCollectionButton(
                    selectedProviderId: selectedProviderId,
                    isLoading: isCreatingPaymentCollection,
                    onCreatePaymentCollection: {
                        createPaymentCollection(providerId: selectedProviderId)
                    }
                )
            }
            
            Spacer()
        }
        .navigationTitle("Payment Providers")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Refresh") {
                    paymentProvidersService.fetchPaymentProviders(for: cart)
                }
                .disabled(paymentProvidersService.isLoading)
            }
        }
        .onAppear {
            paymentProvidersService.fetchPaymentProviders(for: cart)
            selectedProviderId = cart.paymentCollection?.paymentProviders?.first?.id
            paymentProvidersService.cartService = cartService // Inject CartService
        }
        .alert("Payment Collection Created", isPresented: $showingSuccessAlert) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text(successMessage)
        }
    }
    
    private func logProviderSelection(providerId: String) {
        print("💳 PAYMENT PROVIDER SELECTED:")
        print("💳 ========================")
        print("💳 Provider ID: \(providerId)")
        print("💳 Cart ID: \(cart.id)")
        print("💳 Cart Total: \(cart.formattedTotal)")
        print("💳 Cart Currency: \(cart.currencyCode)")
        print("💳 Region ID: \(cart.regionId ?? "nil")")
        
        // Find the selected provider for additional details
        if let selectedProvider = paymentProvidersService.paymentProviders.first(where: { $0.id == providerId }) {
            print("💳 Provider Name: \(selectedProvider.displayName)")
            print("💳 Provider Type: \(selectedProvider.providerType.displayName)")
            print("💳 Provider Status: \(selectedProvider.statusText)")
            print("💳 Provider Available: \(selectedProvider.isAvailable)")
        }
        
        print("💳 ========================")
    }
    
    private func createPaymentCollection(providerId: String) {
        print("💳 CREATING PAYMENT COLLECTION:")
        print("💳 =============================")
        print("💳 Provider ID: \(providerId)")
        print("💳 Cart ID: \(cart.id)")
        
        isCreatingPaymentCollection = true
        
        paymentProvidersService.createPaymentCollection(cartId: cart.id) { success, paymentCollection in
            DispatchQueue.main.async {
                self.isCreatingPaymentCollection = false
                
                if success, let paymentCollection = paymentCollection {
                    print("💳 ✅ PAYMENT COLLECTION CREATED SUCCESSFULLY:")
                    
                    self.successMessage = "Payment collection created"
                    self.showingSuccessAlert = true
                    // After successful creation, update the cart service with the new payment collection
                    self.cartService.currentCart?.paymentCollection = paymentCollection
                    self.cartService.saveCartToStorage()
                } else {
                    print("💳 ❌ FAILED TO CREATE PAYMENT COLLECTION")
                    // Error is already handled by paymentProvidersService.errorMessage
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct PaymentCartInfoHeader: View {
    let cart: Cart
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Payment Information")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("Region ID:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(cart.regionId ?? "Unknown")
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
                    Text("Cart Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(cart.formattedTotal)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Status")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: cart.isReadyForCheckout ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(cart.isReadyForCheckout ? .green : .orange)
                            .font(.caption)
                        
                        Text(cart.isReadyForCheckout ? "Ready" : "Incomplete")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(cart.isReadyForCheckout ? .green : .orange)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding()
    }
}

struct LoadingPaymentProvidersView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading payment providers...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyPaymentProvidersView: View {
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Payment Providers Available")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("No payment providers were found for this region. This might be because:")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("• No payment providers are configured for this region")
                Text("• All payment providers are disabled")
                Text("• Region configuration is incomplete")
                Text("• Network connectivity issues")
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

struct PaymentProvidersListView: View {
    let paymentProviders: [PaymentProvider]
    @Binding var selectedProviderId: String?
    let onSelectProvider: (String) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(paymentProviders) { provider in
                    PaymentProviderCard(
                        provider: provider,
                        isSelected: selectedProviderId == provider.id,
                        onTap: {
                            onSelectProvider(provider.id)
                        }
                    )
                }
            }
            .padding()
        }
    }
}

struct PaymentProviderCard: View {
    let provider: PaymentProvider
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with icon, name and status
                HStack {
                    // Provider icon
                    Image(systemName: provider.iconName)
                        .font(.title2)
                        .foregroundColor(provider.iconColor)
                        .frame(width: 40, height: 40)
                        .background(provider.iconColor.opacity(0.1))
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(provider.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("ID: \(provider.id)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        // Status badge
                        HStack {
                            Image(systemName: provider.isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(provider.statusColor)
                            
                            Text(provider.statusText)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(provider.statusColor)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(provider.statusColor.opacity(0.1))
                        .cornerRadius(6)
                        
                        // Selection indicator
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.blue)
                        } else {
                            Image(systemName: "circle")
                                .font(.title3)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // Description
                if !provider.displayDescription.isEmpty {
                    Text(provider.displayDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                // Provider type badge
                HStack {
                    Text(provider.providerType.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(provider.iconColor.opacity(0.2))
                        .foregroundColor(provider.iconColor)
                        .cornerRadius(6)
                    
                    Spacer()
                }
                
                // Supported payment methods
                VStack(alignment: .leading, spacing: 8) {
                    Text("Supported Payment Methods:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 4) {
                        ForEach(provider.supportedMethods, id: \.self) { method in
                            HStack {
                                Image(systemName: "checkmark")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                                
                                Text(method)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // Technical details (collapsible)
                DisclosureGroup("Technical Details") {
                    VStack(alignment: .leading, spacing: 4) {
                        DetailRow(title: "Provider ID", value: provider.id)
                        
                        if let name = provider.name {
                            DetailRow(title: "Name", value: name)
                        }
                        
                        if let description = provider.description {
                            DetailRow(title: "Description", value: description)
                        }
                        
                        if let isEnabled = provider.isEnabled {
                            DetailRow(title: "Enabled", value: "\(isEnabled)")
                        }
                        
                        DetailRow(title: "Provider Type", value: provider.providerType.displayName)
                        DetailRow(title: "Available", value: "\(provider.isAvailable)")
                        
                        // Metadata
                        if let metadata = provider.metadata, !metadata.isEmpty {
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
}

struct CreatePaymentCollectionButton: View {
    let selectedProviderId: String
    let isLoading: Bool
    let onCreatePaymentCollection: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Divider()
            
            Button(action: onCreatePaymentCollection) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    
                    Image(systemName: "plus.circle")
                    Text("Create Payment Collection")
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

struct PaymentErrorMessageView: View {
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

// MARK: - Extensions

extension PaymentProviderType {
    var displayName: String {
        switch self {
        case .stripe:
            return "Stripe"
        case .paypal:
            return "PayPal"
        case .manual:
            return "Manual Payment"
        case .klarna:
            return "Klarna"
        case .applePay:
            return "Apple Pay"
        case .googlePay:
            return "Google Pay"
        case .razorpay:
            return "Razorpay"
        case .square:
            return "Square"
        case .adyen:
            return "Adyen"
        case .other:
            return "Other"
        }
    }
}
