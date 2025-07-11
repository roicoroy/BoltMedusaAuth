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
    
    private let baseURL = "https://1839-2a00-23c7-dc88-f401-c478-f6a-492c-22da.ngrok-free.app"
    private let publishableKey = "pk_d62e2de8f849db562e79a89c8a08ec4f5d23f1a958a344d5f64dfc38ad39fa1a"
    
    private var cancellables = Set<AnyCancellable>()
    
    // Cart service reference for handling cart association
    weak var cartService: CartService?
    
    init() {
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
        
        guard let url = URL(string: "\(baseURL)/auth/customer/emailpass/register") else {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Invalid URL for auth registration"
                self?.isLoading = false
            }
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(publishableKey, forHTTPHeaderField: "x-publishable-api-key")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(authPayload)
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Failed to encode auth registration request: \(error.localizedDescription)"
                self?.isLoading = false
            }
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("Auth Registration Response Status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Auth Registration Response: \(responseString)")
                    }
                    
                    if httpResponse.statusCode >= 400 {
                        throw URLError(.badServerResponse)
                    }
                }
                return data
            }
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
                    // Step 2: Create customer profile using JWT token
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
        
        guard let url = URL(string: "\(baseURL)/store/customers") else {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Invalid URL for customer creation"
                self?.isLoading = false
            }
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(publishableKey, forHTTPHeaderField: "x-publishable-api-key")
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(customerPayload)
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Failed to encode customer creation request: \(error.localizedDescription)"
                self?.isLoading = false
            }
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("Customer Creation Response Status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Customer Creation Response: \(responseString)")
                    }
                    
                    if httpResponse.statusCode >= 400 {
                        throw URLError(.badServerResponse)
                    }
                }
                return data
            }
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
                    // Step 3: Login with email and password
                    self?.loginAfterRegistration(email: email, password: password)
                }
            )
            .store(in: &cancellables)
    }
    
    private func loginAfterRegistration(email: String, password: String) {
        let loginRequest = CustomerLoginRequest(email: email, password: password)
        
        guard let url = URL(string: "\(baseURL)/auth/customer/emailpass") else {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Invalid URL for login"
                self?.isLoading = false
            }
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(publishableKey, forHTTPHeaderField: "x-publishable-api-key")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(loginRequest)
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Failed to encode login request: \(error.localizedDescription)"
                self?.isLoading = false
            }
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("Login After Registration Response Status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Login After Registration Response: \(responseString)")
                    }
                    
                    if httpResponse.statusCode >= 400 {
                        throw URLError(.badServerResponse)
                    }
                }
                return data
            }
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
        
        guard let url = URL(string: "\(baseURL)/auth/customer/emailpass") else {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Invalid URL"
                self?.isLoading = false
            }
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(publishableKey, forHTTPHeaderField: "x-publishable-api-key")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Failed to encode request: \(error.localizedDescription)"
                self?.isLoading = false
            }
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("Login Response Status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Login Response: \(responseString)")
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
        
        guard let url = URL(string: "\(baseURL)/store/customers/me") else {
            self.errorMessage = "Invalid URL for customer profile"
            self.isLoading = false
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(publishableKey, forHTTPHeaderField: "x-publishable-api-key")
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("Customer Profile Response Status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Customer Profile Response: \(responseString)")
                    }
                    
                    if httpResponse.statusCode >= 400 {
                        throw URLError(.badServerResponse)
                    }
                }
                return data
            }
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
                    
                    // Notify cart service about user login
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
        
        guard let url = URL(string: "\(baseURL)/store/customers/me") else {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Invalid URL"
            }
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(publishableKey, forHTTPHeaderField: "x-publishable-api-key")
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("Fetch Customer Profile Response Status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Fetch Customer Profile Response: \(responseString)")
                    }
                    
                    if httpResponse.statusCode >= 400 {
                        throw URLError(.badServerResponse)
                    }
                }
                return data
            }
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
        
        guard let url = URL(string: "\(baseURL)/store/customers/me/addresses") else {
            completion(false, "Invalid URL")
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
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(publishableKey, forHTTPHeaderField: "x-publishable-api-key")
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(addressRequest)
        } catch {
            completion(false, "Failed to encode address request: \(error.localizedDescription)")
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("Add Address Response Status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Add Address Response: \(responseString)")
                    }
                    
                    if httpResponse.statusCode >= 400 {
                        throw URLError(.badServerResponse)
                    }
                }
                return data
            }
            .sink(
                receiveCompletion: { [weak self] completionResult in
                    if case .failure(let error) = completionResult {
                        print("Add address failed: \(error)")
                        completion(false, "Failed to add address: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] data in
                    // Log the response for debugging
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Add Address Success Response: \(responseString)")
                    }
                    
                    // Try to decode the response to verify it's valid
                    do {
                        let _ = try JSONDecoder().decode(AddressResponse.self, from: data)
                        print("Address added successfully")
                        
                        // Refresh customer profile to get updated addresses
                        // Add a small delay to ensure the server has processed the address
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self?.fetchCustomerProfile()
                        }
                        
                        completion(true, nil)
                    } catch {
                        print("Failed to decode address response: \(error)")
                        // Even if decoding fails, the address might have been created
                        // So we still refresh and report success
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
        
        guard let url = URL(string: "\(baseURL)/store/customers/me/addresses/\(addressId)") else {
            completion(false, "Invalid URL")
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
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(publishableKey, forHTTPHeaderField: "x-publishable-api-key")
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(addressRequest)
        } catch {
            completion(false, "Failed to encode address request: \(error.localizedDescription)")
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("Update Address Response Status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Update Address Response: \(responseString)")
                    }
                    
                    if httpResponse.statusCode >= 400 {
                        throw URLError(.badServerResponse)
                    }
                }
                return data
            }
            .sink(
                receiveCompletion: { [weak self] completionResult in
                    if case .failure(let error) = completionResult {
                        print("Update address failed: \(error)")
                        completion(false, "Failed to update address: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] data in
                    // Log the response for debugging
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Update Address Success Response: \(responseString)")
                    }
                    
                    // Try to decode the response to verify it's valid
                    do {
                        let _ = try JSONDecoder().decode(AddressResponse.self, from: data)
                        print("Address updated successfully")
                        
                        // Refresh customer profile to get updated addresses
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self?.fetchCustomerProfile()
                        }
                        
                        completion(true, nil)
                    } catch {
                        print("Failed to decode address response: \(error)")
                        // Even if decoding fails, the address might have been updated
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
        
        guard let url = URL(string: "\(baseURL)/store/customers/me/addresses/\(addressId)") else {
            completion(false, "Invalid URL")
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(publishableKey, forHTTPHeaderField: "x-publishable-api-key")
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("Delete Address Response Status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Delete Address Response: \(responseString)")
                    }
                    
                    if httpResponse.statusCode >= 400 {
                        throw URLError(.badServerResponse)
                    }
                }
                return data
            }
            .sink(
                receiveCompletion: { [weak self] completionResult in
                    if case .failure(let error) = completionResult {
                        print("Delete address failed: \(error)")
                        completion(false, "Failed to delete address: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] data in
                    // Log the response for debugging
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Delete Address Success Response: \(responseString)")
                    }
                    
                    
                    
                    // Refresh customer profile to get updated addresses
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