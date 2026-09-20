public struct TreeTraversalLimits:
    Sendable,
    Equatable,
    Hashable,
    Codable
{
    public let maximum_depth: Int?

    public init(
        maximum_depth: Int? = nil
    ) throws {
        if let maximum_depth,
           maximum_depth < 0 {
            throw TreeTraversalLimitError.negative_maximum_depth(
                maximum_depth
            )
        }

        self.maximum_depth = maximum_depth
    }

    private init(
        validated_maximum_depth: Int?
    ) {
        self.maximum_depth = validated_maximum_depth
    }

    public static let unlimited = Self(
        validated_maximum_depth: nil
    )

    private enum CodingKeys: String, CodingKey {
        case maximum_depth
    }

    public init(
        from decoder: Decoder
    ) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        try self.init(
            maximum_depth: container.decodeIfPresent(
                Int.self,
                forKey: .maximum_depth
            )
        )
    }

    public func encode(
        to encoder: Encoder
    ) throws {
        var container = encoder.container(
            keyedBy: CodingKeys.self
        )

        try container.encodeIfPresent(
            maximum_depth,
            forKey: .maximum_depth
        )
    }
}

public enum TreeTraversalLimitError:
    Error,
    Sendable,
    Equatable
{
    case negative_maximum_depth(Int)
}

extension TreeTraversalLimits {
    func allows_descent(
        from address: TreeAddress
    ) -> Bool {
        guard let maximum_depth else {
            return true
        }

        return address.depth < maximum_depth
    }
}
