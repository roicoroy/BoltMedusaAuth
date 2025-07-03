
import Foundation
import Combine

class PaymentProvidersService: ObservableObject {
    @Published var paymentProviders: [PaymentProvider] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    weak var cartService: CartService?
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Payment Providers
    
    func fetchPaymentProviders(for cart: Cart) {
        guard let regionId = cart.regionId else {
            errorMessage = "Cart does not have a region ID"
            return
        }
        fetchPaymentProviders(regionId: regionId)
    }
    
    func fetchPaymentProviders(regionId: String) {
        isLoading = true
        errorMessage = nil
        
        NetworkManager.shared.request(endpoint: "payment-providers?region_id=\(regionId)", requiresAuth: true)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "Failed to fetch payment providers: \(error.localizedDescription)"
                }
            }, receiveValue: { [weak self] (response: PaymentProvidersResponse) in
                self?.paymentProviders = response.paymentProviders
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Payment Collection Creation
    
    func createPaymentCollection(cartId: String, completion: @escaping (Bool, PaymentCollection?) -> Void) {
        let request = CreatePaymentCollectionRequest(cartId: cartId)
        guard let body = try? JSONEncoder().encode(request) else {
            completion(false, nil)
            return
        }
        
        NetworkManager.shared.request(endpoint: "payment-collections", method: "POST", body: body, requiresAuth: true)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completionResult in
                if case .failure = completionResult {
                    completion(false, nil)
                }
            }, receiveValue: { [weak self] (response: PaymentCollectionResponse) in
                if let cartService = self?.cartService, var currentCart = cartService.currentCart {
                    currentCart.paymentCollection = response.paymentCollection
                    cartService.currentCart = currentCart
                    cartService.fetchCart(cartId: currentCart.id)
                    
                    if let providerId = self?.paymentProviders.first?.id {
                        self?.initializePaymentSession(paymentCollectionId: response.paymentCollection.id, providerId: providerId) { success in
                        }
                    }
                }
                completion(true, response.paymentCollection)
            })
            .store(in: &cancellables)
    }
    
    func initializePaymentSession(paymentCollectionId: String, providerId: String, completion: @escaping (Bool) -> Void) {
        let requestBody: [String: Any] = ["provider_id": providerId]
        guard let body = try? JSONSerialization.data(withJSONObject: requestBody, options: []) else {
            completion(false)
            return
        }
        
        NetworkManager.shared.request(endpoint: "payment-collections/\(paymentCollectionId)/payment-sessions", method: "POST", body: body, requiresAuth: true)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completionResult in
                if case .failure = completionResult {
                    completion(false)
                }
            }, receiveValue: { [weak self] (response: PaymentCollectionResponse) in
                if let cartService = self?.cartService, var currentCart = cartService.currentCart {
                    currentCart.paymentCollection = response.paymentCollection
                    cartService.fetchCart(cartId: currentCart.id)
                }
                completion(true)
            })
            .store(in: &cancellables)
    }
    
    func clearPaymentProviders() {
        paymentProviders = []
        errorMessage = nil
    }
    
    func refreshPaymentProviders(for cart: Cart) {
        fetchPaymentProviders(for: cart)
    }
    
    func refreshPaymentProviders(regionId: String) {
        fetchPaymentProviders(regionId: regionId)
    }
}
