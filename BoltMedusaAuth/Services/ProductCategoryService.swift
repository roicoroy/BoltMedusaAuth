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

    private let baseURL = "https://1839-2a00-23c7-dc88-f401-c478-f6a-492c-22da.ngrok-free.app"
    private let publishableKey = "pk_7b9a964b0ae6d083f0d2e70a5db350e2d6a7d93aceea46949373ff2872ead0fc"

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Optionally fetch categories on init
        // fetchProductCategories()
    }

    func fetchProductCategories() {
        isLoading = true
        errorMessage = nil

        guard let url = URL(string: "\(baseURL)/store/product-categories") else {
            errorMessage = "Invalid URL for product categories"
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(publishableKey, forHTTPHeaderField: "x-publishable-api-key")

        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
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

        guard let url = URL(string: "\(baseURL)/store/product-categories/\(id)") else {
            errorMessage = "Invalid URL for product category with ID: \(id)"
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(publishableKey, forHTTPHeaderField: "x-publishable-api-key")

        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: ProductCategoryResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case let .failure(error) = completion {
                    self?.errorMessage = "Failed to fetch product category \(id): \(error.localizedDescription)"
                }
            }, receiveValue: { [weak self] response in
                // Handle single category response, e.g., add to a dictionary or a specific published property
                print("Fetched single product category: \(response.productCategory.name)")
            })
            .store(in: &cancellables)
    }
}
