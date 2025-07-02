//
//  ProductService.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 28/06/2025.
//

import Foundation
import Combine

class ProductService: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkManager: NetworkManager
    private var cancellables = Set<AnyCancellable>()
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
        fetchProducts()
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    func fetchProducts(limit: Int = 50, offset: Int = 0, categoryId: String? = nil, collectionId: String? = nil) {
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = true
            self?.errorMessage = nil
        }
        
        var path = "/store/products?limit=\(limit)&offset=\(offset)"
        if let categoryId = categoryId {
            path += "&category_id[]=\(categoryId)"
        }
        if let collectionId = collectionId {
            path += "&collection_id[]=\(collectionId)"
        }
        
        networkManager.request(
            path: path,
            method: "GET"
        )
        .decode(type: ProductsResponse.self, decoder: JSONDecoder())
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "Failed to fetch products: \(error.localizedDescription)"
                    print("Products fetch error: \(error)")
                }
            },
            receiveValue: { [weak self] response in
                self?.products = response.products
                print("Fetched \(response.products.count) products")
            }
        )
        .store(in: &cancellables)
    }
    
    func fetchProduct(id: String, completion: @escaping (Product?) -> Void) {
        networkManager.request(
            path: "/store/products/\(id)",
            method: "GET"
        )
        .decode(type: ProductResponse.self, decoder: JSONDecoder())
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Product detail fetch error: \(error)")
                    completion(nil as Product?)
                }
            },
            receiveValue: { response in
                completion(response.product)
            }
        )
        .store(in: &cancellables)
    }
    
    func searchProducts(query: String, limit: Int = 50, categoryId: String? = nil, collectionId: String? = nil) {
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = true
            self?.errorMessage = nil
        }
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            DispatchQueue.main.async {
                self.errorMessage = "Invalid search query"
                self.isLoading = false
            }
            return
        }
        
        var path = "/store/products?q=\(encodedQuery)&limit=\(limit)"
        if let categoryId = categoryId {
            path += "&category_id[]=\(categoryId)"
        }
        if let collectionId = collectionId {
            path += "&collection_id[]=\(collectionId)"
        }
        
        networkManager.request(
            path: path,
            method: "GET"
        )
        .decode(type: ProductsResponse.self, decoder: JSONDecoder())
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "Search failed: \(error.localizedDescription)"
                    print("Search error: \(error)")
                }
            },
            receiveValue: { [weak self] response in
                self?.products = response.products
                print("Search found \(response.products.count) products")
            }
        )
        .store(in: &cancellables)
    }
}
