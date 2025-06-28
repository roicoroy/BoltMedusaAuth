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
    
    private let baseURL = "https://your-medusa-backend.com" // Replace with your Medusa backend URL
    private let publishableKey = "pk_d62e2de8f849db562e79a89c8a08ec4f5d23f1a958a344d5f64dfc38ad39fa1a"
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Check if user is already logged in
        checkAuthenticationStatus()
    }
    
    private func checkAuthenticationStatus() {
        // Check for stored authentication token or customer data
        if let customerData = UserDefaults.standard.data(forKey: "customer"),
           let customer = try? JSONDecoder().decode(Customer.self, from: customerData) {
            self.currentCustomer = customer
            self.isAuthenticated = true
        }
    }
    
    func register(email: String, password: String, firstName: String?, lastName: String?, phone: String?) {
        isLoading = true
        errorMessage = nil
        
        let request = CustomerRegistrationRequest(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName,
            phone: phone
        )
        
        guard let url = URL(string: "\(baseURL)/store/customers") else {
            self.errorMessage = "Invalid URL"
            self.isLoading = false
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(publishableKey, forHTTPHeaderField: "x-publishable-api-key")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            self.errorMessage = "Failed to encode request"
            self.isLoading = false
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .map(\.data)
            .decode(type: MedusaResponse<Customer>.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] response in
                    if let customer = response.customer {
                        self?.currentCustomer = customer
                        self?.isAuthenticated = true
                        self?.saveCustomerData(customer)
                        
                        // After registration, automatically log in
                        self?.login(email: email, password: password)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func login(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        let request = CustomerLoginRequest(email: email, password: password)
        
        guard let url = URL(string: "\(baseURL)/store/auth/customer/emailpass") else {
            self.errorMessage = "Invalid URL"
            self.isLoading = false
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(publishableKey, forHTTPHeaderField: "x-publishable-api-key")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            self.errorMessage = "Failed to encode request"
            self.isLoading = false
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .map(\.data)
            .decode(type: MedusaResponse<Customer>.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] response in
                    if let customer = response.customer {
                        self?.currentCustomer = customer
                        self?.isAuthenticated = true
                        self?.saveCustomerData(customer)
                        
                        // Save token if provided
                        if let token = response.token {
                            UserDefaults.standard.set(token, forKey: "auth_token")
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func logout() {
        isAuthenticated = false
        currentCustomer = nil
        
        // Clear stored data
        UserDefaults.standard.removeObject(forKey: "customer")
        UserDefaults.standard.removeObject(forKey: "auth_token")
    }
    
    private func saveCustomerData(_ customer: Customer) {
        if let encoded = try? JSONEncoder().encode(customer) {
            UserDefaults.standard.set(encoded, forKey: "customer")
        }
    }
}