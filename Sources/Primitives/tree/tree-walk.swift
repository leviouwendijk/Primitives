public struct TreeWalk<Value>: Sequence {
    public typealias Element = Tree<Value>.LocatedNode

    private let roots: [Tree<Value>.Node]
    private let traversal: TreeTraversal
    private let limits: TreeTraversalLimits
    private let descent: TreeDescentPolicy<Value>
    private let root_order: TreeRootOrderPolicy<Value>
    private let child_order: TreeChildOrderPolicy<Value>

    fileprivate init(
        roots: [Tree<Value>.Node],
        traversal: TreeTraversal,
        limits: TreeTraversalLimits,
        descent: TreeDescentPolicy<Value>,
        root_order: TreeRootOrderPolicy<Value>,
        child_order: TreeChildOrderPolicy<Value>
    ) {
        self.roots = roots
        self.traversal = traversal
        self.limits = limits
        self.descent = descent
        self.root_order = root_order
        self.child_order = child_order
    }

    public func makeIterator() -> Iterator {
        .init(
            roots: roots,
            traversal: traversal,
            limits: limits,
            descent: descent,
            root_order: root_order,
            child_order: child_order
        )
    }
}

public extension TreeWalk {
    struct Iterator: IteratorProtocol {
        public typealias Element = Tree<Value>.LocatedNode

        private struct PostorderEntry {
            let located: Element
            let expanded: Bool
        }

        private let traversal: TreeTraversal
        private let limits: TreeTraversalLimits
        private let descent: TreeDescentPolicy<Value>
        private let child_order: TreeChildOrderPolicy<Value>

        private var depth_first_preorder_stack: [Element]
        private var depth_first_postorder_stack: [PostorderEntry]

        private var breadth_first_level: [Element]
        private var breadth_first_next_level: [Element]
        private var breadth_first_index: Int

        fileprivate init(
            roots: [Tree<Value>.Node],
            traversal: TreeTraversal,
            limits: TreeTraversalLimits,
            descent: TreeDescentPolicy<Value>,
            root_order: TreeRootOrderPolicy<Value>,
            child_order: TreeChildOrderPolicy<Value>
        ) {
            self.traversal = traversal
            self.limits = limits
            self.descent = descent
            self.child_order = child_order

            self.depth_first_preorder_stack = []
            self.depth_first_postorder_stack = []

            self.breadth_first_level = []
            self.breadth_first_next_level = []
            self.breadth_first_index = 0

            let rootIndices = root_order(
                roots
            )

            switch traversal {
            case .depth_first_preorder:
                for rootIndex in rootIndices.reversed() {
                    depth_first_preorder_stack.append(
                        .init(
                            address: .init(
                                validRoot: rootIndex
                            ),
                            node: roots[rootIndex]
                        )
                    )
                }

            case .depth_first_postorder:
                for rootIndex in rootIndices.reversed() {
                    depth_first_postorder_stack.append(
                        .init(
                            located: .init(
                                address: .init(
                                    validRoot: rootIndex
                                ),
                                node: roots[rootIndex]
                            ),
                            expanded: false
                        )
                    )
                }

            case .breadth_first:
                for rootIndex in rootIndices {
                    breadth_first_level.append(
                        .init(
                            address: .init(
                                validRoot: rootIndex
                            ),
                            node: roots[rootIndex]
                        )
                    )
                }
            }
        }

        public mutating func next() -> Element? {
            switch traversal {
            case .depth_first_preorder:
                walk_depth_first_preorder()

            case .depth_first_postorder:
                walk_depth_first_postorder()

            case .breadth_first:
                walk_breadth_first()
            }
        }
    }
}

private extension TreeWalk.Iterator {
    func located_child(
        _ index: Int,
        of located: Element
    ) -> Element {
        .init(
            address: located.address.child(
                validIndex: index
            ),
            node: located.node.children[index]
        )
    }

    mutating func walk_depth_first_preorder() -> Element? {
        guard let located = depth_first_preorder_stack.popLast() else {
            return nil
        }

        if limits.allows_descent(
            from: located.address
        ), descent(located) == .descend {
            let childIndices = child_order(
                located
            )

            for childIndex in childIndices.reversed() {
                depth_first_preorder_stack.append(
                    located_child(
                        childIndex,
                        of: located
                    )
                )
            }
        }

        return located
    }

    mutating func walk_depth_first_postorder() -> Element? {
        while let entry = depth_first_postorder_stack.popLast() {
            if entry.expanded {
                return entry.located
            }

            guard limits.allows_descent(
                from: entry.located.address
            ), descent(entry.located) == .descend else {
                return entry.located
            }

            depth_first_postorder_stack.append(
                .init(
                    located: entry.located,
                    expanded: true
                )
            )

            let childIndices = child_order(
                entry.located
            )

            for childIndex in childIndices.reversed() {
                depth_first_postorder_stack.append(
                    .init(
                        located: located_child(
                            childIndex,
                            of: entry.located
                        ),
                        expanded: false
                    )
                )
            }
        }

        return nil
    }

    mutating func walk_breadth_first() -> Element? {
        while true {
            if breadth_first_index < breadth_first_level.count {
                let located =
                    breadth_first_level[breadth_first_index]

                breadth_first_index += 1

                if limits.allows_descent(
                    from: located.address
                ), descent(located) == .descend {
                    let childIndices = child_order(
                        located
                    )

                    for childIndex in childIndices {
                        breadth_first_next_level.append(
                            located_child(
                                childIndex,
                                of: located
                            )
                        )
                    }
                }

                return located
            }

            guard !breadth_first_next_level.isEmpty else {
                return nil
            }

            breadth_first_level =
                breadth_first_next_level

            breadth_first_next_level = []
            breadth_first_index = 0
        }
    }
}

public extension Tree {
    func walk(
        _ traversal: TreeTraversal = .depth_first_preorder,
        limits: TreeTraversalLimits = .unlimited,
        descent: TreeDescentPolicy<Value> = .unrestricted,
        root_order: TreeRootOrderPolicy<Value> = .natural,
        child_order: TreeChildOrderPolicy<Value> = .natural
    ) -> TreeWalk<Value> {
        .init(
            roots: roots,
            traversal: traversal,
            limits: limits,
            descent: descent,
            root_order: root_order,
            child_order: child_order
        )
    }
}

extension TreeWalk: Sendable where Value: Sendable {}
