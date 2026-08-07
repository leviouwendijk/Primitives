import Foundation

public enum UUIDIdentifierError:
    Error,
    LocalizedError,
    Sendable,
    Equatable
{
    case invalid_uuid(
        type: String,
        provided: String
    )

    public var errorDescription: String? {
        switch self {
        case .invalid_uuid(let type, let provided):
            return "Invalid \(type) UUID identifier: \(provided)"
        }
    }
}
