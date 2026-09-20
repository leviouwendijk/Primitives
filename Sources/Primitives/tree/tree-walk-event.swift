public enum TreeWalkEvent<Value> {
    case enter(Tree<Value>.LocatedNode)
    case exit(Tree<Value>.LocatedNode)
}

extension TreeWalkEvent: Sendable where Value: Sendable {}
extension TreeWalkEvent: Equatable where Value: Equatable {}
extension TreeWalkEvent: Hashable where Value: Hashable {}

public struct TreeEventWalk<Value>: Sequence {
    public typealias Element = TreeWalkEvent<Value>

    private let roots: [Tree<Value>.Node]
    private let limits: TreeTraversalLimits
    private let descent: TreeDescentPolicy<Value>
    private let root_order: TreeRootOrderPolicy<Value>
    private let child_order: TreeChildOrderPolicy<Value>

    fileprivate init(
        roots: [Tree<Value>.Node],
        limits: TreeTraversalLimits,
        descent: TreeDescentPolicy<Value>,
        root_order: TreeRootOrderPolicy<Value>,
        child_order: TreeChildOrderPolicy<Value>
    ) {
        self.roots = roots
        self.limits = limits
        self.descent = descent
        self.root_order = root_order
        self.child_order = child_order
    }

    public func makeIterator() -> Iterator {
        .init(
            roots: roots,
            limits: limits,
            descent: descent,
            root_order: root_order,
            child_order: child_order
        )
    }
}

public extension TreeEventWalk {
    struct Iterator: IteratorProtocol {
        public typealias Element = TreeWalkEvent<Value>
        public typealias LocatedNode = Tree<Value>.LocatedNode

        private let limits: TreeTraversalLimits
        private let descent: TreeDescentPolicy<Value>
        private let child_order: TreeChildOrderPolicy<Value>
        private var stack: [Element]

        fileprivate init(
            roots: [Tree<Value>.Node],
            limits: TreeTraversalLimits,
            descent: TreeDescentPolicy<Value>,
            root_order: TreeRootOrderPolicy<Value>,
            child_order: TreeChildOrderPolicy<Value>
        ) {
            self.limits = limits
            self.descent = descent
            self.child_order = child_order
            self.stack = []

            let rootIndices = root_order(
                roots
            )

            for rootIndex in rootIndices.reversed() {
                stack.append(
                    .enter(
                        .init(
                            address: .init(
                                validRoot: rootIndex
                            ),
                            node: roots[rootIndex]
                        )
                    )
                )
            }
        }

        public mutating func next() -> Element? {
            guard let event = stack.popLast() else {
                return nil
            }

            switch event {
            case .enter(let located):
                stack.append(
                    .exit(
                        located
                    )
                )

                if limits.allows_descent(
                    from: located.address
                ), descent(located) == .descend {
                    let childIndices = child_order(
                        located
                    )

                    for childIndex in childIndices.reversed() {
                        stack.append(
                            .enter(
                                located_child(
                                    childIndex,
                                    of: located
                                )
                            )
                        )
                    }
                }

            case .exit:
                break
            }

            return event
        }

        private func located_child(
            _ index: Int,
            of located: LocatedNode
        ) -> LocatedNode {
            .init(
                address: located.address.child(
                    validIndex: index
                ),
                node: located.node.children[index]
            )
        }
    }
}

public extension Tree {
    func events(
        limits: TreeTraversalLimits = .unlimited,
        descent: TreeDescentPolicy<Value> = .unrestricted,
        root_order: TreeRootOrderPolicy<Value> = .natural,
        child_order: TreeChildOrderPolicy<Value> = .natural
    ) -> TreeEventWalk<Value> {
        .init(
            roots: roots,
            limits: limits,
            descent: descent,
            root_order: root_order,
            child_order: child_order
        )
    }
}

extension TreeEventWalk: Sendable where Value: Sendable {}
