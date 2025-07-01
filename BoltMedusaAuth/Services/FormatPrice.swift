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
    
    let decimalAmount = Double(amount) / 100.0
    return formatter.string(from: NSNumber(value: decimalAmount)) ?? "\(currencyCode.uppercased()) 0.00"
}
