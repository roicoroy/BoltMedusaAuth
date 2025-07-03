
import Foundation

func decodeFlexibleInt<Key: CodingKey>(from container: KeyedDecodingContainer<Key>, forKey key: Key) throws -> Int? {
    // Try to decode as Int first
    if let intValue = try? container.decodeIfPresent(Int.self, forKey: key) {
        return intValue
    }

    // Try to decode as Double and convert to Int (multiply by 100 for cents)
    if let doubleValue = try? container.decodeIfPresent(Double.self, forKey: key) {
        // Convert to cents (multiply by 100 and round)
        return Int(round(doubleValue * 100))
    }

    // Try to decode as String and convert
    if let stringValue = try? container.decodeIfPresent(String.self, forKey: key) {
        if let doubleValue = Double(stringValue) {
            // Convert to cents (multiply by 100 and round)
            return Int(round(doubleValue * 100))
        }
        if let intValue = Int(stringValue) {
            return intValue
        }
    }

    // If all fail, return nil
    return nil
}
