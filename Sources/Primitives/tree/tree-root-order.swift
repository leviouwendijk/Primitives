public struct TreeRootOrderPolicy<Value>: Sendable {
    public typealias Node = Tree<Value>.Node

    public typealias Comparison = @Sendable (
        _ lhs: Node,
        _ rhs: Node
    ) -> Bool

    private let ordering: @Sendable (
        _ roots: [Node]
    ) -> [Int]

    private init(
        _ ordering: @escaping @Sendable (
            _ roots: [Node]
        ) -> [Int]
    ) {
        self.ordering = ordering
    }

    public func callAsFunction(
        _ roots: [Node]
    ) -> [Int] {
        ordering(
            roots
        )
    }
}

public extension TreeRootOrderPolicy {
    static var natural: Self {
        .init { roots in
            Array(
                roots.indices
            )
        }
    }

    static var reversed: Self {
        .init { roots in
            Array(
                roots.indices.reversed()
            )
        }
    }

    static func sorted(
        by areInIncreasingOrder: @escaping Comparison
    ) -> Self {
        .init { roots in
            roots.indices.sorted { lhs, rhs in
                let lhsNode = roots[lhs]
                let rhsNode = roots[rhs]

                if areInIncreasingOrder(
                    lhsNode,
                    rhsNode
                ) {
                    return true
                }

                if areInIncreasingOrder(
                    rhsNode,
                    lhsNode
                ) {
                    return false
                }

                return lhs < rhs
            }
        }
    }

    static func sorted_by_value(
        _ areInIncreasingOrder: @escaping @Sendable (
            _ lhs: Value,
            _ rhs: Value
        ) -> Bool
    ) -> Self {
        sorted { lhs, rhs in
            areInIncreasingOrder(
                lhs.value,
                rhs.value
            )
        }
    }
}
