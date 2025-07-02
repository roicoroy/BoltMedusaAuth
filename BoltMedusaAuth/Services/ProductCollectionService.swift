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

    private let networkManager: NetworkManager
    private var cancellables = Set<AnyCancellable>()

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
        // Optionally fetch collections on init
        // fetchProductCollections()
    }

    func fetchProductCollections() {
        isLoading = true
        errorMessage = nil

        networkManager.request(
            path: "/store/collections",
            method: "GET"
        )
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

        networkManager.request(
            path: "/store/collections/\(id)",
            method: "GET"
        )
        .decode(type: ProductCollectionResponse.self, decoder: JSONDecoder())
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { [weak self] completion in
            self?.isLoading = false
            if case let .failure(error) = completion {
                self?.errorMessage = "Failed to fetch product collection \(id): \(error.localizedDescription)"
            }
        }, receiveValue: { [weak self] response in
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

 public struct ProductCollectionResponse: Codable {
     let collection: ProductCollection

    enum CodingKeys: String, CodingKey {
        case collection
    }
}
