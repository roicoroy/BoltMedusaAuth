//
//  ProductCollectionService.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 02/07/2025.
//

import Foundation
import Combine

class ProductCollectionService: ObservableObject {
    @Published var productCollections: [ProductCollection] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private let baseURL = "https://1839-2a00-23c7-dc88-f401-c478-f6a-492c-22da.ngrok-free.app"
    private let publishableKey = "pk_7b9a964b0ae6d083f0d2e70a5db350e2d6a7d93aceea46949373ff2872ead0fc"

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Optionally fetch collections on init
        // fetchProductCollections()
    }

    func fetchProductCollections() {
        isLoading = true
        errorMessage = nil

        guard let url = URL(string: "\(baseURL)/store/collections") else {
            errorMessage = "Invalid URL for product collections"
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
            .decode(type: ProductCollectionsResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case let .failure(error) = completion {
                    self?.errorMessage = "Failed to fetch product collections: \(error.localizedDescription)"
                }
            }, receiveValue: { [weak self] response in
                self?.productCollections = response.collections
            })
            .store(in: &cancellables)
    }

    func fetchProductCollection(id: String) {
        isLoading = true
        errorMessage = nil

        guard let url = URL(string: "\(baseURL)/store/collections/\(id)") else {
            errorMessage = "Invalid URL for product collection with ID: \(id)"
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
            .decode(type: ProductCollectionResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case let .failure(error) = completion {
                    self?.errorMessage = "Failed to fetch product collection \(id): \(error.localizedDescription)"
                }
            }, receiveValue: { [weak self] response in
                // Handle single collection response, e.g., add to a dictionary or a specific published property
                print("Fetched single product collection: \(response.collection.title)")
            })
            .store(in: &cancellables)
    }
}

// MARK: - API Request/Response Models for Product Collections
 struct ProductCollectionsResponse: Codable {
     let limit: Int
     let offset: Int
     let count: Int
     let collections: [ProductCollection]

    enum CodingKeys: String, CodingKey {
        case limit, offset, count
        case collections
    }
}

 struct ProductCollectionResponse: Codable {
     let collection: ProductCollection

    enum CodingKeys: String, CodingKey {
        case collection
    }
}
