public extension Tree {
    func map_values<MappedValue>(
        _ transform: (
            _ located: LocatedNode
        ) throws -> MappedValue
    ) rethrows -> Tree<MappedValue> {
        let mappedRoots = try fold { located, children in
            Tree<MappedValue>.Node(
                try transform(
                    located
                ),
                annotations: located.node.annotations,
                children: children
            )
        }

        return .init(
            roots: mappedRoots
        )
    }
}
