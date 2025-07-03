import Foundation
import Combine

class OrdersService: ObservableObject {
    @Published var orders: [Order] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    func fetchOrders() {
        isLoading = true
        errorMessage = nil
        
        NetworkManager.shared.request(endpoint: "orders", requiresAuth: true)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "Failed to fetch orders: \(error.localizedDescription)"
                }
            }, receiveValue: { [weak self] (response: OrdersResponse) in
                self?.orders = response.orders
            })
            .store(in: &cancellables)
    }
}
