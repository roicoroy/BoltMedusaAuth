//
//  ProductCategoryService.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 02/07/2025.
//

import Foundation
import Combine

class ProductCategoryService: ObservableObject {
    @Published var productCategories: [ProductCategory] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private let networkManager: NetworkManager
    private var cancellables = Set<AnyCancellable>()

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
        // Optionally fetch categories on init
        // fetchProductCategories()
    }

    func fetchProductCategories() {
        isLoading = true
        errorMessage = nil

        networkManager.request(
            path: "/store/product-categories",
            method: "GET"
        )
        .decode(type: ProductCategoriesResponse.self, decoder: JSONDecoder())
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { [weak self] completion in
            self?.isLoading = false
            if case let .failure(error) = completion {
                self?.errorMessage = "Failed to fetch product categories: \(error.localizedDescription)"
            }
        }, receiveValue: { [weak self] response in
            self?.productCategories = response.productCategories
        })
        .store(in: &cancellables)
    }

    func fetchProductCategory(id: String) {
        isLoading = true
        errorMessage = nil

        networkManager.request(
            path: "/store/product-categories/\(id)",
            method: "GET"
        )
        .decode(type: ProductCategoryResponse.self, decoder: JSONDecoder())
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { [weak self] completion in
            self?.isLoading = false
            if case let .failure(error) = completion {
                self?.errorMessage = "Failed to fetch product category \(id): \(error.localizedDescription)"
            }
        }, receiveValue: { [weak self] response in
            print("Fetched single product category: \(response.productCategory.name)")
        })
        .store(in: &cancellables)
    }
}
