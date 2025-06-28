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
            .decode(type: CartResponse.self, decoder: JSONDecoder())
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
                receiveValue: { [weak self] response in
                    self?.currentCart = response.cart
                    self?.saveCartToStorage()
                    print("Cart created successfully: \(response.cart.id) for region: \(regionId) with currency: \(response.cart.currencyCode)")
                    
                    // If user is logged in and cart doesn't have customer_id, associate it
                    if UserDefaults.standard.string(forKey: "auth_token") != nil && response.cart.customerId == nil {
                        self?.associateCartWithCustomer(cartId: response.cart.id) { associationSuccess in
                            print("Customer association result: \(associationSuccess)")
                            completion(true) // Still return success even if association fails
                        }
                    } else {
                        completion(true)
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
            .decode(type: CartResponse.self, decoder: JSONDecoder())
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
                receiveValue: { [weak self] response in
                    self?.isLoading = false
                    self?.currentCart = response.cart
                    self?.saveCartToStorage()
                    print("Cart region updated successfully: \(response.cart.id) to currency: \(response.cart.currencyCode)")
                    completion(true)
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
            .decode(type: CartResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completionResult in
                    self?.isLoading = false
                    if case .failure(let error) = completionResult {
                        self?.errorMessage = "Failed to fetch cart: \(error.localizedDescription)"
                        print("Fetch cart error: \(error)")
                    }
                },
                receiveValue: { [weak self] response in
                    self?.currentCart = response.cart
                    self?.saveCartToStorage()
                    print("Cart fetched successfully: \(response.cart.id) with currency: \(response.cart.currencyCode)")
                    print("Cart has shipping address: \(response.cart.hasShippingAddress)")
                    print("Cart has billing address: \(response.cart.hasBillingAddress)")
                    
                    // If user is logged in and cart doesn't have customer_id, associate it
                    if UserDefaults.standard.string(forKey: "auth_token") != nil && response.cart.customerId == nil {
                        self?.associateCartWithCustomer(cartId: response.cart.id) { associationSuccess in
                            print("Customer association result: \(associationSuccess)")
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
            .decode(type: CartResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completionResult in
                    if case .failure(let error) = completionResult {
                        print("Cart customer association error: \(error)")
                        completion(false)
                    }
                },
                receiveValue: { [weak self] response in
                    self?.currentCart = response.cart
                    self?.saveCartToStorage()
                    print("Cart successfully associated with customer: \(response.cart.id)")
                    if let customerId = response.cart.customerId {
                        print("Customer ID: \(customerId)")
                    }
                    
                    // After successful customer association, add addresses if available
                    self?.addCustomerAddressesToCart(cartId: cartId) { addressSuccess in
                        print("Customer addresses addition result: \(addressSuccess)")
                        completion(true) // Return success regardless of address addition result
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func addCustomerAddressesToCart(cartId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        guard let customer = authService?.currentCustomer,
              let addresses = customer.addresses,
              !addresses.isEmpty else {
            print("No customer or addresses available for cart address setup")
            completion(false)
            return
        }
        
        // Find default shipping and billing addresses
        let defaultShippingAddress = addresses.first { $0.isDefaultShipping } ?? addresses.first
        let defaultBillingAddress = addresses.first { $0.isDefaultBilling } ?? addresses.first
        
        var completedOperations = 0
        let totalOperations = (defaultShippingAddress != nil ? 1 : 0) + (defaultBillingAddress != nil ? 1 : 0)
        
        guard totalOperations > 0 else {
            print("No addresses to add to cart")
            completion(false)
            return
        }
        
        var hasError = false
        
        let checkCompletion = {
            completedOperations += 1
            if completedOperations >= totalOperations {
                completion(!hasError)
            }
        }
        
        // Add shipping address if available
        if let shippingAddress = defaultShippingAddress {
            addShippingAddressToCart(cartId: cartId, address: shippingAddress) { success in
                if !success {
                    hasError = true
                }
                checkCompletion()
            }
        }
        
        // Add billing address if available and different from shipping
        if let billingAddress = defaultBillingAddress {
            if billingAddress.id != defaultShippingAddress?.id {
                addBillingAddressToCart(cartId: cartId, address: billingAddress) { success in
                    if !success {
                        hasError = true
                    }
                    checkCompletion()
                }
            } else {
                // Same address for both shipping and billing
                checkCompletion()
            }
        }
    }
    
    private func addShippingAddressToCart(cartId: String, address: Address, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/store/carts/\(cartId)/shipping-address") else {
            print("Invalid URL for adding shipping address to cart")
            completion(false)
            return
        }
        
        let addressData: [String: Any] = [
            "first_name": address.firstName ?? "",
            "last_name": address.lastName ?? "",
            "address_1": address.address1,
            "address_2": address.address2 ?? "",
            "city": address.city,
            "country_code": address.countryCode,
            "postal_code": address.postalCode,
            "phone": address.phone ?? "",
            "company": address.company ?? "",
            "province": address.province ?? ""
        ]
        
        performAddressRequest(url: url, addressData: addressData, addressType: "shipping", completion: completion)
    }
    
    private func addBillingAddressToCart(cartId: String, address: Address, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/store/carts/\(cartId)/billing-address") else {
            print("Invalid URL for adding billing address to cart")
            completion(false)
            return
        }
        
        let addressData: [String: Any] = [
            "first_name": address.firstName ?? "",
            "last_name": address.lastName ?? "",
            "address_1": address.address1,
            "address_2": address.address2 ?? "",
            "city": address.city,
            "country_code": address.countryCode,
            "postal_code": address.postalCode,
            "phone": address.phone ?? "",
            "company": address.company ?? "",
            "province": address.province ?? ""
        ]
        
        performAddressRequest(url: url, addressData: addressData, addressType: "billing", completion: completion)
    }
    
    private func performAddressRequest(url: URL, addressData: [String: Any], addressType: String, completion: @escaping (Bool) -> Void) {
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            print("No auth token found for \(addressType) address addition")
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
            print("Adding \(addressType) address to cart with data: \(addressData)")
        } catch {
            print("Failed to encode \(addressType) address data: \(error)")
            completion(false)
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("Add \(addressType.capitalized) Address Response Status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Add \(addressType.capitalized) Address Response: \(responseString)")
                    }
                    
                    if httpResponse.statusCode >= 400 {
                        throw URLError(.badServerResponse)
                    }
                }
                return data
            }
            .decode(type: CartResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completionResult in
                    if case .failure(let error) = completionResult {
                        print("Failed to add \(addressType) address to cart: \(error)")
                        completion(false)
                    }
                },
                receiveValue: { [weak self] response in
                    self?.currentCart = response.cart
                    self?.saveCartToStorage()
                    print("\(addressType.capitalized) address successfully added to cart")
                    print("Cart now has shipping address: \(response.cart.hasShippingAddress)")
                    print("Cart now has billing address: \(response.cart.hasBillingAddress)")
                    completion(true)
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Manual Address Management
    
    func addShippingAddressFromCustomerAddress(addressId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        guard let cart = currentCart,
              let customer = authService?.currentCustomer,
              let addresses = customer.addresses,
              let address = addresses.first(where: { $0.id == addressId }) else {
            print("Cannot find address or cart for shipping address addition")
            completion(false)
            return
        }
        
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
        
        addBillingAddressToCart(cartId: cart.id, address: address, completion: completion)
    }
    
    func copyShippingToBillingAddress(completion: @escaping (Bool) -> Void = { _ in }) {
        guard let cart = currentCart,
              let shippingAddress = cart.shippingAddress else {
            print("No cart or shipping address to copy")
            completion(false)
            return
        }
        
        guard let url = URL(string: "\(baseURL)/store/carts/\(cart.id)/billing-address") else {
            print("Invalid URL for copying shipping to billing address")
            completion(false)
            return
        }
        
        let addressData: [String: Any] = [
            "first_name": shippingAddress.firstName ?? "",
            "last_name": shippingAddress.lastName ?? "",
            "address_1": shippingAddress.address1,
            "address_2": shippingAddress.address2 ?? "",
            "city": shippingAddress.city,
            "country_code": shippingAddress.countryCode,
            "postal_code": shippingAddress.postalCode,
            "phone": shippingAddress.phone ?? "",
            "company": shippingAddress.company ?? "",
            "province": shippingAddress.province ?? ""
        ]
        
        performAddressRequest(url: url, addressData: addressData, addressType: "billing", completion: completion)
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
            .decode(type: CartResponse.self, decoder: JSONDecoder())
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
                receiveValue: { [weak self] response in
                    self?.currentCart = response.cart
                    self?.saveCartToStorage()
                    print("Line item added successfully to cart: \(response.cart.id)")
                    print("Cart now has \(response.cart.itemCount) items")
                    
                    // If user is logged in and cart doesn't have customer_id, associate it
                    if UserDefaults.standard.string(forKey: "auth_token") != nil && response.cart.customerId == nil {
                        self?.associateCartWithCustomer(cartId: response.cart.id) { associationSuccess in
                            print("Customer association after add item result: \(associationSuccess)")
                            completion(true) // Still return success even if association fails
                        }
                    } else {
                        completion(true)
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
            .decode(type: CartResponse.self, decoder: JSONDecoder())
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
                receiveValue: { [weak self] response in
                    self?.currentCart = response.cart
                    self?.saveCartToStorage()
                    print("Line item updated successfully")
                    completion(true)
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
        do {
            let response = try JSONDecoder().decode(CartResponse.self, from: data)
            self.currentCart = response.cart
            self.saveCartToStorage()
            print("Line item removed successfully - cart updated")
            onComplete(true)
            return
        } catch {
            print("Failed to decode as CartResponse: \(error)")
        }
        
        // Try to parse as JSON to see what structure we have
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                print("Remove response JSON structure: \(json)")
                
                // Check if it's a success response without cart data
                if let success = json["success"] as? Bool, success {
                    print("Line item removed successfully - success flag found")
                    // Refresh cart data from server since we don't have updated cart in response
                    if let cart = currentCart {
                        fetchCart(cartId: cart.id)
                    }
                    onComplete(true)
                    return
                }
                
                // Check if cart is nested differently
                if let cartData = json["data"] as? [String: Any] {
                    let cartJsonData = try JSONSerialization.data(withJSONObject: cartData, options: [])
                    let cart = try JSONDecoder().decode(Cart.self, from: cartJsonData)
                    self.currentCart = cart
                    self.saveCartToStorage()
                    print("Line item removed successfully - cart found in data field")
                    onComplete(true)
                    return
                }
                
                // If response doesn't contain cart data but operation was successful
                // (indicated by successful HTTP status), refresh the cart
                print("Line item removed successfully - refreshing cart data")
                if let cart = currentCart {
                    fetchCart(cartId: cart.id)
                }
                onComplete(true)
                return
            }
        } catch {
            print("Failed to parse remove response JSON: \(error)")
        }
        
        // If we can't parse the response but got here, it means the HTTP request was successful
        // So we should refresh the cart to get the updated state
        print("Line item removed successfully - response parsing failed but HTTP was successful, refreshing cart")
        if let cart = currentCart {
            fetchCart(cartId: cart.id)
        }
        onComplete(true)
    }
    
    // MARK: - User Authentication Handling
    
    func handleUserLogin() {
        // When user logs in, associate existing cart with the customer
        if let cart = currentCart, cart.customerId == nil {
            print("User logged in, associating existing cart with customer")
            associateCartWithCustomer(cartId: cart.id) { success in
                if success {
                    print("Successfully associated cart with logged-in customer")
                } else {
                    print("Failed to associate cart with customer after login")
                }
            }
        }
    }
    
    func handleUserLogout() {
        // When user logs out, we might want to clear the cart or keep it as anonymous
        // For now, we'll keep the cart but it will become anonymous
        print("User logged out, cart will remain as anonymous cart")
        
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
    
    // MARK: - Currency Formatting
    
    func formatPrice(_ amount: Int, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode.uppercased()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        let decimalAmount = Double(amount) / 100.0
        return formatter.string(from: NSNumber(value: decimalAmount)) ?? "\(currencyCode.uppercased()) 0.00"
    }
    
    // MARK: - Storage
    
    private func saveCartToStorage() {
        guard let cart = currentCart else { return }
        if let encoded = try? JSONEncoder().encode(cart) {
            UserDefaults.standard.set(encoded, forKey: "medusa_cart")
            print("Cart saved to storage: \(cart.id) with \(cart.itemCount) items, currency: \(cart.currencyCode)")
            if let customerId = cart.customerId {
                print("Cart is associated with customer: \(customerId)")
            } else {
                print("Cart is anonymous (no customer association)")
            }
        }
    }
    
    private func loadCartFromStorage() {
        if let cartData = UserDefaults.standard.data(forKey: "medusa_cart"),
           let cart = try? JSONDecoder().decode(Cart.self, from: cartData) {
            DispatchQueue.main.async { [weak self] in
                self?.currentCart = cart
            }
            print("Cart loaded from storage: \(cart.id) with \(cart.itemCount) items, currency: \(cart.currencyCode)")
            if let customerId = cart.customerId {
                print("Cart is associated with customer: \(customerId)")
            } else {
                print("Cart is anonymous (no customer association)")
            }
            // Refresh cart data from server to ensure it's up to date
            fetchCart(cartId: cart.id)
        } else {
            print("No cart found in storage")
        }
    }
}