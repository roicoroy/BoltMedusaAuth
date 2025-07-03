//
//  ShippingService.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 01/07/2025.
//

import Foundation
import Combine

class ShippingService: ObservableObject {
    @Published var shippingOptions: [ShippingOption] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let baseURL = "https://1839-2a00-23c7-dc88-f401-c478-f6a-492c-22da.ngrok-free.app"
    private let publishableKey = "pk_7b9a964b0ae6d083f0d2e70a5db350e2d6a7d93aceea46949373ff2872ead0fc"
    
    private var cancellables = Set<AnyCancellable>()
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Shipping Options
    
    func fetchShippingOptions(for cartId: String, fields: String? = nil) {
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = true
            self?.errorMessage = nil
        }
        
        var urlString = "\(baseURL)/store/shipping-options?cart_id=\(cartId)"
        
        // Add fields parameter if provided
        if let fields = fields {
            urlString += "&fields=\(fields)"
        }
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Invalid URL for shipping options"
                self?.isLoading = false
            }
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(publishableKey, forHTTPHeaderField: "x-publishable-api-key")
        
        // Add authentication header if user is logged in
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        print("🚚 Fetching shipping options for cart: \(cartId)")
        print("🚚 URL: \(urlString)")
        
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("🚚 Shipping Options Response Status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("🚚 Shipping Options Response: \(responseString)")
                    }
                    
                    if httpResponse.statusCode >= 400 {
                        throw URLError(.badServerResponse)
                    }
                }
                return data
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "Failed to fetch shipping options: \(error.localizedDescription)"
                        print("🚚 Shipping options fetch error: \(error)")
                    }
                },
                receiveValue: { [weak self] data in
                    self?.handleShippingOptionsResponse(data: data)
                }
            )
            .store(in: &cancellables)
    }
    
    private func handleShippingOptionsResponse(data: Data) {
        // Log the raw response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("🚚 Raw Shipping Options Response: \(responseString)")
        }
        
        // Try to decode as ShippingOptionsResponse first
        do {
            let response = try JSONDecoder().decode(ShippingOptionsResponse.self, from: data)
            self.shippingOptions = response.shippingOptions
            print("🚚 Successfully loaded \(response.shippingOptions.count) shipping options")
            
            // Log each shipping option for debugging
            for (index, option) in response.shippingOptions.enumerated() {
                print("🚚 Option \(index + 1): \(option.name) - \(option.formattedAmount) (\(option.priceTypeDisplay))")
            }
            
            return
        } catch {
            print("🚚 Failed to decode as ShippingOptionsResponse: \(error)")
        }
        
        // Try to parse as JSON and extract shipping options manually
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                print("🚚 Shipping Options JSON Structure: \(json)")
                
                // Try different possible structures
                var optionsArray: [[String: Any]]?
                
                // Case 1: shipping_options is at root level
                if let options = json["shipping_options"] as? [[String: Any]] {
                    optionsArray = options
                }
                // Case 2: data.shipping_options
                else if let dataDict = json["data"] as? [String: Any],
                        let options = dataDict["shipping_options"] as? [[String: Any]] {
                    optionsArray = options
                }
                // Case 3: Direct array at root
                else if let options = json as? [[String: Any]] {
                    optionsArray = [json]
                }
                
                if let optionsData = optionsArray {
                    // Convert back to Data and decode
                    let optionsJsonData = try JSONSerialization.data(withJSONObject: ["shipping_options": optionsData], options: [])
                    let response = try JSONDecoder().decode(ShippingOptionsResponse.self, from: optionsJsonData)
                    
                    self.shippingOptions = response.shippingOptions
                    print("🚚 Successfully loaded \(response.shippingOptions.count) shipping options (manual parsing)")
                    return
                }
            }
        } catch {
            print("🚚 Failed to parse shipping options JSON: \(error)")
        }
        
        // If all parsing fails, show error
        self.errorMessage = "Failed to parse shipping options response"
    }
    
    func clearShippingOptions() {
        DispatchQueue.main.async { [weak self] in
            self?.shippingOptions = []
            self?.errorMessage = nil
        }
    }
    
    func refreshShippingOptions(for cartId: String) {
        fetchShippingOptions(for: cartId)
    }
}
