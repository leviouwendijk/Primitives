public struct JSONIssue:
    Sendable,
    Hashable
{
    public enum Kind:
        Sendable,
        Hashable
    {
        case missing
        case unexpected
        case typeMismatch
        case invalidValue
    }

    public let kind: Kind
    public let path: JSONCodingPath
    public let reason: String

    public init(
        kind: Kind,
        path: JSONCodingPath,
        reason: String
    ) {
        self.kind = kind
        self.path = path
        self.reason = reason
    }
}
