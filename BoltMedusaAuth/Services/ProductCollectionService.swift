import Foundation
import Combine

class ProductCollectionService: ObservableObject {
    @Published var productCollections: [ProductCollection] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Optionally fetch collections on init
        // fetchProductCollections()
    }

    func fetchProductCollections() {
        isLoading = true
        errorMessage = nil

        NetworkManager.shared.request(endpoint: "collections")
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case let .failure(error) = completion {
                    self?.errorMessage = "Failed to fetch product collections: \(error.localizedDescription)"
                }
            }, receiveValue: { [weak self] (response: ProductCollectionsResponse) in
                self?.productCollections = response.collections
            })
            .store(in: &cancellables)
    }

    func fetchProductCollection(id: String) {
        isLoading = true
        errorMessage = nil

        NetworkManager.shared.request(endpoint: "collections/\(id)")
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case let .failure(error) = completion {
                    self?.errorMessage = "Failed to fetch product collection \(id): \(error.localizedDescription)"
                }
            }, receiveValue: { [weak self] (response: ProductCollectionResponse) in
                // Handle single collection response, e.g., add to a dictionary or a specific published property
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
