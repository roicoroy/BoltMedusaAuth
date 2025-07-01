//
//  FormatPrice.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 01/07/2025.
//

import Foundation

// MARK: - Currency Formatting

func formatPrice(_ amount: Int, currencyCode: String) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = currencyCode.uppercased()
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    
    // Convert from cents to main currency unit (divide by 100)
    let decimalAmount = Double(amount) / 100.0
    return formatter.string(from: NSNumber(value: decimalAmount)) ?? "\(currencyCode.uppercased()) 0.00"
}

// MARK: - Price Formatting Extensions

extension Int {
    func formatAsCurrency(currencyCode: String) -> String {
        return formatPrice(self, currencyCode: currencyCode)
    }
    
    func formatAsCurrency(currencyCode: String?) -> String {
        return formatPrice(self, currencyCode: currencyCode ?? "USD")
    }
}

// MARK: - Debug Price Formatting

func debugPriceFormatting() {
    print("=== PRICE FORMATTING DEBUG ===")
    
    let testAmounts = [1000, 1050, 2500, 999, 0, 12345]
    let testCurrencies = ["GBP", "USD", "EUR", "JPY"]
    
    for currency in testCurrencies {
        print("\n\(currency) Examples:")
        for amount in testAmounts {
            let formatted = formatPrice(amount, currencyCode: currency)
            print("  \(amount) cents = \(formatted)")
        }
    }
    
    print("\n=== END DEBUG ===")
}