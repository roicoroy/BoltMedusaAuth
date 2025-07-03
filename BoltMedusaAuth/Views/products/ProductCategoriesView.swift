//
//  ProductCategoriesView.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 02/07/2025.
//

import SwiftUI

struct ProductCategoriesView: View {
    @StateObject var productCategoryService = ProductCategoryService()

    var body: some View {
        NavigationView {
            List(productCategoryService.productCategories) {
                category in
                NavigationLink(destination: ProductsByCategoryView(category: category)
                    .environmentObject(RegionService())
                    .environmentObject(CartService())
                    .environmentObject(AuthService())) {
                    Text(category.name ?? "")
                }
            }
            .navigationTitle("Product Categories")
            .onAppear {
                productCategoryService.fetchProductCategories()
            }
            .overlay {
                if productCategoryService.isLoading {
                    ProgressView()
                }
            }
            .alert("Error", isPresented: .constant(productCategoryService.errorMessage != nil)) {
                Button("OK") { productCategoryService.errorMessage = nil }
            } message: {
                Text(productCategoryService.errorMessage ?? "")
            }
        }
    }
}

struct ProductCategoriesView_Previews: PreviewProvider {
    static var previews: some View {
        ProductCategoriesView()
    }
}
