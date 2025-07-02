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
    
    private let networkManager: NetworkManager
    private var cancellables = Set<AnyCancellable>()
    
    // Reference to auth service to get customer data
    weak var authService: AuthService?
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
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
        
        let requestBody = CreateCartRequest(regionId: regionId)
        
        networkManager.request(
            path: "/store/carts",
            method: "POST",
            body: requestBody,
            authToken: UserDefaults.standard.string(forKey: "auth_token")
        )
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
                
                if UserDefaults.standard.string(forKey: "auth_token") != nil && response.cart.customerId == nil {
                    self?.associateCartWithCustomer(cartId: response.cart.id) { associationSuccess in
                        print("Customer association result: \(associationSuccess)")
                        completion(true)
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
            createCart(regionId: newRegionId, completion: completion)
            return
        }
        
        print("Updating cart region from current cart: \(currentCart.id)")
        
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = true
            self?.errorMessage = nil
        }
        
        let requestBody = ["region_id": newRegionId]
        
        networkManager.request(
            path: "/store/carts/\(currentCart.id)",
            method: "POST",
            body: requestBody,
            authToken: UserDefaults.standard.string(forKey: "auth_token")
        )
        .decode(type: CartResponse.self, decoder: JSONDecoder())
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completionResult in
                if case .failure(let error) = completionResult {
                    print("Cart region update failed: \(error), creating new cart instead")
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
        
        networkManager.request(
            path: "/store/carts/\(cartId)",
            method: "GET",
            authToken: UserDefaults.standard.string(forKey: "auth_token")
        )
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
                
                if let paymentSessions = response.cart.paymentCollection?.paymentSessions,
                   let firstSession = paymentSessions.first,
                   let clientSecretValue = firstSession.data?["client_secret"]?.value,
                   let clientSecret = clientSecretValue as? String {
                    print("Found client secret: \(clientSecret)")
                    print("🚚 Cart client secret: \(clientSecret)")
                }
                
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
        
        networkManager.request(
            path: "/store/carts/\(cartId)/customer",
            method: "POST",
            body: [String: String](), // Empty body
            authToken: token
        )
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
                
                self?.addDefaultCustomerAddressesToCart(cartId: cartId) { addressSuccess in
                    print("Default customer addresses addition result: \(addressSuccess)")
                    completion(true)
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
        updateCartAddresses(cartId: cartId, shippingAddress: address, completion: completion)
    }
    
    private func addBillingAddressToCart(cartId: String, address: Address, completion: @escaping (Bool) -> Void) {
        updateCartAddresses(cartId: cartId, billingAddress: address, completion: completion)
    }
    
    private func updateCartAddresses(cartId: String, shippingAddress: Address? = nil, billingAddress: Address? = nil, completion: @escaping (Bool) -> Void) {
        var requestBody: [String: AnyCodable] = [:]
        
        if let shippingAddress = shippingAddress {
            requestBody["shipping_address"] = AnyCodable(shippingAddress.toDictionary())
            print("📦 Updating cart with shipping address: \(shippingAddress.address1)")
        }
        
        if let billingAddress = billingAddress {
            requestBody["billing_address"] = AnyCodable(billingAddress.toDictionary())
            print("💳 Updating cart with billing address: \(billingAddress.address1)")
        }
        
        guard !requestBody.isEmpty else {
            print("No addresses provided for cart update.")
            completion(false)
            return
        }
        
        networkManager.request(
            path: "/store/carts/\(cartId)",
            method: "POST",
            body: requestBody,
            authToken: UserDefaults.standard.string(forKey: "auth_token")
        )
        .decode(type: CartResponse.self, decoder: JSONDecoder())
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { completionResult in
                if case .failure(let error) = completionResult {
                    print("❌ Failed to update cart addresses: \(error)")
                    completion(false)
                }
            },
            receiveValue: { [weak self] response in
                print("✅ Cart addresses updated successfully. Refreshing cart from server.")
                self?.fetchCart(cartId: cartId)
                completion(true)
            }
        )
        .store(in: &cancellables)
    }
    
    // MARK: - Shipping Method Management
    
    func addShippingMethodToCart(optionId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        guard let cart = currentCart else {
            print("❌ No cart available for adding shipping method")
            completion(false)
            return
        }
        
        print("🚚 ADDING SHIPPING METHOD TO CART:")
        print("🚚 =================================")
        print("🚚 Cart ID: \(cart.id)")
        print("🚚 Shipping Option ID: \(optionId)")
        print("🚚 Current Cart Total: \(cart.formattedTotal)")
        print("🚚 Current Shipping Total: \(cart.formattedShippingTotal)")
        
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = true
            self?.errorMessage = nil
        }
        
        let requestData = ["option_id": optionId]
        
        networkManager.request(
            path: "/store/carts/\(cart.id)/shipping-methods",
            method: "POST",
            body: requestData,
            authToken: UserDefaults.standard.string(forKey: "auth_token")
        )
        .sink(
            receiveCompletion: { [weak self] completionResult in
                self?.isLoading = false
                if case .failure(let error) = completionResult {
                    self?.errorMessage = "Failed to add shipping method: \(error.localizedDescription)"
                    print("🚚 ❌ Add shipping method error: \(error)")
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
            print("🚚 Raw Shipping Method Response: \(responseString)")
        }
        
        // Try to decode as CartResponse first
        do {
            let response = try JSONDecoder().decode(CartResponse.self, from: data)
            self.currentCart = response.cart
            self.saveCartToStorage()
            
            print("🚚 ✅ SHIPPING METHOD SUCCESSFULLY ADDED!")
            print("🚚 Updated Cart Total: \(response.cart.formattedTotal)")
            print("🚚 Updated Shipping Total: \(response.cart.formattedShippingTotal)")
            print("🚚 Shipping Total (cents): \(response.cart.shippingTotal)")
            
            // Log detailed cart information
            print("🚚 UPDATED CART DETAILS:")
            print("🚚 - Subtotal: \(response.cart.formattedSubtotal)")
            print("🚚 - Shipping: \(response.cart.formattedShippingTotal)")
            print("🚚 - Tax: \(response.cart.formattedTaxTotal)")
            print("🚚 - Total: \(response.cart.formattedTotal)")
            
            completion(true)
            return
        } catch {
            print("🚚 Failed to decode as CartResponse: \(error)")
        }
        
        // Try to parse as JSON to see what structure we have
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                print("🚚 Shipping method response JSON structure: \(json)")
                
                // Check if it's a success response
                if let success = json["success"] as? Bool, success {
                    print("🚚 ✅ Shipping method added successfully - success flag found")
                    // Refresh cart data from server since we don't have updated cart in response
                    if let cart = currentCart {
                        fetchCart(cartId: cart.id)
                    }
                    completion(true)
                    return
                }
                
                // Check if cart is nested differently
                if let cartData = json["cart"] as? [String: Any] {
                    let cartJsonData = try JSONSerialization.data(withJSONObject: cartData, options: [])
                    let cart = try JSONDecoder().decode(Cart.self, from: cartJsonData)
                    self.currentCart = cart
                    self.saveCartToStorage()
                    print("🚚 ✅ Shipping method added successfully - cart found in response")
                    completion(true)
                    return
                }
                
                // If response doesn't contain cart data but operation was successful
                print("🚚 ✅ Shipping method added successfully - refreshing cart data")
                if let cart = currentCart {
                    fetchCart(cartId: cart.id)
                }
                completion(true)
                return
            }
        } catch {
            print("🚚 Failed to parse shipping method response JSON: \(error)")
        }
        
        // If we can't parse the response but got here, it means the HTTP request was successful
        print("🚚 ✅ Shipping method added successfully - HTTP was successful, refreshing cart")
        if let cart = currentCart {
            fetchCart(cartId: cart.id)
        }
        completion(true)
    }
    
    // MARK: - Payment Provider Management

    func updateCartPaymentProvider(cartId: String, paymentCollectionId: String?, providerId: String, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = true
            self?.errorMessage = nil
        }

        guard let collectionId = paymentCollectionId else {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Payment collection ID is missing."
                self?.isLoading = false
            }
            completion(false)
            return
        }

        let requestBody: [String: String] = ["provider_id": providerId]
        print("requestBody::::: \(requestBody)")

        networkManager.request(
            path: "/store/payment-collections/\(collectionId)/payment-sessions",
            method: "POST",
            body: requestBody,
            authToken: UserDefaults.standard.string(forKey: "auth_token")
        )
        .decode(type: PaymentCollectionResponse.self, decoder: JSONDecoder())
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completionResult in
                self?.isLoading = false
                if case .failure(let error) = completionResult {
                    self?.errorMessage = "Failed to update cart payment provider: \(error.localizedDescription)"
                    print("❌ Update Cart Payment Provider error: \(error)")
                    completion(false)
                }
            },
            receiveValue: { [weak self] response in
                if let cartService = self?.authService?.cartService, var currentCart = cartService.currentCart {
                    currentCart.paymentCollection = response.paymentCollection
                    cartService.currentCart = currentCart
                    cartService.saveCartToStorage()
                    
                    self?.fetchCart(cartId: currentCart.id)
                    print("✅ Cart payment provider updated successfully.")
                    completion(true)
                } else {
                    print("❌ Failed to update cart after payment provider update: CartService or currentCart is nil.")
                    completion(false)
                }
            }
        )
        .store(in: &cancellables)
    }

    // MARK: - Line Item Management
    
    func addLineItem(variantId: String, quantity: Int = 1, regionId: String, completion: @escaping (Bool) -> Void = { _ in }) {
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
        
        let requestBody = AddLineItemRequest(variantId: variantId, quantity: quantity)
        
        networkManager.request(
            path: "/store/carts/\(cart.id)/line-items",
            method: "POST",
            body: requestBody,
            authToken: UserDefaults.standard.string(forKey: "auth_token")
        )
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
                
                if UserDefaults.standard.string(forKey: "auth_token") != nil && response.cart.customerId == nil {
                    self?.associateCartWithCustomer(cartId: response.cart.id) { associationSuccess in
                        print("Customer association after add item result: \(associationSuccess)")
                        completion(true)
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
        
        let requestBody = UpdateLineItemRequest(quantity: quantity)
        
        networkManager.request(
            path: "/store/carts/\(cart.id)/line-items/\(lineItemId)",
            method: "POST",
            body: requestBody,
            authToken: UserDefaults.standard.string(forKey: "auth_token")
        )
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
        
        networkManager.request(
            path: "/store/carts/\(cart.id)/line-items/\(lineItemId)",
            method: "DELETE",
            authToken: UserDefaults.standard.string(forKey: "auth_token")
        )
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

    func completeCart(completion: @escaping (Bool) -> Void) {
        guard let cart = currentCart else {
            completion(false)
            return
        }

        networkManager.request(
            path: "/store/carts/\(cart.id)/complete",
            method: "POST",
            authToken: UserDefaults.standard.string(forKey: "auth_token")
        )
        .sink(receiveCompletion: { result in
            switch result {
            case .finished:
                break
            case .failure(let error):
                print("Failed to complete cart: \(error)")
                completion(false)
            }
        }, receiveValue: { [weak self] _ in
            self?.clearCart()
            completion(true)
        })
        .store(in: &cancellables)
    }
    
    // MARK: - Utility Methods
    
    func createCartIfNeeded(regionId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        if let currentCart = currentCart {
            // Check if cart currency matches the new region's expected currency
            // If not, update the cart region or create a new one
            print("Cart exists: \(currentCart.id) with currency: \(currentCart.currencyCode)")
            
            
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
    
    
    // MARK: - Storage
    
     public func saveCartToStorage() {
        guard let cart = currentCart else { return }
        if let encoded = try? JSONEncoder().encode(cart) {
            UserDefaults.standard.set(encoded, forKey: "medusa_cart")
        }
    }
    
     public func loadCartFromStorage() {
        if let cartData = UserDefaults.standard.data(forKey: "medusa_cart"),
           let cart = try? JSONDecoder().decode(Cart.self, from: cartData) {
            DispatchQueue.main.async { [weak self] in
                self?.currentCart = cart
            }
            // Refresh cart data from server to ensure it's up to date
            fetchCart(cartId: cart.id)
        } else {
            print("💾 No cart found in storage")
        }
    }
}
