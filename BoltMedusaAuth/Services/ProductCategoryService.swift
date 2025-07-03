import Foundation
import Combine

class ProductCategoryService: ObservableObject {
    @Published var productCategories: [ProductCategory] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Optionally fetch categories on init
        // fetchProductCategories()
    }

    func fetchProductCategories() {
        isLoading = true
        errorMessage = nil

        NetworkManager.shared.request(endpoint: "product-categories")
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case let .failure(error) = completion {
                    self?.errorMessage = "Failed to fetch product categories: \(error.localizedDescription)"
                }
            }, receiveValue: { [weak self] (response: ProductCategoriesResponse) in
                self?.productCategories = response.productCategories
            })
            .store(in: &cancellables)
    }

    func fetchProductCategory(id: String) {
        isLoading = true
        errorMessage = nil

        NetworkManager.shared.request(endpoint: "product-categories/\(id)")
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case let .failure(error) = completion {
                    self?.errorMessage = "Failed to fetch product category \(id): \(error.localizedDescription)"
                }
            }, receiveValue: { [weak self] (response: ProductCategoryResponse) in
                // Handle single category response, e.g., add to a dictionary or a specific published property
                print("Fetched single product category: \(response.productCategory.name ?? "N/A")")
            })
            .store(in: &cancellables)
    }
}
