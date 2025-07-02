//
//  NetworkManager.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 02/07/2025.
//

import Foundation
import Combine

public class NetworkManager {
    private let baseURL: String
    private let publishableKey: String

    public init(baseURL: String, publishableKey: String) {
        self.baseURL = baseURL
        self.publishableKey = publishableKey
    }

    public func request<T: Decodable>(
        path: String,
        method: String,
        body: Encodable? = nil,
        authToken: String? = nil
    ) -> AnyPublisher<T, Error> {
        guard var urlComponents = URLComponents(string: baseURL) else {
            fatalError("Invalid base URL")
        }
        urlComponents.path = path

        guard let url = urlComponents.url else {
            fatalError("Invalid URL path: \(path)")
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(publishableKey, forHTTPHeaderField: "x-publishable-api-key")

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try? JSONEncoder().encode(body)
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                // Log response for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("\(method) \(path) Response Status: \(httpResponse.statusCode)")
                    print("\(method) \(path) Response Body: \(responseString)")
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    // Attempt to decode a common error response if available
                    if let errorResponse = try? JSONDecoder().decode(MedusaErrorResponse.self, from: data) {
                        throw MedusaAPIError.apiError(errorResponse.message)
                    } else {
                        throw URLError(.badServerResponse)
                    }
                }
                return data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}

// MARK: - Generic Error Handling
public struct MedusaErrorResponse: Decodable {
    public let message: String
    public let type: String?
    public let code: String?
}

public enum MedusaAPIError: Error, LocalizedError {
    case apiError(String)
    case unknown

    public var errorDescription: String? {
        switch self {
        case .apiError(let message):
            return message
        case .unknown:
            return "An unknown error occurred."
        }
    }
}
