public enum TreeDescent:
    Sendable,
    Equatable,
    Hashable
{
    case descend
    case skip_children
}

public struct TreeDescentPolicy<Value>: Sendable {
    public typealias LocatedNode = Tree<Value>.LocatedNode
    public typealias Decision = @Sendable (LocatedNode) -> TreeDescent

    private let decision: Decision

    public init(
        _ decision: @escaping Decision
    ) {
        self.decision = decision
    }

    public func callAsFunction(
        _ located: LocatedNode
    ) -> TreeDescent {
        decision(
            located
        )
    }
}

public extension TreeDescentPolicy {
    static var unrestricted: Self {
        .init { _ in
            .descend
        }
    }

    static func descend_while(
        _ predicate: @escaping @Sendable (
            LocatedNode
        ) -> Bool
    ) -> Self {
        .init { located in
            predicate(located)
                ? .descend
                : .skip_children
        }
    }

    static func descend_while_value(
        _ predicate: @escaping @Sendable (
            Value
        ) -> Bool
    ) -> Self {
        descend_while { located in
            predicate(
                located.node.value
            )
        }
    }

    func and(
        _ other: Self
    ) -> Self {
        .init { located in
            guard self(located) == .descend else {
                return .skip_children
            }

            return other(
                located
            )
        }
    }

    func or(
        _ other: Self
    ) -> Self {
        .init { located in
            if self(located) == .descend {
                return .descend
            }

            return other(
                located
            )
        }
    }
}
