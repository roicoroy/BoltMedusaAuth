//
//  ProductsByCollectionView.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 02/07/2025.
//

import SwiftUI

struct ProductsByCollectionView: View {
    let collection: ProductCollection
    @StateObject private var productService = ProductService()
    @EnvironmentObject var regionService: RegionService
    @EnvironmentObject var cartService: CartServiceReview
    @EnvironmentObject var authService: AuthService
    @State private var searchText = ""

    private var filteredProducts: [Product] {
        if searchText.isEmpty {
            return productService.products
        } else {
            return productService.products.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                ($0.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            SearchBarView(searchText: $searchText)
                .padding(.horizontal)
                .padding(.bottom)

            // Products Grid
            if productService.isLoading {
                LoadingProductsView()
            } else if filteredProducts.isEmpty {
                EmptyProductsView(
                    searchText: searchText,
                    onClearSearch: { searchText = "" }
                )
            } else {
                ProductsGridView(
                    products: filteredProducts,
                    regionService: regionService
                )
            }

            // Error messages
            ErrorMessagesView(
                productService: productService,
                regionService: regionService
            )
        }
        .navigationTitle(collection.title)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            productService.fetchProducts(collectionId: collection.id)
        }
        .refreshable {
            productService.fetchProducts(collectionId: collection.id)
        }
        .onChange(of: searchText) { newValue in
            if !newValue.isEmpty && newValue.count > 2 {
                // Debounce search
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if searchText == newValue {
                        productService.searchProducts(query: newValue, collectionId: collection.id)
                    }
                }
            } else if newValue.isEmpty {
                productService.fetchProducts(collectionId: collection.id)
            }
        }
    }
}

