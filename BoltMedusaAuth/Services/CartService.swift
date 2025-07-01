//
//  CartService.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 28/06/2025.
//

import Foundation
import Combine

class CartService: ObservableObject {
    @Published var currentCart: Cart?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let baseURL = "https://1839-2a00-23c7-dc88-f401-c478-f6a-492c-22da.ngrok-free.app"
    private let publishableKey = "pk_d62e2de8f849db562e79a89c8a08ec4f5d23f1a958a344d5f64dfc38ad39fa1a"
    
    private var cancellables = Set<AnyCancellable>()
    
    // Reference to auth service to get customer data
    weak var authService: AuthService?
    
    init() {
        loadCartFromStorage()
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Auth Service Integration
    
    func setAuthService(_ authService: AuthService) {
        self.authService = authService
    }
    
    // MARK: - Cart Management
    
    func createCart(regionId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = true
            self?.errorMessage = nil
        }
        
        guard let url = URL(string: "\(baseURL)/store/carts") else {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Invalid URL for cart creation"
                self?.isLoading = false
            }
            completion(false)
            return
        }
        
        let request = CreateCartRequest(regionId: regionId)
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(publishableKey, forHTTPHeaderField: "x-publishable-api-key")
        
        // Add authentication header if user is logged in
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Failed to encode cart request: \(error.localizedDescription)"
                self?.isLoading = false
            }
            completion(false)
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("Create Cart Response Status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Create Cart Response: \(responseString)")
                    }
                    
                    if httpResponse.statusCode >= 400 {
                        throw URLError(.badServerResponse)
                    }
                }
                return data
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completionResult in
                    self?.isLoading = false
                    if case .failure(let error) = completionResult {
                        self?.errorMessage = "Failed to create cart: \(error.localizedDescription)"
                        print("Create cart error: \(error)")
                        completion(false)
                    }
                },
                receiveValue: { [weak self] data in
                    self?.handleCartResponse(data: data) { success in
                        if success {
                            print("Cart created successfully")
                            // If user is logged in and cart doesn't have customer_id, associate it
                            if UserDefaults.standard.string(forKey: "auth_token") != nil,
                               let cart = self?.currentCart,
                               cart.customerId == nil {
                                self?.associateCartWithCustomer(cartId: cart.id) { associationSuccess in
                                    print("Customer association result: \(associationSuccess)")
                                    completion(true) // Still return success even if association fails
                                }
                            } else {
                                completion(true)
                            }
                        } else {
                            completion(false)
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func updateCartRegion(newRegionId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        guard let currentCart = currentCart else {
            // No existing cart, create a new one
            createCart(regionId: newRegionId, completion: completion)
            return
        }
        
        // Check if cart is already in the correct region
        // Note: We'll need to track region ID in cart or compare currency
        print("Updating cart region from current cart: \(currentCart.id)")
        
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = true
            self?.errorMessage = nil
        }
        
        guard let url = URL(string: "\(baseURL)/store/carts/\(currentCart.id)") else {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Invalid URL for cart update"
                self?.isLoading = false
            }
            completion(false)
            return
        }
        
        let updateRequest = ["region_id": newRegionId]
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(publishableKey, forHTTPHeaderField: "x-publishable-api-key")
        
        // Add authentication header if user is logged in
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: updateRequest, options: [])
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Failed to encode cart update request: \(error.localizedDescription)"
                self?.isLoading = false
            }
            completion(false)
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("Update Cart Region Response Status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Update Cart Region Response: \(responseString)")
                    }
                    
                    // If update fails (e.g., not supported), create a new cart
                    if httpResponse.statusCode >= 400 {
                        print("Cart region update not supported, will create new cart")
                        throw URLError(.badServerResponse)
                    }
                }
                return data
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completionResult in
                    if case .failure(let error) = completionResult {
                        print("Cart region update failed: \(error), creating new cart instead")
                        // If update fails, create a new cart for the new region
                        self?.clearCart()
                        self?.createCart(regionId: newRegionId, completion: completion)
                    }
                },
                receiveValue: { [weak self] data in
                    self?.isLoading = false
                    self?.handleCartResponse(data: data) { success in
                        if success {
                            print("Cart region updated successfully")
                        }
                        completion(success)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func fetchCart(cartId: String) {
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = true
            self?.errorMessage = nil
        }
        
        guard let url = URL(string: "\(baseURL)/store/carts/\(cartId)") else {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Invalid URL for cart fetch"
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
        
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("Fetch Cart Response Status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Fetch Cart Response: \(responseString)")
                    }
                    
                    if httpResponse.statusCode >= 400 {
                        throw URLError(.badServerResponse)
                    }
                }
                return data
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completionResult in
                    self?.isLoading = false
                    if case .failure(let error) = completionResult {
                        self?.errorMessage = "Failed to fetch cart: \(error.localizedDescription)"
                        print("Fetch cart error: \(error)")
                    }
                },
                receiveValue: { [weak self] data in
                    self?.handleCartResponse(data: data) { success in
                        if success {
                            print("Cart fetched successfully")
                            print("📦 Cart has shipping address: \(self?.currentCart?.hasShippingAddress ?? false)")
                            print("💳 Cart has billing address: \(self?.currentCart?.hasBillingAddress ?? false)")
                            
                            // If user is logged in and cart doesn't have customer_id, associate it
                            if UserDefaults.standard.string(forKey: "auth_token") != nil,
                               let cart = self?.currentCart,
                               cart.customerId == nil {
                                self?.associateCartWithCustomer(cartId: cart.id) { associationSuccess in
                                    print("Customer association result: \(associationSuccess)")
                                }
                            }
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Customer Association with Addresses
    
    func associateCartWithCustomer(cartId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            print("No auth token found, cannot associate cart with customer")
            completion(false)
            return
        }
        
        guard let url = URL(string: "\(baseURL)/store/carts/\(cartId)/customer") else {
            print("Invalid URL for cart customer association")
            completion(false)
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(publishableKey, forHTTPHeaderField: "x-publishable-api-key")
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Empty body for customer association
        urlRequest.httpBody = Data("{}".utf8)
        
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("Associate Customer Response Status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Associate Customer Response: \(responseString)")
                    }
                    
                    if httpResponse.statusCode >= 400 {
                        throw URLError(.badServerResponse)
                    }
                }
                return data
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completionResult in
                    if case .failure(let error) = completionResult {
                        print("Cart customer association error: \(error)")
                        completion(false)
                    }
                },
                receiveValue: { [weak self] data in
                    self?.handleCartResponse(data: data) { success in
                        if success {
                            print("Cart successfully associated with customer")
                            if let customerId = self?.currentCart?.customerId {
                                print("Customer ID: \(customerId)")
                            }
                            
                            // After successful customer association, add default addresses if available
                            self?.addDefaultCustomerAddressesToCart(cartId: cartId) { addressSuccess in
                                print("Default customer addresses addition result: \(addressSuccess)")
                                completion(true) // Return success regardless of address addition result
                            }
                        } else {
                            completion(false)
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func addDefaultCustomerAddressesToCart(cartId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        guard let customer = authService?.currentCustomer,
              let addresses = customer.addresses,
              !addresses.isEmpty else {
            print("No customer or addresses available for default address setup")
            completion(false)
            return
        }
        
        print("🏠 Adding default customer addresses to cart. Customer has \(addresses.count) address(es)")
        
        // Find default shipping and billing addresses
        let defaultShippingAddress = addresses.first { $0.isDefaultShipping }
        let defaultBillingAddress = addresses.first { $0.isDefaultBilling }
        
        print("📦 Default shipping address: \(defaultShippingAddress?.addressName ?? "None")")
        print("💳 Default billing address: \(defaultBillingAddress?.addressName ?? "None")")
        
        var completedOperations = 0
        let totalOperations = (defaultShippingAddress != nil ? 1 : 0) + (defaultBillingAddress != nil ? 1 : 0)
        
        guard totalOperations > 0 else {
            print("❌ No default addresses to add to cart")
            completion(false)
            return
        }
        
        var hasError = false
        
        let checkCompletion = {
            completedOperations += 1
            print("✅ Completed \(completedOperations)/\(totalOperations) default address operations")
            if completedOperations >= totalOperations {
                // After all address operations, refresh the cart to verify addresses were added
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.fetchCart(cartId: cartId)
                }
                completion(!hasError)
            }
        }
        
        // Add default shipping address if available
        if let shippingAddress = defaultShippingAddress {
            print("📦 Adding default shipping address: \(shippingAddress.address1), \(shippingAddress.city)")
            addShippingAddressToCart(cartId: cartId, address: shippingAddress) { success in
                if !success {
                    hasError = true
                    print("❌ Failed to add default shipping address")
                } else {
                    print("✅ Successfully added default shipping address")
                }
                checkCompletion()
            }
        }
        
        // Add default billing address if available and different from shipping
        if let billingAddress = defaultBillingAddress {
            if billingAddress.id != defaultShippingAddress?.id {
                print("💳 Adding default billing address: \(billingAddress.address1), \(billingAddress.city)")
                addBillingAddressToCart(cartId: cartId, address: billingAddress) { success in
                    if !success {
                        hasError = true
                        print("❌ Failed to add default billing address")
                    } else {
                        print("✅ Successfully added default billing address")
                    }
                    checkCompletion()
                }
            } else {
                // Same address for both shipping and billing
                print("📦💳 Using same address for both shipping and billing")
                checkCompletion()
            }
        }
    }
    
    // MARK: - Manual Address Management (for address selector)
    
    func addShippingAddressFromCustomerAddress(addressId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        guard let cart = currentCart,
              let customer = authService?.currentCustomer,
              let addresses = customer.addresses,
              let address = addresses.first(where: { $0.id == addressId }) else {
            print("Cannot find address or cart for shipping address addition")
            completion(false)
            return
        }
        
        print("📦 Adding selected shipping address: \(address.addressName ?? "Address") - \(address.address1)")
        addShippingAddressToCart(cartId: cart.id, address: address, completion: completion)
    }
    
    func addBillingAddressFromCustomerAddress(addressId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        guard let cart = currentCart,
              let customer = authService?.currentCustomer,
              let addresses = customer.addresses,
              let address = addresses.first(where: { $0.id == addressId }) else {
            print("Cannot find address or cart for billing address addition")
            completion(false)
            return
        }
        
        print("💳 Adding selected billing address: \(address.addressName ?? "Address") - \(address.address1)")
        addBillingAddressToCart(cartId: cart.id, address: address, completion: completion)
    }
    
    private func addShippingAddressToCart(cartId: String, address: Address, completion: @escaping (Bool) -> Void) {
        // Try multiple possible endpoints for Medusa v2
        let possibleEndpoints = [
            "\(baseURL)/store/carts/\(cartId)/addresses/shipping",
            "\(baseURL)/store/carts/\(cartId)/shipping-address",
            "\(baseURL)/store/carts/\(cartId)/address/shipping"
        ]
        
        tryAddressEndpoints(endpoints: possibleEndpoints, address: address, addressType: "shipping", completion: completion)
    }
    
    private func addBillingAddressToCart(cartId: String, address: Address, completion: @escaping (Bool) -> Void) {
        // Try multiple possible endpoints for Medusa v2
        let possibleEndpoints = [
            "\(baseURL)/store/carts/\(cartId)/addresses/billing",
            "\(baseURL)/store/carts/\(cartId)/billing-address",
            "\(baseURL)/store/carts/\(cartId)/address/billing"
        ]
        
        tryAddressEndpoints(endpoints: possibleEndpoints, address: address, addressType: "billing", completion: completion)
    }
    
    private func tryAddressEndpoints(endpoints: [String], address: Address, addressType: String, completion: @escaping (Bool) -> Void) {
        guard !endpoints.isEmpty else {
            print("❌ No more endpoints to try for \(addressType) address")
            completion(false)
            return
        }
        
        var remainingEndpoints = endpoints
        let currentEndpoint = remainingEndpoints.removeFirst()
        
        guard let url = URL(string: currentEndpoint) else {
            print("❌ Invalid URL for \(addressType) address: \(currentEndpoint)")
            tryAddressEndpoints(endpoints: remainingEndpoints, address: address, addressType: addressType, completion: completion)
            return
        }
        
        print("🔄 Trying \(addressType) address endpoint: \(currentEndpoint)")
        
        // Create a simplified address payload that matches Medusa's expected format
        var addressData: [String: Any] = [
            "first_name": address.firstName ?? "",
            "last_name": address.lastName ?? "",
            "address_1": address.address1,
            "city": address.city,
            "country_code": address.countryCode.lowercased(), // Ensure lowercase
            "postal_code": address.postalCode
        ]
        
        // Add the address ID for the selected address
        addressData["\(addressType)_address_id"] = address.id
        
        // Add optional fields only if they have values
        if let address2 = address.address2, !address2.isEmpty {
            addressData["address_2"] = address2
        }
        
        if let phone = address.phone, !phone.isEmpty {
            addressData["phone"] = phone
        }
        
        if let company = address.company, !company.isEmpty {
            addressData["company"] = company
        }
        
        if let province = address.province, !province.isEmpty {
            addressData["province"] = province
        }
        
        print("📦 \(addressType.capitalized) address payload:")
        for (key, value) in addressData {
            print("  \(key): \(value)")
        }
        
        performAddressRequest(url: url, addressData: addressData, addressType: addressType) { success in
            if success {
                print("✅ Successfully added \(addressType) address using endpoint: \(currentEndpoint)")
                completion(true)
            } else {
                print("❌ Failed with endpoint: \(currentEndpoint), trying next...")
                self.tryAddressEndpoints(endpoints: remainingEndpoints, address: address, addressType: addressType, completion: completion)
            }
        }
    }
    
    private func performAddressRequest(url: URL, addressData: [String: Any], addressType: String, completion: @escaping (Bool) -> Void) {
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            print("❌ No auth token found for \(addressType) address addition")
            completion(false)
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(publishableKey, forHTTPHeaderField: "x-publishable-api-key")
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: addressData, options: [])
            print("🚀 Sending \(addressType) address request to: \(url)")
            
            // Log the exact JSON being sent
            if let jsonString = String(data: urlRequest.httpBody!, encoding: .utf8) {
                print("📤 Request JSON: \(jsonString)")
            }
        } catch {
            print("❌ Failed to encode \(addressType) address data: \(error)")
            completion(false)
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("📍 Add \(addressType.capitalized) Address Response Status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("📍 Add \(addressType.capitalized) Address Response: \(responseString)")
                    }
                    
                    if httpResponse.statusCode >= 400 {
                        print("❌ \(addressType.capitalized) address addition failed with status: \(httpResponse.statusCode)")
                        
                        // Try to parse error message from response
                        if let errorData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            print("❌ Error details: \(errorData)")
                        }
                        
                        throw URLError(.badServerResponse)
                    }
                }
                return data
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completionResult in
                    if case .failure(let error) = completionResult {
                        print("❌ Failed to add \(addressType) address to cart: \(error)")
                        completion(false)
                    }
                },
                receiveValue: { [weak self] data in
                    // Handle the response - it might not always be a CartResponse
                    self?.handleAddressResponse(data: data, addressType: addressType, completion: completion)
                }
            )
            .store(in: &cancellables)
    }
    
    private func handleAddressResponse(data: Data, addressType: String, completion: @escaping (Bool) -> Void) {
        // Log the raw response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("📍 \(addressType.capitalized) Address Raw Response: \(responseString)")
        }
        
        // Try to decode as CartResponse first
        handleCartResponse(data: data) { success in
            if success {
                print("✅ \(addressType.capitalized) address successfully added to cart via CartResponse")
                print("📦 Cart now has shipping address: \(self.currentCart?.hasShippingAddress ?? false)")
                print("💳 Cart now has billing address: \(self.currentCart?.hasBillingAddress ?? false)")
                
                // Log the address details for verification
                if addressType == "shipping", let shippingAddress = self.currentCart?.shippingAddress {
                    print("📦 Shipping address details:")
                    print("   Name: \(shippingAddress.fullName)")
                    print("   Address: \(shippingAddress.singleLineAddress)")
                }
                
                if addressType == "billing", let billingAddress = self.currentCart?.billingAddress {
                    print("💳 Billing address details:")
                    print("   Name: \(billingAddress.fullName)")
                    print("   Address: \(billingAddress.singleLineAddress)")
                }
                
                completion(true)
            } else {
                // If cart response parsing fails, still consider it successful if HTTP was successful
                print("✅ \(addressType.capitalized) address added successfully - HTTP was successful")
                completion(true)
            }
        }
    }
    
    // MARK: - Shipping Methods
    
    func addShippingMethodToCart(optionId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        guard let cart = currentCart else {
            print("❌ No cart available for adding shipping method")
            completion(false)
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = true
            self?.errorMessage = nil
        }
        
        guard let url = URL(string: "\(baseURL)/store/carts/\(cart.id)/shipping-methods") else {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Invalid URL for adding shipping method"
                self?.isLoading = false
            }
            completion(false)
            return
        }
        
        let requestPayload = ["option_id": optionId]
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(publishableKey, forHTTPHeaderField: "x-publishable-api-key")
        
        // Add authentication header if user is logged in
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: requestPayload, options: [])
            print("🚚 Adding shipping method to cart: \(cart.id)")
            print("🚚 Option ID: \(optionId)")
            print("🚚 URL: \(url)")
            
            if let jsonString = String(data: urlRequest.httpBody!, encoding: .utf8) {
                print("🚚 Request JSON: \(jsonString)")
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Failed to encode shipping method request: \(error.localizedDescription)"
                self?.isLoading = false
            }
            completion(false)
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("🚚 Add Shipping Method Response Status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("🚚 Add Shipping Method Response: \(responseString)")
                    }
                    
                    if httpResponse.statusCode >= 400 {
                        throw URLError(.badServerResponse)
                    }
                }
                return data
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completionResult in
                    self?.isLoading = false
                    if case .failure(let error) = completionResult {
                        self?.errorMessage = "Failed to add shipping method: \(error.localizedDescription)"
                        print("🚚 Add shipping method error: \(error)")
                        completion(false)
                    }
                },
                receiveValue: { [weak self] data in
                    self?.handleShippingMethodResponse(data: data, completion: completion)
                }
            )
            .store(in: &cancellables)
    }
    
    private func handleShippingMethodResponse(data: Data, completion: @escaping (Bool) -> Void) {
        // Log the raw response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("🚚 Shipping Method Raw Response: \(responseString)")
        }
        
        // Try to decode as CartResponse first
        handleCartResponse(data: data) { success in
            if success {
                print("🚚 Shipping method successfully added to cart")
                print("🚚 Cart shipping total: \(self.currentCart?.formattedShippingTotal ?? "N/A")")
                print("🚚 Cart total: \(self.currentCart?.formattedTotal ?? "N/A")")
                completion(true)
            } else {
                // If cart response parsing fails, still consider it successful if HTTP was successful
                print("🚚 Shipping method added successfully - HTTP was successful, refreshing cart")
                if let cart = self.currentCart {
                    self.fetchCart(cartId: cart.id)
                }
                completion(true)
            }
        }
    }
    
    // MARK: - Line Item Management
    
    func addLineItem(variantId: String, quantity: Int = 1, regionId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        // Create cart if it doesn't exist
        guard let cart = currentCart else {
            print("No cart exists, creating new cart for region: \(regionId)")
            createCart(regionId: regionId) { [weak self] success in
                if success {
                    print("Cart created, now adding line item")
                    self?.addLineItem(variantId: variantId, quantity: quantity, regionId: regionId, completion: completion)
                } else {
                    print("Failed to create cart")
                    completion(false)
                }
            }
            return
        }
        
        print("Adding line item to existing cart: \(cart.id)")
        
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = true
            self?.errorMessage = nil
        }
        
        guard let url = URL(string: "\(baseURL)/store/carts/\(cart.id)/line-items") else {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Invalid URL for adding line item"
                self?.isLoading = false
            }
            completion(false)
            return
        }
        
        let request = AddLineItemRequest(variantId: variantId, quantity: quantity)
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(publishableKey, forHTTPHeaderField: "x-publishable-api-key")
        
        // Add authentication header if user is logged in
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Failed to encode line item request: \(error.localizedDescription)"
                self?.isLoading = false
            }
            completion(false)
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("Add Line Item Response Status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Add Line Item Response: \(responseString)")
                    }
                    
                    if httpResponse.statusCode >= 400 {
                        throw URLError(.badServerResponse)
                    }
                }
                return data
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completionResult in
                    self?.isLoading = false
                    if case .failure(let error) = completionResult {
                        self?.errorMessage = "Failed to add item to cart: \(error.localizedDescription)"
                        print("Add line item error: \(error)")
                        completion(false)
                    }
                },
                receiveValue: { [weak self] data in
                    self?.handleCartResponse(data: data) { success in
                        if success {
                            print("Line item added successfully to cart")
                            print("Cart now has \(self?.currentCart?.itemCount ?? 0) items")
                            
                            // If user is logged in and cart doesn't have customer_id, associate it
                            if UserDefaults.standard.string(forKey: "auth_token") != nil,
                               let cart = self?.currentCart,
                               cart.customerId == nil {
                                self?.associateCartWithCustomer(cartId: cart.id) { associationSuccess in
                                    print("Customer association after add item result: \(associationSuccess)")
                                    completion(true) // Still return success even if association fails
                                }
                            } else {
                                completion(true)
                            }
                        } else {
                            completion(false)
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func updateLineItem(lineItemId: String, quantity: Int, completion: @escaping (Bool) -> Void = { _ in }) {
        guard let cart = currentCart else {
            completion(false)
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = true
            self?.errorMessage = nil
        }
        
        guard let url = URL(string: "\(baseURL)/store/carts/\(cart.id)/line-items/\(lineItemId)") else {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Invalid URL for updating line item"
                self?.isLoading = false
            }
            completion(false)
            return
        }
        
        let request = UpdateLineItemRequest(quantity: quantity)
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(publishableKey, forHTTPHeaderField: "x-publishable-api-key")
        
        // Add authentication header if user is logged in
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Failed to encode update request: \(error.localizedDescription)"
                self?.isLoading = false
            }
            completion(false)
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("Update Line Item Response Status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Update Line Item Response: \(responseString)")
                    }
                    
                    if httpResponse.statusCode >= 400 {
                        throw URLError(.badServerResponse)
                    }
                }
                return data
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completionResult in
                    self?.isLoading = false
                    if case .failure(let error) = completionResult {
                        self?.errorMessage = "Failed to update item: \(error.localizedDescription)"
                        print("Update line item error: \(error)")
                        completion(false)
                    }
                },
                receiveValue: { [weak self] data in
                    self?.handleCartResponse(data: data) { success in
                        if success {
                            print("Line item updated successfully")
                        }
                        completion(success)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func removeLineItem(lineItemId: String, onComplete: @escaping (Bool) -> Void = { _ in }) {
        guard let cart = currentCart else {
            onComplete(false)
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = true
            self?.errorMessage = nil
        }
        
        guard let url = URL(string: "\(baseURL)/store/carts/\(cart.id)/line-items/\(lineItemId)") else {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Invalid URL for removing line item"
                self?.isLoading = false
            }
            onComplete(false)
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(publishableKey, forHTTPHeaderField: "x-publishable-api-key")
        
        // Add authentication header if user is logged in
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("Remove Line Item Response Status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Remove Line Item Response: \(responseString)")
                    }
                    
                    if httpResponse.statusCode >= 400 {
                        throw URLError(.badServerResponse)
                    }
                }
                return data
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completionResult in
                    if case .failure(let error) = completionResult {
                        self?.isLoading = false
                        self?.errorMessage = "Failed to remove item: \(error.localizedDescription)"
                        print("Remove line item error: \(error)")
                        onComplete(false)
                    }
                },
                receiveValue: { [weak self] data in
                    // Handle different response structures for DELETE operation
                    self?.handleRemoveLineItemResponse(data: data, onComplete: onComplete)
                }
            )
            .store(in: &cancellables)
    }
    
    private func handleRemoveLineItemResponse(data: Data, onComplete: @escaping (Bool) -> Void) {
        // Log the raw response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("Remove Line Item Success Response: \(responseString)")
        }
        
        // Try to decode as CartResponse first (standard response)
        handleCartResponse(data: data) { success in
            self.isLoading = false
            if success {
                print("Line item removed successfully - cart updated")
                onComplete(true)
            } else {
                // If cart response parsing fails, still consider it successful if HTTP was successful
                print("Line item removed successfully - refreshing cart data")
                if let cart = self.currentCart {
                    self.fetchCart(cartId: cart.id)
                }
                onComplete(true)
            }
        }
    }
    
    // MARK: - User Authentication Handling
    
    func handleUserLogin() {
        // When user logs in, associate existing cart with the customer
        if let cart = currentCart, cart.customerId == nil {
            print("👤 User logged in, associating existing cart with customer")
            associateCartWithCustomer(cartId: cart.id) { success in
                if success {
                    print("✅ Successfully associated cart with logged-in customer and added default addresses")
                } else {
                    print("❌ Failed to associate cart with customer after login")
                }
            }
        }
    }
    
    func handleUserLogout() {
        // When user logs out, we might want to clear the cart or keep it as anonymous
        // For now, we'll keep the cart but it will become anonymous
        print("👤 User logged out, cart will remain as anonymous cart")
        
        // Optionally, you could clear the cart here:
        // clearCart()
    }
    
    // MARK: - Utility Methods
    
    func createCartIfNeeded(regionId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        if let currentCart = currentCart {
            // Check if cart currency matches the new region's expected currency
            // If not, update the cart region or create a new one
            print("Cart exists: \(currentCart.id) with currency: \(currentCart.currencyCode)")
            print("Checking if cart needs region update for region: \(regionId)")
            
            // For now, we'll update the cart region
            updateCartRegion(newRegionId: regionId, completion: completion)
        } else {
            print("Creating cart for region: \(regionId)")
            createCart(regionId: regionId, completion: completion)
        }
    }
    
    func clearCart() {
        DispatchQueue.main.async { [weak self] in
            self?.currentCart = nil
        }
        UserDefaults.standard.removeObject(forKey: "medusa_cart")
        print("Cart cleared")
    }
    
    func refreshCart() {
        guard let cart = currentCart else { 
            print("No cart to refresh")
            return 
        }
        print("Refreshing cart: \(cart.id)")
        fetchCart(cartId: cart.id)
    }
    
    // MARK: - Response Handling
    
    private func handleCartResponse(data: Data, completion: @escaping (Bool) -> Void) {
        // Log the raw response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("Raw Cart Response: \(responseString)")
        }
        
        // Try to decode as CartResponse first
        do {
            let response = try JSONDecoder().decode(CartResponse.self, from: data)
            self.currentCart = response.cart
            self.saveCartToStorage()
            print("Cart response decoded successfully")
            completion(true)
            return
        } catch {
            print("Failed to decode as CartResponse: \(error)")
        }
        
        // Try to parse as JSON and extract cart data manually
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                print("Cart Response JSON Structure: \(json)")
                
                // Try to extract cart from different possible structures
                var cartData: [String: Any]?
                
                // Case 1: Cart is nested under "cart" key
                if let nestedCart = json["cart"] as? [String: Any] {
                    cartData = nestedCart
                }
                // Case 2: Cart data is at root level
                else if json["id"] != nil && json["currency_code"] != nil {
                    cartData = json
                }
                
                if let cartJson = cartData {
                    // Convert back to Data and decode
                    let cartJsonData = try JSONSerialization.data(withJSONObject: cartJson, options: [])
                    let cart = try JSONDecoder().decode(Cart.self, from: cartJsonData)
                    
                    self.currentCart = cart
                    self.saveCartToStorage()
                    print("Cart response decoded successfully (manual parsing)")
                    completion(true)
                    return
                }
            }
        } catch {
            print("Failed to parse cart response JSON: \(error)")
        }
        
        // If all parsing fails, show error
        print("Failed to parse cart response")
        completion(false)
    }
    
    // MARK: - Storage
    
    private func saveCartToStorage() {
        guard let cart = currentCart else { return }
        if let encoded = try? JSONEncoder().encode(cart) {
            UserDefaults.standard.set(encoded, forKey: "medusa_cart")
            print("💾 Cart saved to storage: \(cart.id) with \(cart.itemCount) items, currency: \(cart.currencyCode)")
            if let customerId = cart.customerId {
                print("👤 Cart is associated with customer: \(customerId)")
            } else {
                print("👤 Cart is anonymous (no customer association)")
            }
            print("📦 Cart has shipping address: \(cart.hasShippingAddress)")
            print("💳 Cart has billing address: \(cart.hasBillingAddress)")
        }
    }
    
    private func loadCartFromStorage() {
        if let cartData = UserDefaults.standard.data(forKey: "medusa_cart"),
           let cart = try? JSONDecoder().decode(Cart.self, from: cartData) {
            DispatchQueue.main.async { [weak self] in
                self?.currentCart = cart
            }
            print("💾 Cart loaded from storage: \(cart.id) with \(cart.itemCount) items, currency: \(cart.currencyCode)")
            if let customerId = cart.customerId {
                print("👤 Cart is associated with customer: \(customerId)")
            } else {
                print("👤 Cart is anonymous (no customer association)")
            }
            print("📦 Cart has shipping address: \(cart.hasShippingAddress)")
            print("💳 Cart has billing address: \(cart.hasBillingAddress)")
            // Refresh cart data from server to ensure it's up to date
            fetchCart(cartId: cart.id)
        } else {
            print("💾 No cart found in storage")
        }
    }
}