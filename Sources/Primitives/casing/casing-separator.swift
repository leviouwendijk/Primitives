public extension Casing {
    struct Separator:
        RawRepresentable,
        Sendable,
        Codable,
        Hashable
    {
        public let rawValue: String

        public init(
            rawValue: String
        ) {
            self.rawValue = rawValue
        }

        public init(
            from decoder: Decoder
        ) throws {
            let container = try decoder.singleValueContainer()
            self.init(
                rawValue: try container.decode(String.self)
            )
        }

        public func encode(
            to encoder: Encoder
        ) throws {
            var container = encoder.singleValueContainer()
            try container.encode(
                rawValue
            )
        }

        public static let none = Self(rawValue: "")
        public static let underscore = Self(rawValue: "_")
        public static let hyphen = Self(rawValue: "-")
        public static let dot = Self(rawValue: ".")
        public static let slash = Self(rawValue: "/")
        public static let space = Self(rawValue: " ")
    }
}
