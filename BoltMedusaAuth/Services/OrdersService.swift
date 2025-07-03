//
//  OrdersService.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 02/07/2025.
//

import Foundation
import Combine

class OrdersService: ObservableObject {
    @Published var orders: [Order] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let baseURL = "https://1839-2a00-23c7-dc88-f401-c478-f6a-492c-22da.ngrok-free.app"
    private let publishableKey = "pk_7b9a964b0ae6d083f0d2e70a5db350e2d6a7d93aceea46949373ff2872ead0fc"
    
    private var cancellables = Set<AnyCancellable>()
    
    func fetchOrders() {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(baseURL)/store/orders") else {
            errorMessage = "Invalid URL for fetching orders"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(publishableKey, forHTTPHeaderField: "x-publishable-api-key")
        
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: OrdersResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "Failed to fetch orders: \(error.localizedDescription)"
                        print("Fetch orders error: \(error)")
                    }
                },
                receiveValue: { [weak self] response in
                    self?.orders = response.orders
                    self?.isLoading = false
                    print("Successfully fetched \(response.orders.count) orders.")
                }
            )
            .store(in: &cancellables)
    }
}
