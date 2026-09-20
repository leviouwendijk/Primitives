public enum TreeMutationError: Error, Sendable, Equatable {
    case address_not_found(TreeAddress)
    case missing_child_index(TreeAddress)
    case insertion_index_out_of_bounds(
        index: Int,
        count: Int
    )
    case cannot_move_into_self(
        source: TreeAddress,
        destination: TreeAddress
    )
}

public extension Tree {
    @discardableResult
    mutating func update<Result>(
        at address: TreeAddress,
        _ body: (
            _ node: inout Node
        ) throws -> Result
    ) throws -> Result {
        var copy = self

        let result = try copy.update_unchecked(
            at: address,
            body
        )

        self = copy

        return result
    }

    mutating func replace(
        at address: TreeAddress,
        with replacement: Node
    ) throws {
        try update(
            at: address
        ) { node in
            node = replacement
        }
    }

    @discardableResult
    mutating func remove(
        at address: TreeAddress
    ) throws -> Node {
        var copy = self

        let removed = try copy.remove_unchecked(
            at: address
        )

        self = copy

        return removed
    }

    mutating func insert_root(
        _ node: Node,
        at index: Int? = nil
    ) throws {
        var copy = self

        try copy.insert_root_unchecked(
            node,
            at: index
        )

        self = copy
    }

    mutating func insert(
        _ node: Node,
        under parent: TreeAddress,
        at index: Int? = nil
    ) throws {
        var copy = self

        try copy.insert_unchecked(
            node,
            under: parent,
            at: index
        )

        self = copy
    }

    mutating func move(
        from source: TreeAddress,
        under destination: TreeAddress,
        at index: Int? = nil
    ) throws {
        guard node(
            at: source
        ) != nil else {
            throw TreeMutationError.address_not_found(
                source
            )
        }

        guard node(
            at: destination
        ) != nil else {
            throw TreeMutationError.address_not_found(
                destination
            )
        }

        guard source != destination,
              !source.is_ancestor(
                  of: destination
              )
        else {
            throw TreeMutationError.cannot_move_into_self(
                source: source,
                destination: destination
            )
        }

        var copy = self

        let moved = try copy.remove_unchecked(
            at: source
        )

        let adjustedDestination = Self.adjusted_address(
            destination,
            after_removing: source
        )

        try copy.insert_unchecked(
            moved,
            under: adjustedDestination,
            at: index
        )

        self = copy
    }

    mutating func move_to_root(
        from source: TreeAddress,
        at index: Int? = nil
    ) throws {
        guard node(
            at: source
        ) != nil else {
            throw TreeMutationError.address_not_found(
                source
            )
        }

        var copy = self

        let moved = try copy.remove_unchecked(
            at: source
        )

        try copy.insert_root_unchecked(
            moved,
            at: index
        )

        self = copy
    }
}

private extension Tree {
    mutating func update_unchecked<Result>(
        at address: TreeAddress,
        _ body: (
            _ node: inout Node
        ) throws -> Result
    ) throws -> Result {
        guard roots.indices.contains(
            address.root
        ) else {
            throw TreeMutationError.address_not_found(
                address
            )
        }

        var focused = roots[address.root]
        var breadcrumbs: [(
            node: Node,
            child_index: Int
        )] = []

        breadcrumbs.reserveCapacity(
            address.descendants.count
        )

        for childIndex in address.descendants {
            guard focused.children.indices.contains(
                childIndex
            ) else {
                throw TreeMutationError.address_not_found(
                    address
                )
            }

            breadcrumbs.append(
                (
                    node: focused,
                    child_index: childIndex
                )
            )

            focused = focused.children[childIndex]
        }

        let result = try body(
            &focused
        )

        while let breadcrumb = breadcrumbs.popLast() {
            var parent = breadcrumb.node

            parent.children[
                breadcrumb.child_index
            ] = focused

            focused = parent
        }

        roots[address.root] = focused

        return result
    }

    mutating func remove_unchecked(
        at address: TreeAddress
    ) throws -> Node {
        guard roots.indices.contains(
            address.root
        ) else {
            throw TreeMutationError.address_not_found(
                address
            )
        }

        guard let parent = address.parent else {
            return roots.remove(
                at: address.root
            )
        }

        guard let childIndex = address.descendants.last else {
            throw TreeMutationError.missing_child_index(
                address
            )
        }

        return try update_unchecked(
            at: parent
        ) { node in
            guard node.children.indices.contains(
                childIndex
            ) else {
                throw TreeMutationError.address_not_found(
                    address
                )
            }

            return node.children.remove(
                at: childIndex
            )
        }
    }

    mutating func insert_root_unchecked(
        _ node: Node,
        at index: Int?
    ) throws {
        let insertionIndex = index
            ?? roots.endIndex

        guard insertionIndex >= roots.startIndex,
              insertionIndex <= roots.endIndex
        else {
            throw TreeMutationError.insertion_index_out_of_bounds(
                index: insertionIndex,
                count: roots.count
            )
        }

        roots.insert(
            node,
            at: insertionIndex
        )
    }

    mutating func insert_unchecked(
        _ child: Node,
        under parent: TreeAddress,
        at index: Int?
    ) throws {
        try update_unchecked(
            at: parent
        ) { node in
            let insertionIndex = index
                ?? node.children.endIndex

            guard insertionIndex >= node.children.startIndex,
                  insertionIndex <= node.children.endIndex
            else {
                throw TreeMutationError.insertion_index_out_of_bounds(
                    index: insertionIndex,
                    count: node.children.count
                )
            }

            node.children.insert(
                child,
                at: insertionIndex
            )
        }
    }

    static func adjusted_address(
        _ address: TreeAddress,
        after_removing removed: TreeAddress
    ) -> TreeAddress {
        if removed.descendants.isEmpty {
            guard address.root > removed.root else {
                return address
            }

            return .init(
                validRoot: address.root - 1,
                descendants: address.descendants
            )
        }

        guard address.root == removed.root else {
            return address
        }

        let removedLevel =
            removed.descendants.count - 1

        guard address.descendants.count > removedLevel else {
            return address
        }

        guard address.descendants
                .prefix(removedLevel)
                .elementsEqual(
                    removed.descendants.prefix(
                        removedLevel
                    )
                )
        else {
            return address
        }

        guard address.descendants[removedLevel]
                > removed.descendants[removedLevel]
        else {
            return address
        }

        var descendants = address.descendants
        descendants[removedLevel] -= 1

        return .init(
            validRoot: address.root,
            descendants: descendants
        )
    }
}
