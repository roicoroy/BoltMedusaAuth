//
//  ProductsByCategoryView.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 02/07/2025.
//

import SwiftUI

struct ProductsByCategoryView: View {
    let category: ProductCategory
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
        .navigationTitle(category.name ?? "Category")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            productService.fetchProducts(categoryId: category.id)
        }
        .refreshable {
            productService.fetchProducts(categoryId: category.id)
        }
        .onChange(of: searchText) { newValue in
            if !newValue.isEmpty && newValue.count > 2 {
                // Debounce search
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if searchText == newValue {
                        productService.searchProducts(query: newValue, categoryId: category.id)
                    }
                }
            } else if newValue.isEmpty {
                productService.fetchProducts(categoryId: category.id)
            }
        }
    }
}

//struct ProductsByCategoryView_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationView {
//            ProductsByCategoryView(category: {
//                let category = ProductCategory(id: "test_id", name: "Electronics", description: "", handle: "electronics", rank: 0, parentCategoryId: nil, parentCategory: nil, categoryChildren: nil, createdAt: "2023-01-01T00:00:00Z", updatedAt: "2023-01-01T00:00:00Z", deletedAt: nil)
//                return category
//            }())
//                .environmentObject(RegionService())
//                .environmentObject(CartService())
//                .environmentObject(AuthService())
//        }
//    }
//}
