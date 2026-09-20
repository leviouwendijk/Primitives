public enum TreeCursorError:
    Error,
    Sendable,
    Equatable
{
    case address_not_found(TreeAddress)

    case child_index_out_of_bounds(
        parent: TreeAddress,
        index: Int,
        count: Int
    )
}

public struct TreeCursor<Value> {
    public let tree: Tree<Value>
    public let located: Tree<Value>.LocatedNode

    public init(
        tree: Tree<Value>,
        at address: TreeAddress
    ) throws {
        guard let node = tree.node(
            at: address
        ) else {
            throw TreeCursorError.address_not_found(
                address
            )
        }

        self.tree = tree
        self.located = .init(
            address: address,
            node: node
        )
    }

    private init(
        tree: Tree<Value>,
        located: Tree<Value>.LocatedNode
    ) {
        self.tree = tree
        self.located = located
    }
}

public extension TreeCursor {
    var address: TreeAddress {
        located.address
    }

    var node: Tree<Value>.Node {
        located.node
    }

    var depth: Int {
        address.depth
    }

    var parent: Self? {
        guard let parentAddress = address.parent else {
            return nil
        }

        guard let parentNode = tree.node(
            at: parentAddress
        ) else {
            return nil
        }

        return .init(
            tree: tree,
            located: .init(
                address: parentAddress,
                node: parentNode
            )
        )
    }

    var children: [Self] {
        node.children.indices.map { index in
            .init(
                tree: tree,
                located: .init(
                    address: address.child(
                        validIndex: index
                    ),
                    node: node.children[index]
                )
            )
        }
    }

    var first_child: Self? {
        guard let index = node.children.indices.first else {
            return nil
        }

        return .init(
            tree: tree,
            located: .init(
                address: address.child(
                    validIndex: index
                ),
                node: node.children[index]
            )
        )
    }

    var last_child: Self? {
        guard let index = node.children.indices.last else {
            return nil
        }

        return .init(
            tree: tree,
            located: .init(
                address: address.child(
                    validIndex: index
                ),
                node: node.children[index]
            )
        )
    }

    var previous_sibling: Self? {
        sibling(
            offset: -1
        )
    }

    var next_sibling: Self? {
        sibling(
            offset: 1
        )
    }

    func child(
        at index: Int
    ) throws -> Self {
        guard node.children.indices.contains(
            index
        ) else {
            throw TreeCursorError.child_index_out_of_bounds(
                parent: address,
                index: index,
                count: node.children.count
            )
        }

        return .init(
            tree: tree,
            located: .init(
                address: address.child(
                    validIndex: index
                ),
                node: node.children[index]
            )
        )
    }
}

private extension TreeCursor {
    func sibling(
        offset: Int
    ) -> Self? {
        if address.descendants.isEmpty {
            let index = address.root + offset

            guard tree.roots.indices.contains(
                index
            ) else {
                return nil
            }

            return .init(
                tree: tree,
                located: .init(
                    address: .init(
                        validRoot: index
                    ),
                    node: tree.roots[index]
                )
            )
        }

        guard let parentAddress = address.parent else {
            return nil
        }

        guard let parentNode = tree.node(
            at: parentAddress
        ) else {
            return nil
        }

        guard let currentIndex = address.descendants.last else {
            return nil
        }

        let index = currentIndex + offset

        guard parentNode.children.indices.contains(
            index
        ) else {
            return nil
        }

        return .init(
            tree: tree,
            located: .init(
                address: parentAddress.child(
                    validIndex: index
                ),
                node: parentNode.children[index]
            )
        )
    }
}

public extension Tree {
    func cursor(
        at address: TreeAddress
    ) throws -> TreeCursor<Value> {
        try .init(
            tree: self,
            at: address
        )
    }
}

extension TreeCursor: Sendable where Value: Sendable {}
extension TreeCursor: Equatable where Value: Equatable {}
extension TreeCursor: Hashable where Value: Hashable {}
