//
//  ProductDetailView.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 28/06/2025.
//

import SwiftUI

struct ProductDetailView: View {
    let product: Product
    @ObservedObject var regionService: RegionService
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var cartService: CartService
    @State private var selectedVariant: ProductVariant?
    @State private var selectedImageIndex = 0
    @State private var quantity = 1
    @State private var showingAddToCartSuccess = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Product Images
                    if let images = product.images, !images.isEmpty {
                        TabView(selection: $selectedImageIndex) {
                            ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                                AsyncImage(url: URL(string: image.url)) { imageView in
                                    imageView
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color(.systemGray5))
                                        .overlay(
                                            ProgressView()
                                        )
                                }
                                .tag(index)
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                        .frame(height: 300)
                        .cornerRadius(12)
                    } else if let thumbnail = product.thumbnail {
                        AsyncImage(url: URL(string: thumbnail)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                )
                        }
                        .frame(height: 300)
                        .cornerRadius(12)
                    }
                    
                    // Product Info
                    VStack(alignment: .leading, spacing: 16) {
                        // Title and Price
                        VStack(alignment: .leading, spacing: 8) {
                            Text(product.title)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            if let subtitle = product.subtitle {
                                Text(subtitle)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text(selectedVariant?.displayPrice ?? product.displayPrice)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                if let selectedCountry = regionService.selectedCountry {
                                    Text("(\(selectedCountry.formattedCurrency))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if !product.isAvailable {
                                    Text("Contact for Availability")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.orange.opacity(0.2))
                                        .foregroundColor(.orange)
                                        .cornerRadius(6)
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Description
                        if let description = product.description {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Text(description)
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                            
                            Divider()
                        }
                        
                        // Variants
                        if let variants = product.variants, variants.count > 1 {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Variants")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 8) {
                                    ForEach(variants) { variant in
                                        VariantCard(
                                            variant: variant,
                                            isSelected: selectedVariant?.id == variant.id
                                        ) {
                                            selectedVariant = variant
                                        }
                                    }
                                }
                            }
                            
                            Divider()
                        }
                        
                        // Quantity Selector
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quantity")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            HStack {
                                Button(action: {
                                    if quantity > 1 {
                                        quantity -= 1
                                    }
                                }) {
                                    Image(systemName: "minus.circle")
                                        .font(.title2)
                                        .foregroundColor(quantity > 1 ? .blue : .gray)
                                }
                                .disabled(quantity <= 1)
                                
                                Text("\(quantity)")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .frame(minWidth: 40)
                                
                                Button(action: {
                                    quantity += 1
                                }) {
                                    Image(systemName: "plus.circle")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                                
                                Spacer()
                            }
                        }
                        
                        Divider()
                        
                        // Add to Cart Button
                        Button(action: {
                            addToCart()
                        }) {
                            HStack {
                                if cartService.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                
                                Image(systemName: "cart.badge.plus")
                                Text("Add to Cart")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canAddToCart ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(!canAddToCart)
                        
                        // Error message
                        if let errorMessage = cartService.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.horizontal)
                        }
                        
                        // Country requirement message
                        if !regionService.hasSelectedRegion {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.orange)
                                Text("Please select a country to add items to cart")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        // Product Details
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Product Details")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            VStack(spacing: 8) {
                                if let handle = product.handle {
                                    DetailRow(title: "Handle", value: handle)
                                }
                                
                                DetailRow(title: "Status", value: product.displayStatus)
                                
                                if let weight = product.weight {
                                    DetailRow(title: "Weight", value: "\(weight)g")
                                }
                                
                                if let dimensions = formatDimensions() {
                                    DetailRow(title: "Dimensions", value: dimensions)
                                }
                                
                                if let material = product.material {
                                    DetailRow(title: "Material", value: material)
                                }
                                
                                if let originCountry = product.originCountry {
                                    DetailRow(title: "Origin", value: originCountry)
                                }
                                
                                if let sku = selectedVariant?.sku ?? product.variants?.first?.sku {
                                    DetailRow(title: "SKU", value: sku)
                                }
                                
                                // Inventory Management Info
                                if let variant = selectedVariant ?? product.variants?.first {
                                    if let manageInventory = variant.manageInventory {
                                        DetailRow(title: "Inventory Managed", value: manageInventory ? "Yes" : "No")
                                    }
                                    
                                    if let allowBackorder = variant.allowBackorder {
                                        DetailRow(title: "Backorder Allowed", value: allowBackorder ? "Yes" : "No")
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Product Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .onAppear {
            selectedVariant = product.variants?.first
        }
        .alert("Added to Cart", isPresented: $showingAddToCartSuccess) {
            Button("Continue Shopping") { }
            Button("View Cart") {
                // This would navigate to cart view
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("\(product.title) has been added to your cart.")
        }
    }
    
    private var canAddToCart: Bool {
        return selectedVariant != nil && 
               regionService.hasSelectedRegion && 
               !cartService.isLoading
    }
    
    private func addToCart() {
        guard let variant = selectedVariant,
              let regionId = regionService.selectedRegionId else { 
            return 
        }
        
        cartService.addLineItem(
            variantId: variant.id, 
            quantity: quantity, 
            regionId: regionId
        ) { success in
            if success {
                showingAddToCartSuccess = true
            }
        }
    }
    
    private func formatDimensions() -> String? {
        let dimensions = [product.length, product.width, product.height].compactMap { $0 }
        guard !dimensions.isEmpty else { return nil }
        return dimensions.map { "\($0)cm" }.joined(separator: " × ")
    }
}

struct VariantCard: View {
    let variant: ProductVariant
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(variant.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(variant.displayPrice)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(variant.stockStatus)
                    .font(.caption2)
                    .foregroundColor(variant.stockStatusColor)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.blue.opacity(0.2) : Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    // Preview with minimal data since we can't create a full Product easily
    Text("Product Detail Preview")
}