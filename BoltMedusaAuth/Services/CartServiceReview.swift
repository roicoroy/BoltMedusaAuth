import Foundation
import Combine

class CartServiceReview: ObservableObject {
    @Published var currentCart: Cart?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
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
        isLoading = true
        errorMessage = nil
        
        let request = CreateCartRequest(regionId: regionId)
        guard let body = try? JSONEncoder().encode(request) else {
            errorMessage = "Failed to encode cart request"
            isLoading = false
            completion(false)
            return
        }
        
        NetworkManager.shared.request(endpoint: "carts", method: "POST", body: body, requiresAuth: true)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completionResult in
                self?.isLoading = false
                if case .failure(let error) = completionResult {
                    self?.errorMessage = "Failed to create cart: \(error.localizedDescription)"
                    completion(false)
                }
            }, receiveValue: { [weak self] (response: CartResponse) in
                self?.currentCart = response.cart
                self?.saveCartToStorage()
                if UserDefaults.standard.string(forKey: "auth_token") != nil && response.cart.customerId == nil {
                    
                    print("response.cart: \(response.cart)")
                    
                    self?.associateCartWithCustomer(cartId: response.cart.id) { associationSuccess in
                        completion(true)
                    }
                } else {
                    completion(true)
                }
            })
            .store(in: &cancellables)
    }
    
    func updateCartRegion(newRegionId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        guard let currentCart = currentCart else {
            createCart(regionId: newRegionId, completion: completion)
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let updateRequest = ["region_id": newRegionId]
        guard let body = try? JSONSerialization.data(withJSONObject: updateRequest, options: []) else {
            errorMessage = "Failed to encode cart update request"
            isLoading = false
            completion(false)
            return
        }
        
        NetworkManager.shared.request(endpoint: "carts/\(currentCart.id)", method: "POST", body: body, requiresAuth: true)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completionResult in
                if case .failure = completionResult {
                    self?.clearCart()
                    self?.createCart(regionId: newRegionId, completion: completion)
                }
            }, receiveValue: { [weak self] (response: CartResponse) in
                self?.isLoading = false
                self?.currentCart = response.cart
                self?.saveCartToStorage()
                completion(true)
            })
            .store(in: &cancellables)
    }
    
    func fetchCart(cartId: String) {
        isLoading = true
        errorMessage = nil
        
        NetworkManager.shared.request(endpoint: "carts/\(cartId)", requiresAuth: true)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completionResult in
                self?.isLoading = false
                if case .failure(let error) = completionResult {
                    self?.errorMessage = "Failed to fetch cart: \(error.localizedDescription)"
                }
            }, receiveValue: { [weak self] (response: CartResponse) in
                self?.currentCart = response.cart
                
                print("Found client secret: \(response.cart)")
                
                if UserDefaults.standard.string(forKey: "auth_token") != nil && response.cart.customerId == nil {
                    self?.associateCartWithCustomer(cartId: response.cart.id)
                }
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Customer Association with Addresses
    
    func associateCartWithCustomer(cartId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        guard let body = try? JSONEncoder().encode([String:String]()) else {
            completion(false)
            return
        }
        
        NetworkManager.shared.request(endpoint: "carts/\(cartId)/customer", method: "POST", body: body, requiresAuth: true)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completionResult in
                if case .failure = completionResult {
                    completion(false)
                }
            }, receiveValue: { [weak self] (response: CartResponse) in
                self?.currentCart = response.cart
                self?.saveCartToStorage()
                self?.addDefaultCustomerAddressesToCart(cartId: cartId) { addressSuccess in
                    completion(true)
                }
            })
            .store(in: &cancellables)
    }
    
    private func addDefaultCustomerAddressesToCart(cartId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        guard let customer = authService?.currentCustomer, let addresses = customer.addresses, !addresses.isEmpty else {
            completion(false)
            return
        }
        
        let defaultShippingAddress = addresses.first { $0.isDefaultShipping }
        let defaultBillingAddress = addresses.first { $0.isDefaultBilling }
        
        var completedOperations = 0
        let totalOperations = (defaultShippingAddress != nil ? 1 : 0) + (defaultBillingAddress != nil ? 1 : 0)
        
        guard totalOperations > 0 else {
            completion(false)
            return
        }
        
        var hasError = false
        
        let checkCompletion = {
            completedOperations += 1
            if completedOperations >= totalOperations {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.fetchCart(cartId: cartId)
                }
                completion(!hasError)
            }
        }
        
        if let shippingAddress = defaultShippingAddress {
            addShippingAddressToCart(cartId: cartId, address: shippingAddress) { success in
                if !success {
                    hasError = true
                }
                checkCompletion()
            }
        }
        
        if let billingAddress = defaultBillingAddress {
            if billingAddress.id != defaultShippingAddress?.id {
                addBillingAddressToCart(cartId: cartId, address: billingAddress) { success in
                    if !success {
                        hasError = true
                    }
                    checkCompletion()
                }
            } else {
                checkCompletion()
            }
        }
    }
    
    // MARK: - Manual Address Management (for address selector)
    
    func addShippingAddressFromCustomerAddress(addressId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        guard let cart = currentCart, let customer = authService?.currentCustomer, let addresses = customer.addresses, let address = addresses.first(where: { $0.id == addressId }) else {
            completion(false)
            return
        }
        addShippingAddressToCart(cartId: cart.id, address: address, completion: completion)
    }
    
    func addBillingAddressFromCustomerAddress(addressId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        guard let cart = currentCart, let customer = authService?.currentCustomer, let addresses = customer.addresses, let address = addresses.first(where: { $0.id == addressId }) else {
            completion(false)
            return
        }
        addBillingAddressToCart(cartId: cart.id, address: address, completion: completion)
    }
    
    private func addShippingAddressToCart(cartId: String, address: Address, completion: @escaping (Bool) -> Void) {
        updateCartAddresses(cartId: cartId, shippingAddress: address, completion: completion)
    }
    
    private func addBillingAddressToCart(cartId: String, address: Address, completion: @escaping (Bool) -> Void) {
        updateCartAddresses(cartId: cartId, billingAddress: address, completion: completion)
    }
    
    private func updateCartAddresses(cartId: String, shippingAddress: Address? = nil, billingAddress: Address? = nil, completion: @escaping (Bool) -> Void) {
        var requestBody: [String: Any] = [:]
        
        if let shippingAddress = shippingAddress {
            requestBody["shipping_address"] = shippingAddress.toDictionary()
        }
        
        if let billingAddress = billingAddress {
            requestBody["billing_address"] = billingAddress.toDictionary()
        }
        
        guard !requestBody.isEmpty, let body = try? JSONSerialization.data(withJSONObject: requestBody, options: []) else {
            completion(false)
            return
        }
        
        NetworkManager.shared.request(endpoint: "carts/\(cartId)", method: "POST", body: body, requiresAuth: true)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completionResult in
                if case .failure = completionResult {
                    completion(false)
                }
            }, receiveValue: { [weak self] (response: CartResponse) in
                self?.fetchCart(cartId: cartId)
                completion(true)
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Shipping Method Management
    
    func addShippingMethodToCart(optionId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        guard let cart = currentCart else {
            completion(false)
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let requestData = ["option_id": optionId]
        guard let body = try? JSONSerialization.data(withJSONObject: requestData, options: []) else {
            completion(false)
            return
        }
        
        NetworkManager.shared.requestData(endpoint: "carts/\(cart.id)/shipping-methods", method: "POST", body: body, requiresAuth: true)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completionResult in
                self?.isLoading = false
                if case .failure(let error) = completionResult {
                    self?.errorMessage = "Failed to add shipping method: \(error.localizedDescription)"
                    completion(false)
                }
            }, receiveValue: { [weak self] (data: Data) in
                self?.handleShippingMethodResponse(data: data, completion: completion)
            })
            .store(in: &cancellables)
    }
    
    private func handleShippingMethodResponse(data: Data, completion: @escaping (Bool) -> Void) {
        do {
            let response = try JSONDecoder().decode(CartResponse.self, from: data)
            self.currentCart = response.cart
            self.saveCartToStorage()
            completion(true)
            return
        } catch {}
        
        if let cart = currentCart {
            fetchCart(cartId: cart.id)
        }
        completion(true)
    }
    
    // MARK: - Payment Provider Management

    func updateCartPaymentProvider(cartId: String, paymentCollectionId: String?, providerId: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil

        guard let collectionId = paymentCollectionId else {
            errorMessage = "Payment collection ID is missing."
            isLoading = false
            completion(false)
            return
        }

        let requestBody: [String: Any] = ["provider_id": providerId]
        guard let body = try? JSONSerialization.data(withJSONObject: requestBody, options: []) else {
            completion(false)
            return
        }

        NetworkManager.shared.request(endpoint: "payment-collections/\(collectionId)/payment-sessions", method: "POST", body: body, requiresAuth: true)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completionResult in
                self?.isLoading = false
                if case .failure(let error) = completionResult {
                    self?.errorMessage = "Failed to update cart payment provider: \(error.localizedDescription)"
                    completion(false)
                }
            }, receiveValue: { [weak self] (response: PaymentCollectionResponse) in
                if let cartService = self?.authService?.cartService, var currentCart = cartService.currentCart {
                    currentCart.paymentCollection = response.paymentCollection
                    cartService.currentCart = currentCart
                    cartService.saveCartToStorage()
                    self?.fetchCart(cartId: currentCart.id)
                    completion(true)
                } else {
                    completion(false)
                }
            })
            .store(in: &cancellables)
    }

    // MARK: - Line Item Management
    
    func addLineItem(variantId: String, quantity: Int = 1, regionId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        guard let cart = currentCart else {
            createCart(regionId: regionId) { [weak self] success in
                if success {
                    self?.addLineItem(variantId: variantId, quantity: quantity, regionId: regionId, completion: completion)
                } else {
                    completion(false)
                }
            }
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let request = AddLineItemRequest(variantId: variantId, quantity: quantity)
        guard let body = try? JSONEncoder().encode(request) else {
            completion(false)
            return
        }
        
        NetworkManager.shared.requestData(endpoint: "carts/\(cart.id)/line-items", method: "POST", body: body, requiresAuth: true)
            .tryMap { data -> Data in
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Add Line Item Raw Response Body: \(responseString)")
                }
                return data
            }
            .decode(type: CartResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completionResult in
                self?.isLoading = false
                if case .failure(let error) = completionResult {
                    self?.errorMessage = "Failed to add item to cart: \(error.localizedDescription)"
                    print("Error adding line item: \(error.localizedDescription)")
                    completion(false)
                }
            }, receiveValue: { [weak self] (response: CartResponse) in
                self?.currentCart = response.cart
                self?.saveCartToStorage()
                print("Line item added successfully. Cart ID: \(response.cart.id), Total items: \(response.cart.itemCount)")
                if UserDefaults.standard.string(forKey: "auth_token") != nil && response.cart.customerId == nil {
                    self?.associateCartWithCustomer(cartId: response.cart.id) { associationSuccess in
                        print("Associate cart with customer after adding item: \(associationSuccess)")
                        completion(true)
                    }
                } else {
                    completion(true)
                }
            })
            .store(in: &cancellables)
    }
    
    func updateLineItem(lineItemId: String, quantity: Int, completion: @escaping (Bool) -> Void = { _ in }) {
        guard let cart = currentCart else {
            completion(false)
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let request = UpdateLineItemRequest(quantity: quantity)
        guard let body = try? JSONEncoder().encode(request) else {
            completion(false)
            return
        }
        
        NetworkManager.shared.request(endpoint: "carts/\(cart.id)/line-items/\(lineItemId)", method: "POST", body: body, requiresAuth: true)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completionResult in
                self?.isLoading = false
                if case .failure(let error) = completionResult {
                    self?.errorMessage = "Failed to update item: \(error.localizedDescription)"
                    completion(false)
                }
            }, receiveValue: { [weak self] (response: CartResponse) in
                self?.currentCart = response.cart
                self?.saveCartToStorage()
                completion(true)
            })
            .store(in: &cancellables)
    }
    
    func removeLineItem(lineItemId: String, onComplete: @escaping (Bool) -> Void = { _ in }) {
        guard let cart = currentCart else {
            onComplete(false)
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        NetworkManager.shared.requestData(endpoint: "carts/\(cart.id)/line-items/\(lineItemId)", method: "DELETE", requiresAuth: true)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completionResult in
                self?.isLoading = false
                if case .failure(let error) = completionResult {
                    self?.errorMessage = "Failed to remove item: \(error.localizedDescription)"
                    onComplete(false)
                }
            }, receiveValue: { [weak self] (data: Data) in
                self?.handleRemoveLineItemResponse(data: data, onComplete: onComplete)
            })
            .store(in: &cancellables)
    }
    
    private func handleRemoveLineItemResponse(data: Data, onComplete: @escaping (Bool) -> Void) {
        do {
            let response = try JSONDecoder().decode(CartResponse.self, from: data)
            self.currentCart = response.cart
            self.saveCartToStorage()
            onComplete(true)
            return
        } catch {}
        
        if let cart = currentCart {
            fetchCart(cartId: cart.id)
        }
        onComplete(true)
    }
    
    // MARK: - User Authentication Handling
    
    func handleUserLogin() {
        if let cart = currentCart, cart.customerId == nil {
            associateCartWithCustomer(cartId: cart.id)
        }
    }
    
    func handleUserLogout() {
    }

    func completeCart(completion: @escaping (Bool) -> Void) {
        guard let cart = currentCart else {
            completion(false)
            return
        }

        NetworkManager.shared.request(endpoint: "carts/\(cart.id)/complete", method: "POST", requiresAuth: true)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { result in
                switch result {
                case .finished:
                    break
                case .failure(let error):
                    print("Failed to complete cart: \(error.localizedDescription)")
                    completion(false)
                }
            }, receiveValue: { [weak self] (_: Data) in
                self?.clearCart()
                completion(true)
            })
            .store(in: &cancellables)
    }

    func applyPromotion(cartId: String, promoCode: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil

        let requestBody: [String: Any] = ["promo_codes": [promoCode]]
        guard let body = try? JSONSerialization.data(withJSONObject: requestBody, options: []) else {
            errorMessage = "Failed to encode promotion request"
            isLoading = false
            completion(false)
            return
        }

        NetworkManager.shared.request(endpoint: "carts/\(cartId)/promotions", method: "POST", body: body, requiresAuth: true)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completionResult in
                self?.isLoading = false
                if case .failure(let error) = completionResult {
                    self?.errorMessage = "Failed to apply promotion: \(error.localizedDescription)"
                    completion(false)
                }
            }, receiveValue: { [weak self] (response: CartResponse) in
                self?.currentCart = response.cart
                self?.saveCartToStorage()
                completion(true)
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Utility Methods
    
    func createCartIfNeeded(regionId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        if let currentCart = currentCart {
            updateCartRegion(newRegionId: regionId, completion: completion)
        } else {
            createCart(regionId: regionId, completion: completion)
        }
    }
    
    func clearCart() {
        DispatchQueue.main.async { [weak self] in
            self?.currentCart = nil
        }
        UserDefaults.standard.removeObject(forKey: "medusa_cart")
    }
    
    func refreshCart() {
        guard let cart = currentCart else { return }
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
                print("response:::::  \(cart)")
            }
        }
    }
}
