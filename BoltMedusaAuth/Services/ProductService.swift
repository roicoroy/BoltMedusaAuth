import Foundation
import Combine

class ProductService: ObservableObject {
    @Published var products: [Product] = []
    @Published var productsWithPrice: [ProductWithPrice] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Initial fetch will be handled by the views that require products with prices
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    func fetchProducts(limit: Int = 50, offset: Int = 0, categoryId: String? = nil, collectionId: String? = nil) {
        isLoading = true
        errorMessage = nil
        
        var endpoint = "products?limit=\(limit)&offset=\(offset)"
        if let categoryId = categoryId {
            endpoint += "&category_id[]=\(categoryId)"
        }
        if let collectionId = collectionId {
            endpoint += "&collection_id[]=\(collectionId)"
        }
        
        NetworkManager.shared.request(endpoint: endpoint)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "Failed to fetch products: \(error.localizedDescription)"
                }
            }, receiveValue: { [weak self] (response: ProductsResponse) in
                self?.products = response.products
            })
            .store(in: &cancellables)
    }
    
    func fetchProduct(id: String, completion: @escaping (Product?) -> Void) {
        NetworkManager.shared.request(endpoint: "products/\(id)")
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    
                }
            }, receiveValue: { (response: ProductResponse) in
                completion(response.product)
            })
            .store(in: &cancellables)
    }
    
    func fetchProductsWithPrice(regionId: String, limit: Int = 50, offset: Int = 0) {
        isLoading = true
        errorMessage = nil
        
        let endpoint = "products?fields=*variants.calculated_price&region_id=\(regionId)&limit=\(limit)&offset=\(offset)"
        
        NetworkManager.shared.request(endpoint: endpoint)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "Failed to fetch products with price: \(error.localizedDescription)"
                    print("DEBUG: Failed to fetch products with price: \(error.localizedDescription)")
                }
            }, receiveValue: { (response: ProductWithPriceResponse) in
                // Log the response for now as requested
                print("DEBUG: Fetched products with price: \(response.products)")
                self.productsWithPrice = response.products
            })
            .store(in: &cancellables)
    }
    
    func searchProducts(query: String, regionId: String, limit: Int = 50, categoryId: String? = nil, collectionId: String? = nil) {
        isLoading = true
        errorMessage = nil
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            errorMessage = "Invalid search query"
            isLoading = false
            return
        }
        
        var endpoint = "products?fields=*variants.calculated_price&region_id=\(regionId)&q=\(encodedQuery)&limit=\(limit)"
        if let categoryId = categoryId {
            endpoint += "&category_id[]=\(categoryId)"
        }
        if let collectionId = collectionId {
            endpoint += "&collection_id[]=\(collectionId)"
        }
        
        NetworkManager.shared.request(endpoint: endpoint)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "Failed to search products: \(error.localizedDescription)"
                    print("DEBUG: Failed to search products: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] (response: ProductWithPriceResponse) in
                self?.productsWithPrice = response.products
            })
            .store(in: &cancellables)
    }
}

