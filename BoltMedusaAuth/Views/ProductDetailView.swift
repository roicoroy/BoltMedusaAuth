//
//  ProductDetailView.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 28/06/2025.
//

import SwiftUI

struct ProductDetailView: View {
    let product: Product
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedVariant: ProductVariant?
    @State private var selectedImageIndex = 0
    
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
                                
                                Spacer()
                                
                                if !product.isAvailable {
                                    Text("Out of Stock")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.red.opacity(0.2))
                                        .foregroundColor(.red)
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
                        
                        // Product Details
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Product Details")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            VStack(spacing: 8) {
                                if let handle = product.handle {
                                    DetailRow(title: "Handle", value: handle)
                                }
                                
                                DetailRow(title: "Status", value: product.status.rawValue.capitalized)
                                
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
                                
                                if let collection = product.collection {
                                    DetailRow(title: "Collection", value: collection.title)
                                }
                                
                                if let type = product.type {
                                    DetailRow(title: "Type", value: type.value)
                                }
                                
                                if let sku = selectedVariant?.sku ?? product.variants?.first?.sku {
                                    DetailRow(title: "SKU", value: sku)
                                }
                            }
                        }
                        
                        // Categories
                        if let categories = product.categories, !categories.isEmpty {
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Categories")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 8) {
                                    ForEach(categories) { category in
                                        Text(category.name)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.blue.opacity(0.2))
                                            .foregroundColor(.blue)
                                            .cornerRadius(6)
                                    }
                                }
                            }
                        }
                        
                        // Tags
                        if let tags = product.tags, !tags.isEmpty {
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Tags")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 8) {
                                    ForEach(tags) { tag in
                                        Text(tag.value)
                                            .font(.caption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(Color.green.opacity(0.2))
                                            .foregroundColor(.green)
                                            .cornerRadius(4)
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
                    .foregroundColor(variant.isInStock ? .green : (variant.allowBackorder ? .orange : .red))
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
    let sampleProduct = Product(
        id: "prod_01",
        title: "Sample Product",
        subtitle: "A great product",
        description: "This is a detailed description of the sample product.",
        handle: "sample-product",
        isGiftcard: false,
        status: .published,
        images: nil,
        thumbnail: nil,
        options: nil,
        variants: nil,
        categories: nil,
        collection: nil,
        collectionId: nil,
        type: nil,
        typeId: nil,
        tags: nil,
        weight: 500,
        length: 10,
        height: 5,
        width: 8,
        hsCode: nil,
        originCountry: "US",
        midCode: nil,
        material: "Cotton",
        discountable: true,
        externalId: nil,
        createdAt: "2023-01-01T00:00:00Z",
        updatedAt: "2023-01-01T00:00:00Z",
        deletedAt: nil,
        metadata: nil
    )
    
    ProductDetailView(product: sampleProduct)
}