import Foundation
import Combine

class ShippingService: ObservableObject {
    @Published var shippingOptions: [ShippingOption] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Shipping Options
    
    func fetchShippingOptions(for cartId: String, fields: String? = nil) {
        isLoading = true
        errorMessage = nil
        
        var endpoint = "shipping-options?cart_id=\(cartId)"
        
        if let fields = fields {
            endpoint += "&fields=\(fields)"
        }
        
        NetworkManager.shared.request(endpoint: endpoint)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "Failed to fetch shipping options: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] (response: ShippingOptionsResponse) in
                    self?.shippingOptions = response.shippingOptions
                }
            )
            .store(in: &cancellables)
    }
    
    func clearShippingOptions() {
        shippingOptions = []
        errorMessage = nil
    }
    
    func refreshShippingOptions(for cartId: String) {
        fetchShippingOptions(for: cartId)
    }
}
