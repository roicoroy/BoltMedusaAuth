//
//  ProductCollectionsView.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 02/07/2025.
//

import SwiftUI

struct ProductCollectionsView: View {
    @StateObject var productCollectionService = ProductCollectionService()

    var body: some View {
        NavigationView {
            List(productCollectionService.productCollections) {
                collection in
                NavigationLink(destination: ProductsByCollectionView(collection: collection)
                    .environmentObject(RegionService())
                    .environmentObject(CartService())
                    .environmentObject(AuthService())) {
                    Text(collection.title)
                }
            }
            .navigationTitle("Product Collections")
            .onAppear {
                productCollectionService.fetchProductCollections()
            }
            .overlay {
                if productCollectionService.isLoading {
                    ProgressView()
                }
            }
            .alert("Error", isPresented: .constant(productCollectionService.errorMessage != nil)) {
                Button("OK") { productCollectionService.errorMessage = nil }
            } message: {
                Text(productCollectionService.errorMessage ?? "")
            }
        }
    }
}

struct ProductCollectionsView_Previews: PreviewProvider {
    static var previews: some View {
        ProductCollectionsView()
    }
}
