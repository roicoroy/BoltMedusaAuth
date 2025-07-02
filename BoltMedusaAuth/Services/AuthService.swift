//
//  AuthService.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 28/06/2025.
//

import Foundation
import Combine

class AuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentCustomer: Customer?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkManager: NetworkManager
    private var cancellables = Set<AnyCancellable>()
    
    // Cart service reference for handling cart association
    weak var cartService: CartService?
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
        checkAuthenticationStatus()
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Cart Service Integration
    
    func setCartService(_ cartService: CartService) {
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
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = true
            self?.errorMessage = nil
        }
        
        // Step 1: Register auth customer
        registerAuthCustomer(email: email, password: password, firstName: firstName, lastName: lastName, phone: phone)
    }
    
    private func registerAuthCustomer(email: String, password: String, firstName: String, lastName: String, phone: String) {
        let authPayload = AuthRegisterPayload(
            firstName: firstName,
            lastName: lastName,
            email: email,
            password: password,
            phone: phone
        )
        
        networkManager.request(
            path: "/auth/customer/emailpass/register",
            method: "POST",
            body: authPayload
        )
        .decode(type: AuthRegisterResponse.self, decoder: JSONDecoder())
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = "Auth registration failed: \(error.localizedDescription)"
                    self?.isLoading = false
                }
            },
            receiveValue: { [weak self] response in
                self?.createCustomerProfile(
                    token: response.token,
                    email: email,
                    firstName: firstName,
                    lastName: lastName,
                    phone: phone,
                    password: password
                )
            }
        )
        .store(in: &cancellables)
    }
    
    private func createCustomerProfile(token: String, email: String, firstName: String, lastName: String, phone: String, password: String) {
        let customerPayload = CustomerCreationPayload(
            email: email,
            firstName: firstName,
            lastName: lastName,
            phone: phone
        )
        
        networkManager.request(
            path: "/store/customers",
            method: "POST",
            body: customerPayload,
            authToken: token
        )
        .decode(type: CustomerResponse.self, decoder: JSONDecoder())
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = "Customer creation failed: \(error.localizedDescription)"
                    self?.isLoading = false
                }
            },
            receiveValue: { [weak self] response in
                self?.loginAfterRegistration(email: email, password: password)
            }
        )
        .store(in: &cancellables)
    }
    
    private func loginAfterRegistration(email: String, password: String) {
        let loginRequest = CustomerLoginRequest(email: email, password: password)
        
        networkManager.request(
            path: "/auth/customer/emailpass",
            method: "POST",
            body: loginRequest
        )
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = "Login after registration failed: \(error.localizedDescription)"
                    self?.isLoading = false
                }
            },
            receiveValue: { [weak self] data in
                self?.handleLoginResponse(data: data)
            }
        )
        .store(in: &cancellables)
    }
    
    func login(email: String, password: String) {
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = true
            self?.errorMessage = nil
        }
        
        let request = CustomerLoginRequest(email: email, password: password)
        
        networkManager.request(
            path: "/auth/customer/emailpass",
            method: "POST",
            body: request
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = "Login failed: \(error.localizedDescription)"
                    self?.isLoading = false
                }
            },
            receiveValue: { [weak self] data in
                self?.handleLoginResponse(data: data)
            }
        )
        .store(in: &cancellables)
    }
    
    private func handleLoginResponse(data: Data) {
        // Log the raw response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("Raw Login Response: \(responseString)")
        }
        
        // Parse as JSON to extract the token
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                print("Login Response JSON Structure: \(json)")
                
                // Extract token from response
                guard let token = json["token"] as? String else {
                    self.errorMessage = "No token found in login response"
                    self.isLoading = false
                    return
                }
                
                // Save the token
                UserDefaults.standard.set(token, forKey: "auth_token")
                print("Token saved successfully")
                
                // Now fetch the customer profile using the token
                self.fetchCustomerProfileAfterLogin()
                return
            }
        } catch {
            print("Failed to parse JSON: \(error)")
        }
        
        // If JSON parsing fails, show error
        self.errorMessage = "Failed to parse login response. Please check the console for details."
        self.isLoading = false
    }
    
    private func fetchCustomerProfileAfterLogin() {
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            self.errorMessage = "No authentication token found"
            self.isLoading = false
            return
        }
        
        networkManager.request(
            path: "/store/customers/me",
            method: "GET",
            authToken: token
        )
        .decode(type: CustomerResponse.self, decoder: JSONDecoder())
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "Failed to fetch customer profile: \(error.localizedDescription)"
                }
            },
            receiveValue: { [weak self] response in
                guard let self = self else { return }
                self.currentCustomer = response.customer
                self.isAuthenticated = true
                self.saveCustomerData(response.customer)
                print("Login successful! Customer profile loaded.")
                
                self.cartService?.handleUserLogin()
            }
        )
        .store(in: &cancellables)
    }
    
    func fetchCustomerProfile() {
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "No authentication token found"
            }
            return
        }
        
        networkManager.request(
            path: "/store/customers/me",
            method: "GET",
            authToken: token
        )
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    print("Failed to fetch customer profile: \(error)")
                    DispatchQueue.main.async {
                        self?.errorMessage = "Failed to fetch profile: \(error.localizedDescription)"
                    }
                }
            },
            receiveValue: { [weak self] data in
                self?.handleCustomerProfileResponse(data: data)
            }
        )
        .store(in: &cancellables)
    }
    
    private func handleCustomerProfileResponse(data: Data) {
        // Log the raw response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("Raw Customer Profile Response: \(responseString)")
        }
        
        // Try to decode as CustomerResponse first
        do {
            let response = try JSONDecoder().decode(CustomerResponse.self, from: data)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.currentCustomer = response.customer
                self.saveCustomerData(response.customer)
                print("Customer profile updated successfully")
            }
            return
        } catch {
            print("Failed to decode as CustomerResponse: \(error)")
        }
        
        // Try to parse as JSON and extract customer data manually
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                print("Customer Profile JSON Structure: \(json)")
                
                // Try to extract customer from different possible structures
                var customerData: [String: Any]?
                
                // Case 1: Customer is nested under "customer" key
                if let nestedCustomer = json["customer"] as? [String: Any] {
                    customerData = nestedCustomer
                }
                // Case 2: Customer data is at root level
                else if json["id"] != nil && json["email"] != nil {
                    customerData = json
                }
                
                if let customerJson = customerData {
                    // Convert back to Data and decode
                    let customerJsonData = try JSONSerialization.data(withJSONObject: customerJson, options: [])
                    let customer = try JSONDecoder().decode(Customer.self, from: customerJsonData)
                    
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.currentCustomer = customer
                        self.saveCustomerData(customer)
                        print("Customer profile updated successfully (manual parsing)")
                    }
                    return
                }
            }
        } catch {
            print("Failed to parse customer profile JSON: \(error)")
        }
        
        // If all parsing fails, show error
        DispatchQueue.main.async { [weak self] in
            self?.errorMessage = "Failed to parse customer profile response"
        }
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
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            completion(false, "No authentication token found")
            return
        }
        
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
        
        networkManager.request(
            path: "/store/customers/me/addresses",
            method: "POST",
            body: addressRequest,
            authToken: token
        )
        .sink(
            receiveCompletion: { [weak self] completionResult in
                if case .failure(let error) = completionResult {
                    print("Add address failed: \(error)")
                    completion(false, "Failed to add address: \(error.localizedDescription)")
                }
            },
            receiveValue: { [weak self] data in
                do {
                    let _ = try JSONDecoder().decode(AddressResponse.self, from: data)
                    print("Address added successfully")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self?.fetchCustomerProfile()
                    }
                    
                    completion(true, nil)
                } catch {
                    print("Failed to decode address response: \(error)")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self?.fetchCustomerProfile()
                    }
                    completion(true, nil)
                }
            }
        )
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
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            completion(false, "No authentication token found")
            return
        }
        
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
        
        networkManager.request(
            path: "/store/customers/me/addresses/\(addressId)",
            method: "POST",
            body: addressRequest,
            authToken: token
        )
        .sink(
            receiveCompletion: { [weak self] completionResult in
                if case .failure(let error) = completionResult {
                    print("Update address failed: \(error)")
                    completion(false, "Failed to update address: \(error.localizedDescription)")
                }
            },
            receiveValue: { [weak self] data in
                do {
                    let _ = try JSONDecoder().decode(AddressResponse.self, from: data)
                    print("Address updated successfully")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self?.fetchCustomerProfile()
                    }
                    
                    completion(true, nil)
                } catch {
                    print("Failed to decode address response: \(error)")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self?.fetchCustomerProfile()
                    }
                    completion(true, nil)
                }
            }
        )
        .store(in: &cancellables)
    }
    
    func deleteAddress(addressId: String, completion: @escaping (Bool, String?) -> Void) {
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            completion(false, "No authentication token found")
            return
        }
        
        networkManager.request(
            path: "/store/customers/me/addresses/\(addressId)",
            method: "DELETE",
            authToken: token
        )
        .sink(
            receiveCompletion: { [weak self] completionResult in
                if case .failure(let error) = completionResult {
                    print("Delete address failed: \(error)")
                    completion(false, "Failed to delete address: \(error.localizedDescription)")
                }
            },
            receiveValue: { [weak self] data in
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Delete Address Success Response: \(responseString)")
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self?.fetchCustomerProfile()
                }
                
                completion(true, nil)
            }
        )
        .store(in: &cancellables)
    }
    
    func logout() {
        DispatchQueue.main.async { [weak self] in
            self?.isAuthenticated = false
            self?.currentCustomer = nil
        }
        
        UserDefaults.standard.removeObject(forKey: "customer")
        UserDefaults.standard.removeObject(forKey: "auth_token")
        
        // Notify cart service about user logout
        cartService?.handleUserLogout()
        
        cancellables.removeAll()
    }
    
    private func saveCustomerData(_ customer: Customer) {
        if let encoded = try? JSONEncoder().encode(customer) {
            UserDefaults.standard.set(encoded, forKey: "customer")
        }
    }
}
