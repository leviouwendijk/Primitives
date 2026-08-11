import Foundation

public enum JSONValueError: Error, LocalizedError, Sendable {
    case typeMismatch(expected: String, actual: JSONValue)
    case invalidCast(description: String)
    case pathNotFound(path: String)
    case casingKeyCollision(first: String, second: String, result: String)

    public var errorDescription: String? {
        switch self {
        case .typeMismatch(let expected, let actual):
            return "Type mismatch: expected \(expected), got \(actual)."

        case .invalidCast(let description):
            return "Invalid cast: \(description)."

        case .pathNotFound(let path):
            return "JSON path not found: \(path)."

        case .casingKeyCollision(let first, let second, let result):
            return "JSON keys '\(first)' and '\(second)' both convert to '\(result)'."
        }
    }
}
