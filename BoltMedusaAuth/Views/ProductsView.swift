//
//  ProductsView.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 28/06/2025.
//

import SwiftUI

struct ProductsView: View {
    @StateObject private var productService = ProductService()
    @State private var searchText = ""
    @State private var selectedProduct: Product?
    @State private var showingProductDetail = false
    
    private var filteredProducts: [Product] {
        if searchText.isEmpty {
            return productService.products
        } else {
            return productService.products.filter { product in
                product.title.localizedCaseInsensitiveContains(searchText) ||
                (product.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search products...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .padding()
                .background(Color(.systemBackground))
                
                // Products Grid
                if productService.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading products...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredProducts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "cube.box")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No products found")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        if !searchText.isEmpty {
                            Text("Try adjusting your search")
                                .foregroundColor(.secondary)
                            
                            Button("Clear Search") {
                                searchText = ""
                            }
                            .foregroundColor(.blue)
                        } else {
                            Text("No products available")
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8)
                        ], spacing: 16) {
                            ForEach(filteredProducts) { product in
                                ProductCard(product: product) {
                                    selectedProduct = product
                                    showingProductDetail = true
                                }
                            }
                        }
                        .padding()
                    }
                }
                
                // Error message
                if let errorMessage = productService.errorMessage {
                    VStack {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("Retry") {
                            productService.fetchProducts()
                        }
                        .foregroundColor(.blue)
                    }
                    .background(Color(.systemGray6))
                }
            }
            .navigationTitle("Products")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                productService.fetchProducts()
            }
        }
        .sheet(isPresented: $showingProductDetail) {
            if let product = selectedProduct {
                ProductDetailView(product: product)
            }
        }
        .onChange(of: searchText) { newValue in
            if !newValue.isEmpty && newValue.count > 2 {
                // Debounce search
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if searchText == newValue {
                        productService.searchProducts(query: newValue)
                    }
                }
            } else if newValue.isEmpty {
                productService.fetchProducts()
            }
        }
    }
}

struct ProductCard: View {
    let product: Product
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Product Image
                AsyncImage(url: URL(string: product.displayImage ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.title)
                                .foregroundColor(.gray)
                        )
                }
                .frame(height: 120)
                .clipped()
                .cornerRadius(8)
                
                // Product Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if let subtitle = product.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    HStack {
                        Text(product.displayPrice)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if !product.isAvailable {
                            Text("Contact Us")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .cornerRadius(4)
                        }
                    }
                    
                    // Status indicator
                    if let status = product.status {
                        Text(status.rawValue.capitalized)
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(statusColor(for: status).opacity(0.2))
                            .foregroundColor(statusColor(for: status))
                            .cornerRadius(3)
                    }
                }
                .padding(.horizontal, 4)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func statusColor(for status: ProductStatus) -> Color {
        switch status {
        case .published:
            return .green
        case .draft:
            return .orange
        case .proposed:
            return .blue
        case .rejected:
            return .red
        }
    }
}

#Preview {
    ProductsView()
}