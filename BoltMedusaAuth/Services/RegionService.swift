//
//  RegionService.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 28/06/2025.
//

import Foundation
import Combine

class RegionService: ObservableObject {
    @Published var regions: [Region] = []
    @Published var selectedRegion: Region?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let baseURL = "https://1839-2a00-23c7-dc88-f401-c478-f6a-492c-22da.ngrok-free.app"
    private let publishableKey = "pk_d62e2de8f849db562e79a89c8a08ec4f5d23f1a958a344d5f64dfc38ad39fa1a"
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadSelectedRegionFromStorage()
        fetchRegions()
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Region Management
    
    func fetchRegions() {
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = true
            self?.errorMessage = nil
        }
        
        guard let url = URL(string: "\(baseURL)/store/regions") else {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Invalid URL for regions"
                self?.isLoading = false
            }
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(publishableKey, forHTTPHeaderField: "x-publishable-api-key")
        
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("Regions Response Status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Regions Response: \(responseString)")
                    }
                    
                    if httpResponse.statusCode >= 400 {
                        throw URLError(.badServerResponse)
                    }
                }
                return data
            }
            .decode(type: RegionsResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "Failed to fetch regions: \(error.localizedDescription)"
                        print("Regions fetch error: \(error)")
                    }
                },
                receiveValue: { [weak self] response in
                    self?.regions = response.regions
                    self?.setDefaultRegionIfNeeded()
                    print("Fetched \(response.regions.count) regions")
                    
                    // Debug: Print all regions and their countries
                    for region in response.regions {
                        print("Region: \(region.name) (\(region.id)) - Currency: \(region.currencyCode)")
                        if let countries = region.countries {
                            print("  Countries: \(countries.map { "\($0.displayName) (\($0.iso2))" }.joined(separator: ", "))")
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func selectRegion(_ region: Region) {
        DispatchQueue.main.async { [weak self] in
            self?.selectedRegion = region
        }
        saveSelectedRegionToStorage(region)
        print("Selected region: \(region.name) (\(region.id)) - Currency: \(region.currencyCode)")
        
        if let countries = region.countries {
            print("  Available countries: \(countries.map { $0.displayName }.joined(separator: ", "))")
        }
    }
    
    // MARK: - Default Region Logic
    
    private func setDefaultRegionIfNeeded() {
        // If no region is selected, try to find the best default region
        guard selectedRegion == nil else { return }
        
        // Since we only have one "Europe" region that includes UK, select it as default
        if let europeRegion = regions.first(where: { $0.name.lowercased().contains("europe") }) {
            selectRegion(europeRegion)
            print("Set Europe region as default: \(europeRegion.name)")
            return
        }
        
        // If no Europe region found, use the first available region
        if let firstRegion = regions.first {
            selectRegion(firstRegion)
            print("Set first available region as default: \(firstRegion.name)")
        }
    }
    
    // MARK: - Storage
    
    private func saveSelectedRegionToStorage(_ region: Region) {
        if let encoded = try? JSONEncoder().encode(region) {
            UserDefaults.standard.set(encoded, forKey: "selected_region")
        }
    }
    
    private func loadSelectedRegionFromStorage() {
        if let regionData = UserDefaults.standard.data(forKey: "selected_region"),
           let region = try? JSONDecoder().decode(Region.self, from: regionData) {
            DispatchQueue.main.async { [weak self] in
                self?.selectedRegion = region
            }
            print("Loaded selected region from storage: \(region.name)")
        }
    }
    
    // MARK: - Utility Methods
    
    func refreshRegions() {
        fetchRegions()
    }
    
    var hasSelectedRegion: Bool {
        return selectedRegion != nil
    }
    
    var selectedRegionId: String? {
        return selectedRegion?.id
    }
    
    var selectedRegionCurrency: String? {
        return selectedRegion?.currencyCode
    }
    
    // MARK: - Country-specific helpers
    
    func getCountriesForSelectedRegion() -> [Country] {
        return selectedRegion?.countries ?? []
    }
    
    func hasUKInSelectedRegion() -> Bool {
        return selectedRegion?.hasUK ?? false
    }
}