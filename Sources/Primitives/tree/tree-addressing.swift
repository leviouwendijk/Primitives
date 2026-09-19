public extension Tree {
    func forEachNode(
        _ body: (
            _ located: LocatedNode
        ) throws -> Void
    ) rethrows {
        for (rootIndex, root) in roots.enumerated() {
            let address = TreeAddress(
                validRoot: rootIndex
            )

            try walk(
                node: root,
                at: address,
                body
            )
        }
    }

    var addresses: [TreeAddress] {
        var addresses: [TreeAddress] = []

        forEachNode { located in
            addresses.append(
                located.address
            )
        }

        return addresses
    }

    func located() -> [LocatedNode] {
        var result: [LocatedNode] = []

        forEachNode { located in
            result.append(
                located
            )
        }

        return result
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

private extension Tree {
    func walk(
        node: Node,
        at address: TreeAddress,
        _ body: (
            _ located: LocatedNode
        ) throws -> Void
    ) rethrows {
        try body(
            .init(
                address: address,
                node: node
            )
        )

        for (index, child) in node.children.enumerated() {
            try walk(
                node: child,
                at: address.child(
                    validIndex: index
                ),
                body
            )
        }
    }
}
