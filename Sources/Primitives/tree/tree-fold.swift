public extension Tree {
    func fold<Result>(
        _ transform: (
            _ located: LocatedNode,
            _ children: [Result]
        ) throws -> Result
    ) rethrows -> [Result] {
        typealias Frame = (
            located: LocatedNode,
            next_child_index: Int,
            children: [Result]
        )

        var foldedRoots: [Result] = []
        foldedRoots.reserveCapacity(
            roots.count
        )

        for rootIndex in roots.indices {
            var stack: [Frame] = [
                (
                    located: .init(
                        address: .init(
                            validRoot: rootIndex
                        ),
                        node: roots[rootIndex]
                    ),
                    next_child_index: 0,
                    children: []
                ),
            ]

            while !stack.isEmpty {
                let frameIndex = stack.index(
                    before: stack.endIndex
                )

                let located = stack[frameIndex].located
                let childIndex =
                    stack[frameIndex].next_child_index

                if childIndex < located.node.children.count {
                    stack[frameIndex].next_child_index += 1

                    stack.append(
                        (
                            located: .init(
                                address: located.address.child(
                                    validIndex: childIndex
                                ),
                                node: located.node.children[childIndex]
                            ),
                            next_child_index: 0,
                            children: []
                        )
                    )

                    continue
                }

                let frame = stack.removeLast()

                let result = try transform(
                    frame.located,
                    frame.children
                )

                if stack.isEmpty {
                    foldedRoots.append(
                        result
                    )
                } else {
                    let parentIndex = stack.index(
                        before: stack.endIndex
                    )

                    stack[parentIndex].children.append(
                        result
                    )
                }
            }
        }

        return foldedRoots
    }
}
