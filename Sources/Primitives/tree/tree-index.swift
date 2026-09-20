public enum TreeIndexDuplicatePolicy:
    Sendable,
    Equatable,
    Hashable
{
    case collect
    case reject
}

public enum TreeIndexError:
    Error,
    Sendable,
    Equatable
{
    case duplicate_key(
        first: TreeAddress,
        duplicate: TreeAddress
    )
}

public struct TreeIndex<Key: Hashable> {
    private let storage: [
        Key: [TreeAddress]
    ]

    public init<Value>(
        tree: Tree<Value>,
        duplicate_policy: TreeIndexDuplicatePolicy = .collect,
        key: (
            _ located: Tree<Value>.LocatedNode
        ) throws -> Key?
    ) throws {
        var storage: [
            Key: [TreeAddress]
        ] = [:]

        for located in tree.walk() {
            guard let key = try key(
                located
            ) else {
                continue
            }

            if
                duplicate_policy == .reject,
                let first = storage[key]?.first
            {
                throw TreeIndexError.duplicate_key(
                    first: first,
                    duplicate: located.address
                )
            }

            storage[key, default: []].append(
                located.address
            )
        }

        self.storage = storage
    }
}

public extension TreeIndex {
    var count: Int {
        storage.count
    }

    var isEmpty: Bool {
        storage.isEmpty
    }

    subscript(
        _ key: Key
    ) -> [TreeAddress] {
        storage[key]
            ?? []
    }

    func addresses(
        for key: Key
    ) -> [TreeAddress] {
        self[key]
    }

    func first_address(
        for key: Key
    ) -> TreeAddress? {
        storage[key]?.first
    }

    func contains(
        _ key: Key
    ) -> Bool {
        storage[key] != nil
    }
}

public extension Tree {
    func index<Key: Hashable>(
        duplicate_policy: TreeIndexDuplicatePolicy = .collect,
        by key: (
            _ located: LocatedNode
        ) throws -> Key?
    ) throws -> TreeIndex<Key> {
        try .init(
            tree: self,
            duplicate_policy: duplicate_policy,
            key: key
        )
    }
}

extension TreeIndex: Sendable where Key: Sendable {}
extension TreeIndex: Equatable {}
