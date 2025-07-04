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

    private var filteredProducts: [ProductWithPrice] {
        if searchText.isEmpty {
            return productService.productsWithPrice
        } else {
            return productService.productsWithPrice.filter {
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
            if let regionId = regionService.regions.first?.id {
                productService.fetchProductsWithPrice(regionId: regionId)
            }
        }
        .refreshable {
            if let regionId = regionService.regions.first?.id {
                productService.fetchProductsWithPrice(regionId: regionId)
            }
        }
        .onChange(of: searchText) { newValue in
            if !newValue.isEmpty && newValue.count > 2 {
                // Debounce search
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if searchText == newValue {
                        if let regionId = regionService.regions.first?.id {
                            productService.searchProducts(query: newValue, regionId: regionId, collectionId: collection.id)
                        }
                        
                    }
                }
            } else if newValue.isEmpty {
                productService.fetchProducts(collectionId: collection.id)
            }
        }
    }
}

