import Foundation

public struct JSONDecodingError:
    Error,
    LocalizedError,
    Sendable,
    Hashable
{
    public enum Kind:
        Sendable,
        Hashable
    {
        case keyNotFound
        case typeMismatch
        case valueNotFound
        case dataCorrupted
        case other
    }

    public let kind: Kind
    public let path: JSONCodingPath
    public let reason: String
    public let key: String?
    public let expectedType: String?

    public init(
        _ error: any Error
    ) {
        switch error {
        case DecodingError.keyNotFound(
            let key,
            let context
        ):
            var codingPath = context.codingPath
            codingPath.append(
                key
            )

            self.init(
                kind: .keyNotFound,
                path: JSONCodingPath(
                    codingPath: codingPath
                ),
                reason: context.debugDescription,
                key: key.stringValue,
                expectedType: nil
            )

        case DecodingError.typeMismatch(
            let type,
            let context
        ):
            self.init(
                kind: .typeMismatch,
                path: JSONCodingPath(
                    codingPath: context.codingPath
                ),
                reason: context.debugDescription,
                key: nil,
                expectedType: String(
                    describing: type
                )
            )

        case DecodingError.valueNotFound(
            let type,
            let context
        ):
            self.init(
                kind: .valueNotFound,
                path: JSONCodingPath(
                    codingPath: context.codingPath
                ),
                reason: context.debugDescription,
                key: nil,
                expectedType: String(
                    describing: type
                )
            )

        case DecodingError.dataCorrupted(
            let context
        ):
            self.init(
                kind: .dataCorrupted,
                path: JSONCodingPath(
                    codingPath: context.codingPath
                ),
                reason: context.debugDescription,
                key: nil,
                expectedType: nil
            )

        default:
            self.init(
                kind: .other,
                path: JSONCodingPath(),
                reason: error.localizedDescription,
                key: nil,
                expectedType: nil
            )
        }
    }

    public var errorDescription: String? {
        switch kind {
        case .keyNotFound:
            return "Missing JSON key '\(key ?? "?")' at \(path). \(reason)"

        case .typeMismatch:
            return "JSON type mismatch at \(path); expected \(expectedType ?? "value"). \(reason)"

        case .valueNotFound:
            return "JSON value not found at \(path); expected \(expectedType ?? "value"). \(reason)"

        case .dataCorrupted:
            return "Invalid JSON value at \(path). \(reason)"

        case .other:
            return "JSON decoding failed at \(path). \(reason)"
        }
    }

    private init(
        kind: Kind,
        path: JSONCodingPath,
        reason: String,
        key: String?,
        expectedType: String?
    ) {
        self.kind = kind
        self.path = path
        self.reason = reason
        self.key = key
        self.expectedType = expectedType
    }
}
