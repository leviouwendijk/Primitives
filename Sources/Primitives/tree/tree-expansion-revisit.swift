public enum TreeExpansionRevisitScope:
    Sendable,
    Equatable,
    Hashable
{
    case global
    case ancestors
}

public enum TreeExpansionRevisitAction:
    Sendable,
    Equatable,
    Hashable
{
    case skip
    case fail
}

public struct TreeExpansionRevisitError:
    Error,
    Sendable,
    Equatable
{
    public let scope: TreeExpansionRevisitScope
    public let address: TreeAddress
    public let first_address: TreeAddress

    public init(
        scope: TreeExpansionRevisitScope,
        address: TreeAddress,
        first_address: TreeAddress
    ) {
        self.scope = scope
        self.address = address
        self.first_address = first_address
    }
}

public struct TreeExpansionRevisitPolicy<Value> {
    public let scope: TreeExpansionRevisitScope
    public let action: TreeExpansionRevisitAction

    let identity: (
        Value
    ) -> AnyHashable

    private init(
        scope: TreeExpansionRevisitScope,
        action: TreeExpansionRevisitAction,
        identity: @escaping (
            Value
        ) -> AnyHashable
    ) {
        self.scope = scope
        self.action = action
        self.identity = identity
    }
}

public extension TreeExpansionRevisitPolicy {
    static func global<Identity: Hashable>(
        action: TreeExpansionRevisitAction = .skip,
        identity: @escaping (
            Value
        ) -> Identity
    ) -> Self {
        .init(
            scope: .global,
            action: action,
            identity: { value in
                AnyHashable(
                    identity(value)
                )
            }
        )
    }

    static func ancestors<Identity: Hashable>(
        action: TreeExpansionRevisitAction = .fail,
        identity: @escaping (
            Value
        ) -> Identity
    ) -> Self {
        .init(
            scope: .ancestors,
            action: action,
            identity: { value in
                AnyHashable(
                    identity(value)
                )
            }
        )
    }
}
