import Foundation

public struct NonBlankString: Sendable, Codable, Equatable, Hashable {
    public var rawValue: String

    public init(
        _ rawValue: String
    ) throws {
        let trimmed = rawValue.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmed.isEmpty else {
            throw NonBlankStringError.blank
        }

        self.rawValue = trimmed
    }
}

extension NonBlankString: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

public enum NonBlankStringError: Error, LocalizedError, Sendable, Equatable {
    case blank

    public var errorDescription: String? {
        switch self {
        case .blank:
            return "Expected a non-blank string."
        }
    }
}
