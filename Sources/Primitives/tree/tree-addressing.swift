public extension Tree {
    func forEachNode(
        traversal: TreeTraversal = .depth_first_preorder,
        limits: TreeTraversalLimits = .unlimited,
        descent: TreeDescentPolicy<Value> = .unrestricted,
        root_order: TreeRootOrderPolicy<Value> = .natural,
        child_order: TreeChildOrderPolicy<Value> = .natural,
        _ body: (
            _ located: LocatedNode
        ) throws -> Void
    ) rethrows {
        for located in walk(
            traversal,
            limits: limits,
            descent: descent,
            root_order: root_order,
            child_order: child_order
        ) {
            try body(
                located
            )
        }
    }

    var addresses: [TreeAddress] {
        walk()
            .map(\.address)
    }

    func located(
        traversal: TreeTraversal = .depth_first_preorder,
        limits: TreeTraversalLimits = .unlimited,
        descent: TreeDescentPolicy<Value> = .unrestricted,
        root_order: TreeRootOrderPolicy<Value> = .natural,
        child_order: TreeChildOrderPolicy<Value> = .natural
    ) -> [LocatedNode] {
        Array(
            walk(
                traversal,
                limits: limits,
                descent: descent,
                root_order: root_order,
                child_order: child_order
            )
        )
    }

    func node(
        at address: TreeAddress
    ) -> Node? {
        guard roots.indices.contains(address.root) else {
            return nil
        }

        var node = roots[address.root]

        for index in address.descendants {
            guard node.children.indices.contains(index) else {
                return nil
            }

            node = node.children[index]
        }

        return node
    }
}
