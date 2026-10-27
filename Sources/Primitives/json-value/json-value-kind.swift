extension JSONValue {
    public enum Kind: String, Codable, Sendable, Hashable, CaseIterable {
        case null
        case boolean
        case integer
        case number
        case string
        case array
        case object
    }

    public var kind: Kind {
        switch self {
        case .null:   .null
        case .bool:   .boolean
        case .int:    .integer
        case .double: .number
        case .string: .string
        case .array:  .array
        case .object: .object
        }
    }
}
