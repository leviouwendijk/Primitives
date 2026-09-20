public struct TreeExpansionChildOrderPolicy<Value>: Sendable {
    public typealias Located = TreeExpansion<Value>.Located

    public typealias Ordering = @Sendable (
        _ parent: Located,
        _ children: [Value]
    ) -> [Int]

    private let ordering: Ordering

    public init(
        _ ordering: @escaping Ordering
    ) {
        self.ordering = ordering
    }

    public func callAsFunction(
        parent: Located,
        children: [Value]
    ) -> [Int] {
        ordering(
            parent,
            children
        )
    }
}

public extension TreeExpansionChildOrderPolicy {
    static var natural: Self {
        .init { _, children in
            Array(
                children.indices
            )
        }
    }

    static var reversed: Self {
        .init { _, children in
            Array(
                children.indices.reversed()
            )
        }
    }

    static func sorted(
        by areInIncreasingOrder: @escaping @Sendable (
            _ lhs: Value,
            _ rhs: Value
        ) -> Bool
    ) -> Self {
        .init { _, children in
            children.indices.sorted { lhs, rhs in
                if areInIncreasingOrder(
                    children[lhs],
                    children[rhs]
                ) {
                    return true
                }

                if areInIncreasingOrder(
                    children[rhs],
                    children[lhs]
                ) {
                    return false
                }

                return lhs < rhs
            }
        }
    }
}
