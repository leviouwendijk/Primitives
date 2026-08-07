import Foundation

public enum StringIdentifierValidationError:
    Error,
    LocalizedError,
    Sendable,
    Equatable
{
    case empty(
        field: String
    )

    case whitespace_not_allowed(
        field: String
    )

    public var errorDescription: String? {
        switch self {
        case .empty(let field):
            return "Identifier value '\(field)' cannot be empty."

        case .whitespace_not_allowed(let field):
            return "Identifier value '\(field)' cannot contain whitespace."
        }
    }
}
