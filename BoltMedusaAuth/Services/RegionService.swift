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
    @Published var countryList: [CountrySelection] = []
    @Published var selectedCountry: CountrySelection?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let baseURL = "https://1839-2a00-23c7-dc88-f401-c478-f6a-492c-22da.ngrok-free.app"
    private let publishableKey = "pk_d62e2de8f849db562e79a89c8a08ec4f5d23f1a958a344d5f64dfc38ad39fa1a"
    private let defaultCountryCode = "gb" // Default to UK
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadSelectedCountryFromStorage()
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
                    self?.processCountries(from: response.regions)
                    print("Fetched \(response.regions.count) regions")
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Country Processing (following the example pattern)
    
    private func processCountries(from regions: [Region]) {
        // Flatten all countries from all regions into a single list
        let newCountryList: [CountrySelection] = regions.compactMap { region in
            return region.countries?.map { country in
                CountrySelection(
                    country: country.iso2,
                    label: country.displayName,
                    currencyCode: region.currencyCode,
                    regionId: region.id
                )
            }
        }.flatMap { $0 }
        .sorted { $0.label.localizedCompare($1.label) == .orderedAscending }
        
        DispatchQueue.main.async { [weak self] in
            self?.countryList = newCountryList
            self?.setDefaultCountryIfNeeded()
        }
        
        print("Processed \(newCountryList.count) countries from regions:")
        for country in newCountryList {
            print("  \(country.flagEmoji) \(country.label) (\(country.country.uppercased())) - \(country.formattedCurrency) - Region: \(country.regionId)")
        }
    }
    
    private func setDefaultCountryIfNeeded() {
        // If no country is selected, try to find the default country
        guard selectedCountry == nil else { return }
        
        // Look for the default country code (UK)
        if let defaultCountry = countryList.first(where: { $0.country.lowercased() == defaultCountryCode }) {
            selectCountry(defaultCountry)
            print("Set default country: \(defaultCountry.label) (\(defaultCountry.country.uppercased()))")
            return
        }
        
        // If default country not found, use the first available country
        if let firstCountry = countryList.first {
            selectCountry(firstCountry)
            print("Set first available country as default: \(firstCountry.label)")
        }
    }
    
    func selectCountry(_ country: CountrySelection) {
        DispatchQueue.main.async { [weak self] in
            self?.selectedCountry = country
        }
        saveSelectedCountryToStorage(country)
        print("Selected country: \(country.flagEmoji) \(country.label) (\(country.country.uppercased())) - \(country.formattedCurrency) - Region: \(country.regionId)")
    }
    
    // MARK: - Storage
    
    private func saveSelectedCountryToStorage(_ country: CountrySelection) {
        if let encoded = try? JSONEncoder().encode(country) {
            UserDefaults.standard.set(encoded, forKey: "selected_country")
        }
    }
    
    private func loadSelectedCountryFromStorage() {
        if let countryData = UserDefaults.standard.data(forKey: "selected_country"),
           let country = try? JSONDecoder().decode(CountrySelection.self, from: countryData) {
            DispatchQueue.main.async { [weak self] in
                self?.selectedCountry = country
            }
            print("Loaded selected country from storage: \(country.label)")
        }
    }
    
    // MARK: - Utility Methods
    
    func refreshRegions() {
        fetchRegions()
    }
    
    var hasSelectedRegion: Bool {
        return selectedCountry != nil
    }
    
    var selectedRegionId: String? {
        return selectedCountry?.regionId
    }
    
    var selectedRegionCurrency: String? {
        return selectedCountry?.currencyCode
    }
    
    // MARK: - Backward compatibility properties for existing views
    
    var selectedRegion: Region? {
        guard let selectedCountry = selectedCountry else { return nil }
        return regions.first { $0.id == selectedCountry.regionId }
    }
    
    func selectRegion(_ region: Region) {
        // For backward compatibility, select the first country from this region
        if let firstCountry = region.toCountrySelections().first {
            selectCountry(firstCountry)
        }
    }
    
    // MARK: - Country-specific helpers
    
    func getCountriesForSelectedRegion() -> [Country] {
        guard let selectedRegion = selectedRegion else { return [] }
        return selectedRegion.countries ?? []
    }
    
    func hasUKInSelectedRegion() -> Bool {
        return selectedCountry?.country.lowercased() == "gb"
    }
}