public struct TreeAddress: Sendable, Equatable, Hashable {
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
