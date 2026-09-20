public struct TreeExpansionWalk<Value> {
    private let expansion: TreeExpansion<Value>
    private let traversal: TreeTraversal
    private let descent: TreeExpansionDescentPolicy<Value>
    private let child_order: TreeExpansionChildOrderPolicy<Value>
    private let revisit: TreeExpansionRevisitPolicy<Value>?

    fileprivate init(
        expansion: TreeExpansion<Value>,
        traversal: TreeTraversal,
        descent: TreeExpansionDescentPolicy<Value>,
        child_order: TreeExpansionChildOrderPolicy<Value>,
        revisit: TreeExpansionRevisitPolicy<Value>?
    ) {
        self.expansion = expansion
        self.traversal = traversal
        self.descent = descent
        self.child_order = child_order
        self.revisit = revisit
    }

    public func makeIterator() -> Iterator {
        .init(
            expansion: expansion,
            traversal: traversal,
            descent: descent,
            child_order: child_order,
            revisit: revisit
        )
    }
}

public extension TreeExpansionWalk {
    struct Iterator {
        fileprivate struct IdentityLocation {
            let identity: AnyHashable
            let address: TreeAddress
        }

        fileprivate struct Pending {
            let located: TreeExpansion<Value>.Located
            let identity: AnyHashable?
            let ancestors: [IdentityLocation]
        }

        fileprivate enum PreorderEntry {
            case yield(Pending)
            case expand(Pending)
        }

        fileprivate struct PostorderEntry {
            let pending: Pending
            let expanded: Bool
        }

        private let expansion: TreeExpansion<Value>
        private let traversal: TreeTraversal
        private let descent: TreeExpansionDescentPolicy<Value>
        private let child_order: TreeExpansionChildOrderPolicy<Value>
        private let revisit: TreeExpansionRevisitPolicy<Value>?

        private var global_seen: [AnyHashable: TreeAddress]

        private var next_root_source_index: Int
        private var next_root_output_index: Int

        private var depth_first_preorder_stack: [PreorderEntry]
        private var depth_first_postorder_stack: [PostorderEntry]

        private var breadth_first_level: [Pending]
        private var breadth_first_next_level: [Pending]
        private var breadth_first_index: Int
        private var breadth_first_pending_expansion: Pending?
        private var breadth_first_roots_prepared: Bool

        fileprivate init(
            expansion: TreeExpansion<Value>,
            traversal: TreeTraversal,
            descent: TreeExpansionDescentPolicy<Value>,
            child_order: TreeExpansionChildOrderPolicy<Value>,
            revisit: TreeExpansionRevisitPolicy<Value>?
        ) {
            self.expansion = expansion
            self.traversal = traversal
            self.descent = descent
            self.child_order = child_order
            self.revisit = revisit

            self.global_seen = [:]

            self.next_root_source_index = 0
            self.next_root_output_index = 0

            self.depth_first_preorder_stack = []
            self.depth_first_postorder_stack = []

            self.breadth_first_level = []
            self.breadth_first_next_level = []
            self.breadth_first_index = 0
            self.breadth_first_pending_expansion = nil
            self.breadth_first_roots_prepared = false
        }

        public mutating func next() throws -> TreeExpansion<Value>.Located? {
            switch traversal {
            case .depth_first_preorder:
                try walk_depth_first_preorder()

            case .depth_first_postorder:
                try walk_depth_first_postorder()

            case .breadth_first:
                try walk_breadth_first()
            }
        }
    }
}

fileprivate extension TreeExpansionWalk.Iterator {
    mutating func next_depth_first_root() throws -> Pending? {
        while next_root_source_index < expansion.roots.count {
            let value = expansion.roots[
                next_root_source_index
            ]

            next_root_source_index += 1

            let address = TreeAddress(
                validRoot: next_root_output_index
            )

            guard let pending = try accepted_pending(
                value: value,
                address: address,
                ancestors: []
            ) else {
                continue
            }

            next_root_output_index += 1

            return pending
        }

        return nil
    }

    mutating func prepare_breadth_first_roots() throws {
        guard !breadth_first_roots_prepared else {
            return
        }

        breadth_first_roots_prepared = true

        var outputIndex = 0

        for value in expansion.roots {
            let address = TreeAddress(
                validRoot: outputIndex
            )

            guard let pending = try accepted_pending(
                value: value,
                address: address,
                ancestors: []
            ) else {
                continue
            }

            breadth_first_level.append(
                pending
            )

            outputIndex += 1
        }
    }

    mutating func accepted_pending(
        value: Value,
        address: TreeAddress,
        ancestors: [IdentityLocation]
    ) throws -> Pending? {
        guard let revisit else {
            return .init(
                located: .init(
                    address: address,
                    value: value
                ),
                identity: nil,
                ancestors: ancestors
            )
        }

        let identity = revisit.identity(
            value
        )

        let firstAddress: TreeAddress?

        switch revisit.scope {
        case .global:
            firstAddress = global_seen[
                identity
            ]

        case .ancestors:
            firstAddress = ancestors.first { entry in
                entry.identity == identity
            }?.address
        }

        if let firstAddress {
            switch revisit.action {
            case .skip:
                return nil

            case .fail:
                throw TreeExpansionRevisitError(
                    scope: revisit.scope,
                    address: address,
                    first_address: firstAddress
                )
            }
        }

        if revisit.scope == .global {
            global_seen[identity] = address
        }

        return .init(
            located: .init(
                address: address,
                value: value
            ),
            identity: identity,
            ancestors: ancestors
        )
    }

    func descendants_ancestors(
        of pending: Pending
    ) -> [IdentityLocation] {
        guard let identity = pending.identity else {
            return pending.ancestors
        }

        return pending.ancestors + [
            .init(
                identity: identity,
                address: pending.located.address
            ),
        ]
    }

    mutating func expanded_children(
        of pending: Pending
    ) throws -> [Pending] {
        guard descent(
            pending.located
        ) == .descend else {
            return []
        }

        let discovered = try expansion.children(
            of: pending.located
        )

        let indices = child_order(
            parent: pending.located,
            children: discovered
        )

        guard indices.count == discovered.count else {
            throw TreeExpansionError.child_order_count_mismatch(
                parent: pending.located.address,
                expected: discovered.count,
                actual: indices.count
            )
        }

        var seenIndices: Set<Int> = []

        for index in indices {
            guard discovered.indices.contains(
                index
            ) else {
                throw TreeExpansionError.child_order_index_out_of_bounds(
                    parent: pending.located.address,
                    index: index,
                    child_count: discovered.count
                )
            }

            guard seenIndices.insert(
                index
            ).inserted else {
                throw TreeExpansionError.duplicate_child_order_index(
                    parent: pending.located.address,
                    index: index
                )
            }
        }

        let ancestors = descendants_ancestors(
            of: pending
        )

        var accepted: [Pending] = []
        accepted.reserveCapacity(
            discovered.count
        )

        for sourceIndex in indices {
            let value = discovered[
                sourceIndex
            ]

            let address = pending.located.address.child(
                validIndex: accepted.count
            )

            guard let child = try accepted_pending(
                value: value,
                address: address,
                ancestors: ancestors
            ) else {
                continue
            }

            accepted.append(
                child
            )
        }

        return accepted
    }

    mutating func walk_depth_first_preorder() throws -> TreeExpansion<Value>.Located? {
        while true {
            if let entry = depth_first_preorder_stack.popLast() {
                switch entry {
                case .yield(let pending):
                    depth_first_preorder_stack.append(
                        .expand(
                            pending
                        )
                    )

                    return pending.located

                case .expand(let pending):
                    let children = try expanded_children(
                        of: pending
                    )

                    for child in children.reversed() {
                        depth_first_preorder_stack.append(
                            .yield(
                                child
                            )
                        )
                    }
                }

                continue
            }

            guard let root = try next_depth_first_root() else {
                return nil
            }

            depth_first_preorder_stack.append(
                .yield(
                    root
                )
            )
        }
    }

    mutating func walk_depth_first_postorder() throws -> TreeExpansion<Value>.Located? {
        while true {
            if let entry = depth_first_postorder_stack.popLast() {
                if entry.expanded {
                    return entry.pending.located
                }

                depth_first_postorder_stack.append(
                    .init(
                        pending: entry.pending,
                        expanded: true
                    )
                )

                let children = try expanded_children(
                    of: entry.pending
                )

                for child in children.reversed() {
                    depth_first_postorder_stack.append(
                        .init(
                            pending: child,
                            expanded: false
                        )
                    )
                }

                continue
            }

            guard let root = try next_depth_first_root() else {
                return nil
            }

            depth_first_postorder_stack.append(
                .init(
                    pending: root,
                    expanded: false
                )
            )
        }
    }

    mutating func walk_breadth_first() throws -> TreeExpansion<Value>.Located? {
        try prepare_breadth_first_roots()

        while true {
            if let pending = breadth_first_pending_expansion {
                breadth_first_pending_expansion = nil

                let children = try expanded_children(
                    of: pending
                )

                breadth_first_next_level.append(
                    contentsOf: children
                )
            }

            if breadth_first_index < breadth_first_level.count {
                let pending = breadth_first_level[
                    breadth_first_index
                ]

                breadth_first_index += 1
                breadth_first_pending_expansion = pending

                return pending.located
            }

            guard !breadth_first_next_level.isEmpty else {
                return nil
            }

            breadth_first_level = breadth_first_next_level
            breadth_first_next_level = []
            breadth_first_index = 0
        }
    }
}

public extension TreeExpansion {
    func walk(
        _ traversal: TreeTraversal = .depth_first_preorder,
        descent: TreeExpansionDescentPolicy<Value> = .unrestricted,
        child_order: TreeExpansionChildOrderPolicy<Value> = .natural,
        revisit: TreeExpansionRevisitPolicy<Value>? = nil
    ) -> TreeExpansionWalk<Value> {
        .init(
            expansion: self,
            traversal: traversal,
            descent: descent,
            child_order: child_order,
            revisit: revisit
        )
    }
}
