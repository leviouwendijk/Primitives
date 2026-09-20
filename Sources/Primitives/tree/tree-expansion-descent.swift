public struct TreeExpansionDescentPolicy<Value>: Sendable {
    public typealias Located = TreeExpansion<Value>.Located

    public typealias Decision = @Sendable (
        Located
    ) -> TreeDescent

    private let decision: Decision

    public init(
        _ decision: @escaping Decision
    ) {
        self.decision = decision
    }

    public func callAsFunction(
        _ located: Located
    ) -> TreeDescent {
        decision(
            located
        )
    }
}

public extension TreeExpansionDescentPolicy {
    static var unrestricted: Self {
        .init { _ in
            .descend
        }
    }

    static func descend_while(
        _ predicate: @escaping @Sendable (
            Located
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
                located.value
            )
        }
    }

    static func maximum_depth(
        _ depth: Int
    ) -> Self {
        precondition(
            depth >= 0
        )

        return descend_while { located in
            located.address.depth < depth
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
