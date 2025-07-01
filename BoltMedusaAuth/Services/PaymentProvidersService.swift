//
//  PaymentProvidersService.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 01/07/2025.
//

import Foundation
import Combine

class PaymentProvidersService: ObservableObject {
    @Published var paymentProviders: [PaymentProvider] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let baseURL = "https://1839-2a00-23c7-dc88-f401-c478-f6a-492c-22da.ngrok-free.app"
    private let publishableKey = "pk_d62e2de8f849db562e79a89c8a08ec4f5d23f1a958a344d5f64dfc38ad39fa1a"
    
    private var cancellables = Set<AnyCancellable>()
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Payment Providers
    
    func fetchPaymentProviders(for cart: Cart) {
        guard let regionId = cart.regionId else {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Cart does not have a region ID"
            }
            return
        }
        
        fetchPaymentProviders(regionId: regionId)
    }
    
    func fetchPaymentProviders(regionId: String) {
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = true
            self?.errorMessage = nil
        }
        
        let urlString = "\(baseURL)/store/payment-providers?region_id=\(regionId)"
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Invalid URL for payment providers"
                self?.isLoading = false
            }
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"  // ✅ FIXED: Changed from POST to GET
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(publishableKey, forHTTPHeaderField: "x-publishable-api-key")
        
        // Add authentication header if user is logged in
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // CRITICAL: Add credentials include equivalent for iOS
        urlRequest.setValue("include", forHTTPHeaderField: "credentials")
        
        // ✅ REMOVED: No body needed for GET request
        
        print("💳 Fetching payment providers for region: \(regionId)")
        print("💳 URL: \(urlString)")
        print("💳 Method: GET")
        print("💳 Headers: \(urlRequest.allHTTPHeaderFields ?? [:])")
        
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("💳 Payment Providers Response Status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("💳 Payment Providers Response: \(responseString)")
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
                        self?.errorMessage = "Failed to fetch payment providers: \(error.localizedDescription)"
                        print("💳 Payment providers fetch error: \(error)")
                    }
                },
                receiveValue: { [weak self] data in
                    self?.handlePaymentProvidersResponse(data: data)
                }
            )
            .store(in: &cancellables)
    }
    
    private func handlePaymentProvidersResponse(data: Data) {
        // Log the raw response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("💳 Raw Payment Providers Response: \(responseString)")
        }
        
        // Try to decode the exact expected response structure first
        do {
            // Expected structure:
            // {
            //     "payment_providers": [
            //         {
            //             "id": "pp_system_default",
            //             "is_enabled": true
            //         },
            //         {
            //             "id": "pp_stripe_stripe",
            //             "is_enabled": true
            //         }
            //     ],
            //     "count": 2,
            //     "offset": 0,
            //     "limit": 20
            // }
            
            let response = try JSONDecoder().decode(PaymentProvidersResponse.self, from: data)
            self.paymentProviders = response.paymentProviders
            print("💳 Successfully loaded \(response.paymentProviders.count) payment providers")
            
            // Log each payment provider for debugging
            for (index, provider) in response.paymentProviders.enumerated() {
                print("💳 Provider \(index + 1): \(provider.displayName) (ID: \(provider.id)) - \(provider.statusText)")
                print("💳   - Enabled: \(provider.isEnabled ?? true)")
                print("💳   - Type: \(provider.providerType.displayName)")
            }
            
            return
        } catch {
            print("💳 Failed to decode as PaymentProvidersResponse: \(error)")
            
            // Print detailed decoding error
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("💳 Key '\(key.stringValue)' not found: \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("💳 Type mismatch for type \(type): \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("💳 Value not found for type \(type): \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("💳 Data corrupted: \(context.debugDescription)")
                @unknown default:
                    print("💳 Unknown decoding error: \(error)")
                }
            }
        }
        
        // Try to parse as JSON and extract payment providers manually
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                print("💳 Payment Providers JSON Structure: \(json.keys)")
                
                // Try different possible structures
                var providersArray: [[String: Any]]?
                
                // Case 1: payment_providers is at root level (expected structure)
                if let providers = json["payment_providers"] as? [[String: Any]] {
                    providersArray = providers
                    print("💳 Found payment_providers array with \(providers.count) items")
                }
                // Case 2: data.payment_providers
                else if let dataDict = json["data"] as? [String: Any],
                        let providers = dataDict["payment_providers"] as? [[String: Any]] {
                    providersArray = providers
                    print("💳 Found payment_providers in data object with \(providers.count) items")
                }
                // Case 3: Simple array of objects with just id and is_enabled
                else if let providers = json["payment_providers"] as? [Any] {
                    // Handle mixed array types
                    var convertedProviders: [[String: Any]] = []
                    for provider in providers {
                        if let providerDict = provider as? [String: Any] {
                            convertedProviders.append(providerDict)
                        } else if let providerString = provider as? String {
                            // Convert simple string ID to object
                            convertedProviders.append(["id": providerString, "is_enabled": true])
                        }
                    }
                    providersArray = convertedProviders
                    print("💳 Converted mixed payment_providers array with \(convertedProviders.count) items")
                }
                
                if let providersData = providersArray {
                    print("💳 Processing \(providersData.count) payment providers:")
                    for (index, providerData) in providersData.enumerated() {
                        print("💳   Provider \(index + 1): \(providerData)")
                    }
                    
                    // Convert back to Data and decode
                    let providersJsonData = try JSONSerialization.data(withJSONObject: [
                        "payment_providers": providersData,
                        "limit": json["limit"] ?? 20,
                        "offset": json["offset"] ?? 0,
                        "count": json["count"] ?? providersData.count
                    ], options: [])
                    
                    let response = try JSONDecoder().decode(PaymentProvidersResponse.self, from: providersJsonData)
                    
                    self.paymentProviders = response.paymentProviders
                    print("💳 Successfully loaded \(response.paymentProviders.count) payment providers (manual parsing)")
                    
                    // Log each payment provider for debugging
                    for (index, provider) in response.paymentProviders.enumerated() {
                        print("💳 Provider \(index + 1): \(provider.displayName) (ID: \(provider.id)) - \(provider.statusText)")
                    }
                    
                    return
                }
                
                print("💳 Could not find payment_providers in any expected location")
                print("💳 Available keys: \(Array(json.keys))")
            }
        } catch {
            print("💳 Failed to parse payment providers JSON: \(error)")
        }
        
        // If all parsing fails, show error
        self.errorMessage = "Failed to parse payment providers response. Check console for details."
    }
    
    func clearPaymentProviders() {
        DispatchQueue.main.async { [weak self] in
            self?.paymentProviders = []
            self?.errorMessage = nil
        }
    }
    
    func refreshPaymentProviders(for cart: Cart) {
        fetchPaymentProviders(for: cart)
    }
    
    func refreshPaymentProviders(regionId: String) {
        fetchPaymentProviders(regionId: regionId)
    }
}