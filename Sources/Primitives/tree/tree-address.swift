public struct TreeAddress:
    Sendable,
    Equatable,
    Hashable,
    Codable,
    Comparable
{
    public let root: Int
    public let descendants: [Int]

    public init(
        root: Int,
        descendants: [Int] = []
    ) throws {
        guard root >= 0 else {
            throw Error.negative_root(
                root
            )
        }

        if let position = descendants.firstIndex(
            where: { $0 < 0 }
        ) {
            throw Error.negative_descendant(
                position: position,
                value: descendants[position]
            )
        }

        self.root = root
        self.descendants = descendants
    }
}

public extension TreeAddress {
    var depth: Int {
        descendants.count
    }

    var parent: Self? {
        guard !descendants.isEmpty else {
            return nil
        }

        return .init(
            validRoot: root,
            descendants: Array(
                descendants.dropLast()
            )
        )
    }

    func child(
        _ index: Int
    ) throws -> Self {
        guard index >= 0 else {
            throw Error.negative_descendant(
                position: descendants.count,
                value: index
            )
        }

        return .init(
            validRoot: root,
            descendants: descendants + [index]
        )
    }

    func is_ancestor(
        of other: Self
    ) -> Bool {
        guard root == other.root else {
            return false
        }

        guard descendants.count < other.descendants.count else {
            return false
        }

        return other.descendants
            .prefix(
                descendants.count
            )
            .elementsEqual(
                descendants
            )
    }

    func is_descendant(
        of other: Self
    ) -> Bool {
        other.is_ancestor(
            of: self
        )
    }

    static func < (
        lhs: Self,
        rhs: Self
    ) -> Bool {
        if lhs.root != rhs.root {
            return lhs.root < rhs.root
        }

        let sharedCount = Swift.min(
            lhs.descendants.count,
            rhs.descendants.count
        )

        for index in 0..<sharedCount {
            let lhsIndex = lhs.descendants[index]
            let rhsIndex = rhs.descendants[index]

            if lhsIndex != rhsIndex {
                return lhsIndex < rhsIndex
            }
        }

        return lhs.descendants.count
            < rhs.descendants.count
    }
}

extension TreeAddress {
    private enum CodingKeys: String, CodingKey {
        case root
        case descendants
    }

    public init(
        from decoder: Decoder
    ) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        let root = try container.decode(
            Int.self,
            forKey: .root
        )

        let descendants = try container.decode(
            [Int].self,
            forKey: .descendants
        )

        try self.init(
            root: root,
            descendants: descendants
        )
    }

    public func encode(
        to encoder: Encoder
    ) throws {
        var container = encoder.container(
            keyedBy: CodingKeys.self
        )

        try container.encode(
            root,
            forKey: .root
        )

        try container.encode(
            descendants,
            forKey: .descendants
        )
    }
}

public extension TreeAddress {
    enum Error: Swift.Error, Sendable, Equatable {
        case negative_root(Int)
        case negative_descendant(
            position: Int,
            value: Int
        )
    }
}

extension TreeAddress {
    internal init(
        validRoot root: Int,
        descendants: [Int] = []
    ) {
        precondition(
            root >= 0
        )

        precondition(
            descendants.allSatisfy { $0 >= 0 }
        )

        self.root = root
        self.descendants = descendants
    }

    internal func child(
        validIndex index: Int
    ) -> Self {
        precondition(
            index >= 0
        )

        return .init(
            validRoot: root,
            descendants: descendants + [index]
        )
    }
}
