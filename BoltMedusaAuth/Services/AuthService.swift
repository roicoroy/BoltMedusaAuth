import Foundation
import Combine

class AuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentCustomer: Customer?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    // Cart service reference for handling cart association
    weak var cartService: CartServiceReview?
    
    init() {
        checkAuthenticationStatus()
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Cart Service Integration
    
    func setCartService(_ cartService: CartServiceReview) {
        self.cartService = cartService
    }
    
    private func checkAuthenticationStatus() {
        if let customerData = UserDefaults.standard.data(forKey: "customer"),
           let customer = try? JSONDecoder().decode(Customer.self, from: customerData) {
            DispatchQueue.main.async { [weak self] in
                self?.currentCustomer = customer
                self?.isAuthenticated = true
            }
        }
    }
    
    func register(email: String, password: String, firstName: String, lastName: String, phone: String) {
        isLoading = true
        errorMessage = nil
        
        let authPayload = AuthRegisterPayload(
            firstName: firstName,
            lastName: lastName,
            email: email,
            password: password,
            phone: phone
        )
        
        guard let body = try? JSONEncoder().encode(authPayload) else {
            errorMessage = "Failed to encode registration request"
            isLoading = false
            return
        }
        
        NetworkManager.shared.request(endpoint: "auth/customer/emailpass/register", method: "POST", body: body)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = "Registration failed: \(error.localizedDescription)"
                    self?.isLoading = false
                }
            }, receiveValue: { [weak self] (response: AuthRegisterResponse) in
                self?.createCustomerProfile(token: response.token, email: email, firstName: firstName, lastName: lastName, phone: phone, password: password)
            })
            .store(in: &cancellables)
    }
    
    private func createCustomerProfile(token: String, email: String, firstName: String, lastName: String, phone: String, password: String) {
        let customerPayload = CustomerCreationPayload(
            email: email,
            firstName: firstName,
            lastName: lastName,
            phone: phone
        )
        
        guard let body = try? JSONEncoder().encode(customerPayload) else {
            errorMessage = "Failed to encode customer creation request"
            isLoading = false
            return
        }
        
        NetworkManager.shared.request(endpoint: "customers", method: "POST", body: body, requiresAuth: true)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = "Customer creation failed: \(error.localizedDescription)"
                    self?.isLoading = false
                }
            }, receiveValue: { [weak self] (response: CustomerResponse) in
                self?.loginAfterRegistration(email: email, password: password)
            })
            .store(in: &cancellables)
    }
    
    private func loginAfterRegistration(email: String, password: String) {
        let loginRequest = CustomerLoginRequest(email: email, password: password)
        
        guard let body = try? JSONEncoder().encode(loginRequest) else {
            errorMessage = "Failed to encode login request"
            isLoading = false
            return
        }
        
        NetworkManager.shared.requestData(endpoint: "auth/customer/emailpass", method: "POST", body: body)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = "Login after registration failed: \(error.localizedDescription)"
                    self?.isLoading = false
                }
            }, receiveValue: { [weak self] (data: Data) in
                self?.handleLoginResponse(data: data)
            })
            .store(in: &cancellables)
    }
    
    func login(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        let request = CustomerLoginRequest(email: email, password: password)
        
        guard let body = try? JSONEncoder().encode(request) else {
            errorMessage = "Failed to encode request"
            isLoading = false
            return
        }
        
        NetworkManager.shared.requestData(endpoint: "auth/customer/emailpass", method: "POST", body: body)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = "Login failed: \(error.localizedDescription)"
                    self?.isLoading = false
                }
            }, receiveValue: { [weak self] (data: Data) in
                self?.handleLoginResponse(data: data)
            })
            .store(in: &cancellables)
    }
    
    private func handleLoginResponse(data: Data) {
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                guard let token = json["token"] as? String else {
                    self.errorMessage = "No token found in login response"
                    self.isLoading = false
                    return
                }
                
                UserDefaults.standard.set(token, forKey: "auth_token")
                self.fetchCustomerProfileAfterLogin()
                return
            }
        } catch {
            // Failed to parse JSON, error message will be set below
        }
        
        self.errorMessage = "Failed to parse login response. Please check the console for details."
        self.isLoading = false
    }
    
    private func fetchCustomerProfileAfterLogin() {
        NetworkManager.shared.request(endpoint: "customers/me", requiresAuth: true)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "Failed to fetch customer profile: \(error.localizedDescription)"
                }
            }, receiveValue: { [weak self] (response: CustomerResponse) in
                guard let self = self else { return }
                self.currentCustomer = response.customer
                self.isAuthenticated = true
                self.saveCustomerData(response.customer)
                self.cartService?.handleUserLogin()
            })
            .store(in: &cancellables)
    }
    
    func fetchCustomerProfile() {
        NetworkManager.shared.requestData(endpoint: "customers/me", requiresAuth: true)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = "Failed to fetch profile: \(error.localizedDescription)"
                }
            }, receiveValue: { [weak self] (data: Data) in
                self?.handleCustomerProfileResponse(data: data)
            })
            .store(in: &cancellables)
    }
    
    private func handleCustomerProfileResponse(data: Data) {
        do {
            let response = try JSONDecoder().decode(CustomerResponse.self, from: data)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.currentCustomer = response.customer
                self.saveCustomerData(response.customer)
            }
            return
        } catch {
            // Failed to decode as CustomerResponse, error message will be set below
        }
        
        self.errorMessage = "Failed to parse customer profile response"
    }
    
    func addAddress(
        addressName: String?,
        company: String?,
        firstName: String,
        lastName: String,
        address1: String,
        address2: String?,
        city: String,
        countryCode: String,
        province: String?,
        postalCode: String,
        phone: String?,
        isDefaultShipping: Bool,
        isDefaultBilling: Bool,
        completion: @escaping (Bool, String?) -> Void
    ) {
        let addressRequest = AddressRequest(
            addressName: addressName,
            isDefaultShipping: isDefaultShipping,
            isDefaultBilling: isDefaultBilling,
            company: company,
            firstName: firstName,
            lastName: lastName,
            address1: address1,
            address2: address2,
            city: city,
            countryCode: countryCode,
            province: province,
            postalCode: postalCode,
            phone: phone
        )
        
        guard let body = try? JSONEncoder().encode(addressRequest) else {
            completion(false, "Failed to encode address request")
            return
        }
        
        NetworkManager.shared.request(endpoint: "customers/me/addresses", method: "POST", body: body, requiresAuth: true)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completionResult in
                if case .failure(let error) = completionResult {
                    completion(false, "Failed to add address: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] (response: AddressResponse) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self?.fetchCustomerProfile()
                }
                completion(true, nil)
            })
            .store(in: &cancellables)
    }
    
    func updateAddress(
        addressId: String,
        addressName: String?,
        company: String?,
        firstName: String,
        lastName: String,
        address1: String,
        address2: String?,
        city: String,
        countryCode: String,
        province: String?,
        postalCode: String,
        phone: String?,
        isDefaultShipping: Bool,
        isDefaultBilling: Bool,
        completion: @escaping (Bool, String?) -> Void
    ) {
        let addressRequest = AddressRequest(
            addressName: addressName,
            isDefaultShipping: isDefaultShipping,
            isDefaultBilling: isDefaultBilling,
            company: company,
            firstName: firstName,
            lastName: lastName,
            address1: address1,
            address2: address2,
            city: city,
            countryCode: countryCode,
            province: province,
            postalCode: postalCode,
            phone: phone
        )
        
        guard let body = try? JSONEncoder().encode(addressRequest) else {
            completion(false, "Failed to encode address request")
            return
        }
        
        NetworkManager.shared.request(endpoint: "customers/me/addresses/\(addressId)", method: "POST", body: body, requiresAuth: true)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completionResult in
                if case .failure(let error) = completionResult {
                    completion(false, "Failed to update address: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] (response: AddressResponse) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self?.fetchCustomerProfile()
                }
                completion(true, nil)
            })
            .store(in: &cancellables)
    }
    
    func deleteAddress(addressId: String, completion: @escaping (Bool, String?) -> Void) {
        NetworkManager.shared.requestData(endpoint: "customers/me/addresses/\(addressId)", method: "DELETE", requiresAuth: true)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completionResult in
                if case .failure(let error) = completionResult {
                    completion(false, "Failed to delete address: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] (response: Data) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self?.fetchCustomerProfile()
                }
                completion(true, nil)
            })
            .store(in: &cancellables)
    }
    
    func logout() {
        DispatchQueue.main.async { [weak self] in
            self?.isAuthenticated = false
            self?.currentCustomer = nil
        }
        
        UserDefaults.standard.removeObject(forKey: "customer")
        UserDefaults.standard.removeObject(forKey: "auth_token")
        
        cartService?.handleUserLogout()
        
        cancellables.removeAll()
    }
    
    private func saveCustomerData(_ customer: Customer) {
        if let encoded = try? JSONEncoder().encode(customer) {
            UserDefaults.standard.set(encoded, forKey: "customer")
        }
    }
}
