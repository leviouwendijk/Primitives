public extension TreeExpansion {
    func materialize(
        limits: TreeTraversalLimits = .unlimited,
        descent: TreeExpansionDescentPolicy<Value> = .unrestricted,
        child_order: TreeExpansionChildOrderPolicy<Value> = .natural,
        revisit: TreeExpansionRevisitPolicy<Value>? = nil,
        annotations: (
            _ located: Located
        ) throws -> [TreeAnnotation] = { _ in [] }
    ) throws -> Tree<Value> {
        var iterator = walk(
            .depth_first_postorder,
            limits: limits,
            descent: descent,
            child_order: child_order,
            revisit: revisit
        )
        .makeIterator()

        var completed: [
            TreeAddress: Tree<Value>.Node
        ] = [:]

        while let located = try iterator.next() {
            var children: [Tree<Value>.Node] = []
            var childIndex = 0

            while true {
                let childAddress = located.address.child(
                    validIndex: childIndex
                )

                guard let child = completed.removeValue(
                    forKey: childAddress
                ) else {
                    break
                }

                children.append(
                    child
                )

                childIndex += 1
            }

            completed[located.address] = .init(
                located.value,
                annotations: try annotations(
                    located
                ),
                children: children
            )
        }

        var roots: [Tree<Value>.Node] = []
        var rootIndex = 0

        while true {
            let address = TreeAddress(
                validRoot: rootIndex
            )

            guard let root = completed.removeValue(
                forKey: address
            ) else {
                break
            }

            roots.append(
                root
            )

            rootIndex += 1
        }

        guard completed.isEmpty else {
            throw TreeExpansionError.incomplete_materialization(
                remaining: Set(
                    completed.keys
                )
            )
        }

        return .init(
            roots: roots
        )
    }
}
