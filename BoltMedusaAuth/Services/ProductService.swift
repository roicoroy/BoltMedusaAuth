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
    
    private let baseURL = "https://1839-2a00-23c7-dc88-f401-c478-f6a-492c-22da.ngrok-free.app"
    private let publishableKey = "pk_d62e2de8f849db562e79a89c8a08ec4f5d23f1a958a344d5f64dfc38ad39fa1a"
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
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
        
        var urlString = "\(baseURL)/store/products?limit=\(limit)&offset=\(offset)"
        if let categoryId = categoryId {
            urlString += "&category_id[]=\(categoryId)"
        }
        if let collectionId = collectionId {
            urlString += "&collection_id[]=\(collectionId)"
        }
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Invalid URL for products"
                self?.isLoading = false
            }
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(publishableKey, forHTTPHeaderField: "x-publishable-api-key")
        
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("Products Response Status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Products Response: \(responseString)")
                    }
                    
                    if httpResponse.statusCode >= 400 {
                        throw URLError(.badServerResponse)
                    }
                }
                return data
            }
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
        guard let url = URL(string: "\(baseURL)/store/products/\(id)") else {
            completion(nil)
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(publishableKey, forHTTPHeaderField: "x-publishable-api-key")
        
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("Product Detail Response Status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Product Detail Response: \(responseString)")
                    }
                    
                    if httpResponse.statusCode >= 400 {
                        throw URLError(.badServerResponse)
                    }
                }
                return data
            }
            .decode(type: ProductResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Product detail fetch error: \(error)")
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
        
        var urlString = "\(baseURL)/store/products?q=\(encodedQuery)&limit=\(limit)"
        if let categoryId = categoryId {
            urlString += "&category_id[]=\(categoryId)"
        }
        if let collectionId = collectionId {
            urlString += "&collection_id[]=\(collectionId)"
        }
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Invalid search query"
                self?.isLoading = false
            }
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(publishableKey, forHTTPHeaderField: "x-publishable-api-key")
        
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("Search Response Status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Search Response: \(responseString)")
                    }
                    
                    if httpResponse.statusCode >= 400 {
                        throw URLError(.badServerResponse)
                    }
                }
                return data
            }
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
