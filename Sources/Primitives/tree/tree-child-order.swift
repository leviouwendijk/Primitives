public struct TreeChildOrderPolicy<Value>: Sendable {
    public typealias LocatedNode = Tree<Value>.LocatedNode
    public typealias Node = Tree<Value>.Node

    public typealias Comparison = @Sendable (
        _ lhs: Node,
        _ rhs: Node
    ) -> Bool

    private let ordering: @Sendable (
        LocatedNode
    ) -> [Int]

    private init(
        _ ordering: @escaping @Sendable (
            LocatedNode
        ) -> [Int]
    ) {
        self.ordering = ordering
    }

    public func callAsFunction(
        _ located: LocatedNode
    ) -> [Int] {
        ordering(
            located
        )
    }
}

public extension TreeChildOrderPolicy {
    static var natural: Self {
        .init { located in
            Array(
                located.node.children.indices
            )
        }
    }

    static var reversed: Self {
        .init { located in
            Array(
                located.node.children.indices.reversed()
            )
        }
    }

    static func sorted(
        by areInIncreasingOrder: @escaping Comparison
    ) -> Self {
        .init { located in
            located.node.children.indices.sorted { lhs, rhs in
                let lhsNode = located.node.children[lhs]
                let rhsNode = located.node.children[rhs]

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
