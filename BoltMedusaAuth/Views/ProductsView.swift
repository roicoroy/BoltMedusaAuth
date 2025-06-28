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
    @State private var selectedCategory: ProductCategory?
    @State private var showingCategories = false
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
                // Search and Filter Bar
                VStack(spacing: 12) {
                    // Search Bar
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
                    
                    // Category Filter
                    HStack {
                        Button(action: {
                            showingCategories = true
                        }) {
                            HStack {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                Text(selectedCategory?.name ?? "All Categories")
                                    .lineLimit(1)
                                Spacer()
                                Image(systemName: "chevron.down")
                            }
                            .padding()
                            .background(selectedCategory != nil ? Color.blue.opacity(0.1) : Color(.systemGray6))
                            .cornerRadius(8)
                            .foregroundColor(selectedCategory != nil ? .blue : .primary)
                        }
                        
                        if selectedCategory != nil {
                            Button(action: {
                                selectedCategory = nil
                                productService.fetchProducts()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                
                // Active Filter Indicator
                if let category = selectedCategory {
                    HStack {
                        Text("Filtered by: \(category.name)")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        let productCount = productService.getCategoryProductCount(for: category.id)
                        if productCount > 0 {
                            Text("\(filteredProducts.count) products")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                
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
                        
                        if selectedCategory != nil {
                            Text("No products in this category")
                                .foregroundColor(.secondary)
                            
                            Button("View All Products") {
                                selectedCategory = nil
                                productService.fetchProducts()
                            }
                            .foregroundColor(.blue)
                        } else if !searchText.isEmpty {
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
                            if let category = selectedCategory {
                                productService.filterProductsByCategory(category.id)
                            } else {
                                productService.fetchProducts()
                            }
                        }
                        .foregroundColor(.blue)
                    }
                    .background(Color(.systemGray6))
                }
            }
            .navigationTitle("Products")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                if let category = selectedCategory {
                    productService.filterProductsByCategory(category.id)
                } else {
                    productService.fetchProducts()
                }
            }
        }
        .sheet(isPresented: $showingCategories) {
            CategorySelectionView(
                categories: productService.categories,
                selectedCategory: $selectedCategory,
                productService: productService,
                onCategorySelected: { category in
                    if let category = category {
                        productService.filterProductsByCategory(category.id)
                    } else {
                        productService.fetchProducts()
                    }
                }
            )
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
                if let category = selectedCategory {
                    productService.filterProductsByCategory(category.id)
                } else {
                    productService.fetchProducts()
                }
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
                    
                    // Categories badges
                    if !product.categoryNames.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 4) {
                                ForEach(product.categoryNames.prefix(2), id: \.self) { categoryName in
                                    Text(categoryName)
                                        .font(.caption2)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.2))
                                        .foregroundColor(.blue)
                                        .cornerRadius(3)
                                }
                                
                                if product.categoryNames.count > 2 {
                                    Text("+\(product.categoryNames.count - 2)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    HStack {
                        Text(product.displayPrice)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if !product.isAvailable {
                            Text("Out of Stock")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.2))
                                .foregroundColor(.red)
                                .cornerRadius(4)
                        }
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
}

struct CategorySelectionView: View {
    let categories: [ProductCategory]
    @Binding var selectedCategory: ProductCategory?
    let productService: ProductService
    let onCategorySelected: (ProductCategory?) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    // Organize categories by hierarchy using the service methods
    private var topLevelCategories: [ProductCategory] {
        return productService.getTopLevelCategories()
    }
    
    private func childCategories(for parentId: String) -> [ProductCategory] {
        return productService.getChildCategories(for: parentId)
    }
    
    var body: some View {
        NavigationView {
            List {
                // All Categories option
                Button(action: {
                    selectedCategory = nil
                    onCategorySelected(nil)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("All Categories")
                                .foregroundColor(.primary)
                                .fontWeight(.medium)
                            
                            Text("View all products")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedCategory == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // Top-level categories
                ForEach(topLevelCategories) { category in
                    CategoryRow(
                        category: category,
                        isSelected: selectedCategory?.id == category.id,
                        childCategories: childCategories(for: category.id),
                        selectedCategory: $selectedCategory,
                        productService: productService,
                        onCategorySelected: onCategorySelected,
                        presentationMode: presentationMode
                    )
                }
                
                // Orphaned categories (categories without valid parent)
                let orphanedCategories = categories.filter { category in
                    !category.isTopLevel && 
                    !topLevelCategories.contains { $0.id == category.parentCategoryId }
                }
                
                if !orphanedCategories.isEmpty {
                    Section("Other Categories") {
                        ForEach(orphanedCategories) { category in
                            CategoryRow(
                                category: category,
                                isSelected: selectedCategory?.id == category.id,
                                childCategories: [],
                                selectedCategory: $selectedCategory,
                                productService: productService,
                                onCategorySelected: onCategorySelected,
                                presentationMode: presentationMode
                            )
                        }
                    }
                }
            }
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct CategoryRow: View {
    let category: ProductCategory
    let isSelected: Bool
    let childCategories: [ProductCategory]
    @Binding var selectedCategory: ProductCategory?
    let productService: ProductService
    let onCategorySelected: (ProductCategory?) -> Void
    let presentationMode: Binding<PresentationMode>
    
    @State private var isExpanded = false
    
    private var hasChildren: Bool {
        return productService.hasChildCategories(categoryId: category.id)
    }
    
    private var productCount: Int {
        return productService.getCategoryProductCount(for: category.id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main category row
            Button(action: {
                selectedCategory = category
                onCategorySelected(category)
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(category.name)
                                .foregroundColor(.primary)
                                .fontWeight(category.isTopLevel ? .medium : .regular)
                            
                            if hasChildren {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isExpanded.toggle()
                                    }
                                }) {
                                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                        if let description = category.description {
                            Text(description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        
                        if productCount > 0 {
                            Text("\(productCount) products")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // Child categories (if expanded)
            if isExpanded && !childCategories.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(childCategories) { childCategory in
                        Button(action: {
                            selectedCategory = childCategory
                            onCategorySelected(childCategory)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Text("  • \(childCategory.name)")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if selectedCategory?.id == childCategory.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding(.leading, 16)
                    }
                }
                .padding(.top, 8)
            }
        }
    }
}

#Preview {
    ProductsView()
}