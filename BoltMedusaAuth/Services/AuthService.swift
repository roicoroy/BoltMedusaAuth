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
    
    init() {
        checkAuthenticationStatus()
    }
    
    deinit {
        cancellables.removeAll()
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
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "Login after registration failed: \(error.localizedDescription)"
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
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    if case .failure(let error) = completion {
                        self.errorMessage = "Login failed: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] data in
                    self?.handleLoginResponse(data: data)
                }
            )
            .store(in: &cancellables)
    }
    
    private func handleLoginResponse(data: Data) {
        // First, let's see the raw response structure
        if let responseString = String(data: data, encoding: .utf8) {
            print("Raw Login Response: \(responseString)")
        }
        
        // Try to parse as JSON to understand the structure
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                print("Login Response JSON Structure: \(json)")
                
                // Try different parsing approaches
                if let customer = self.parseCustomerFromResponse(json: json) {
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.currentCustomer = customer
                        self.isAuthenticated = true
                        self.saveCustomerData(customer)
                        
                        // Save token if provided
                        if let token = json["token"] as? String {
                            UserDefaults.standard.set(token, forKey: "auth_token")
                        }
                    }
                    return
                }
            }
        } catch {
            print("Failed to parse JSON: \(error)")
        }
        
        // Fallback: Try standard LoginResponse decoding
        do {
            let response = try JSONDecoder().decode(LoginResponse.self, from: data)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if let customer = response.customer {
                    self.currentCustomer = customer
                    self.isAuthenticated = true
                    self.saveCustomerData(customer)
                    
                    // Save token if provided
                    if let token = response.token {
                        UserDefaults.standard.set(token, forKey: "auth_token")
                    }
                } else {
                    self.errorMessage = "No customer data in response"
                }
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Failed to parse login response: \(error.localizedDescription)"
                print("Login parsing error: \(error)")
            }
        }
    }
    
    private func parseCustomerFromResponse(json: [String: Any]) -> Customer? {
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
        // Case 3: Customer might be under "data" key
        else if let data = json["data"] as? [String: Any],
                let nestedCustomer = data["customer"] as? [String: Any] {
            customerData = nestedCustomer
        }
        
        guard let customerJson = customerData else {
            print("Could not find customer data in response")
            return nil
        }
        
        // Convert back to Data and decode
        do {
            let customerJsonData = try JSONSerialization.data(withJSONObject: customerJson, options: [])
            let customer = try JSONDecoder().decode(Customer.self, from: customerJsonData)
            return customer
        } catch {
            print("Failed to decode customer from extracted data: \(error)")
            return nil
        }
    }
    
    func fetchCustomerProfile() {
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            self.errorMessage = "No authentication token found"
            return
        }
        
        guard let url = URL(string: "\(baseURL)/store/customers/me") else {
            self.errorMessage = "Invalid URL"
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(publishableKey, forHTTPHeaderField: "x-publishable-api-key")
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .map(\.data)
            .decode(type: CustomerResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = "Failed to fetch profile: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    self.currentCustomer = response.customer
                    self.saveCustomerData(response.customer)
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
        
        cancellables.removeAll()
    }
    
    private func saveCustomerData(_ customer: Customer) {
        if let encoded = try? JSONEncoder().encode(customer) {
            UserDefaults.standard.set(encoded, forKey: "customer")
        }
    }
}