
//
//  ProductCategory.swift
//  BoltMedusaAuth
//
//  Created by Ricardo Bento on 02/07/2025.
//

import Foundation

// MARK: - ProductCategory Model
public class ProductCategory: Codable, Identifiable {
    public let id: String
    public let name: String?
    public let description: String?
    public let handle: String?
    public let rank: Int?
    public let parentCategoryId: String?
    public let parentCategory: ProductCategory? // Nested parent category
    public let categoryChildren: [ProductCategory]? // Nested children categories
    public let createdAt: String?
    public let updatedAt: String?
    public let deletedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, description, handle, rank
        case parentCategoryId = "parent_category_id"
        case parentCategory = "parent_category"
        case categoryChildren = "category_children"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}

// MARK: - API Request/Response Models for Product Categories
public struct ProductCategoriesResponse: Codable {
    public let limit: Int
    public let offset: Int
    public let count: Int
    public let productCategories: [ProductCategory]

    enum CodingKeys: String, CodingKey {
        case limit, offset, count
        case productCategories = "product_categories"
    }
}

public struct ProductCategoryResponse: Codable {
    public let productCategory: ProductCategory

    enum CodingKeys: String, CodingKey {
        case productCategory = "product_category"
    }
}
