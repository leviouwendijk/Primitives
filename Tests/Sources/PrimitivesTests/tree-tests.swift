import Testing
import Foundation
import Primitives

enum TreeTestError: Error {
    case failed(String)
    case expansion_failed(TreeAddress)
}

func expect(
    _ condition: @autoclosure () throws -> Bool,
    _ message: String,
    fileID: String = #fileID,
    filePath: String = #filePath,
    line: UInt = #line,
    column: UInt = #column
) throws {
    guard try condition() else {
        throw TestRequirementFailure(
            issue: TestIssue(
                kind: .requirement,
                message: message,
                sourceLocation: .init(
                    fileID: fileID,
                    filePath: filePath,
                    line: line,
                    column: column
                ),
                actual: "false",
                expected: "true"
            )
        )
    }
}

func address(
    _ root: Int,
    _ descendants: Int...
) throws -> TreeAddress {
    try .init(
        root: root,
        descendants: descendants
    )
}

func values(
    _ tree: Tree<String>,
    traversal: TreeTraversal = .depth_first_preorder,
    limits: TreeTraversalLimits = .unlimited,
    descent: TreeDescentPolicy<String> = .unrestricted,
    root_order: TreeRootOrderPolicy<String> = .natural,
    child_order: TreeChildOrderPolicy<String> = .natural
) -> [String] {
    tree.located(
        traversal: traversal,
        limits: limits,
        descent: descent,
        root_order: root_order,
        child_order: child_order
    )
    .map { located in
        located.node.value
    }
}

func expansion_values(
    _ walk: TreeExpansionWalk<String>
) throws -> [String] {
    var iterator = walk.makeIterator()
    var result: [String] = []

    while let located = try iterator.next() {
        result.append(
            located.value
        )
    }

    return result
}

func run_tree_tests() throws {
    let includeB = true

    let tree = Tree<String> {
        Tree<String>.Node(
            "root"
        ) {
            Tree<String>.Node(
                "a",
                annotations: [
                    TreeAnnotation(
                        "branch annotation"
                    ),
                ]
            ) {
                Tree<String>.Node(
                    "a1"
                )
            }

            if includeB {
                Tree<String>.Node(
                    "b"
                )
            }
        }

        Tree<String>.Node(
            "other"
        )
    }

    let root = try address(
        0
    )

    let a = try address(
        0,
        0
    )

    let a1 = try address(
        0,
        0,
        0
    )

    let b = try address(
        0,
        1
    )

    let other_root = try address(
        1
    )

    try expect(
        root.depth == 0,
        "root depth"
    )

    try expect(
        a1.depth == 2,
        "descendant depth"
    )

    try expect(
        a1.parent == a,
        "parent address"
    )

    try expect(
        tree.node(
            at: a1
        )?.value == "a1",
        "address lookup"
    )

    try expect(
        tree.node(
            at: try address(
                9
            )
        ) == nil,
        "missing address lookup"
    )

    try expect(
        values(tree) == [
            "root",
            "a",
            "a1",
            "b",
            "other",
        ],
        "depth-first preorder"
    )

    try expect(
        values(
            tree,
            traversal: .depth_first_postorder
        ) == [
            "a1",
            "a",
            "b",
            "root",
            "other",
        ],
        "depth-first postorder"
    )

    try expect(
        values(
            tree,
            traversal: .breadth_first
        ) == [
            "root",
            "other",
            "a",
            "b",
            "a1",
        ],
        "breadth-first traversal"
    )

    try expect(
        values(
            tree,
            limits: try .init(
                maximum_depth: 1
            )
        ) == [
            "root",
            "a",
            "b",
            "other",
        ],
        "maximum-depth traversal limit"
    )

    do {
        _ = try TreeTraversalLimits(
            maximum_depth: -1
        )

        throw TreeTestError.failed(
            "negative traversal depth unexpectedly succeeded"
        )
    } catch let error as TreeTraversalLimitError {
        try expect(
            error == .negative_maximum_depth(-1),
            "negative traversal depth has typed error"
        )
    }

    try expect(
        values(
            tree,
            child_order: .reversed
        ) == [
            "root",
            "b",
            "a",
            "a1",
            "other",
        ],
        "reversed child order"
    )

    try expect(
        values(
            tree,
            root_order: .reversed
        ) == [
            "other",
            "root",
            "a",
            "a1",
            "b",
        ],
        "reversed forest root order"
    )

    try expect(
        values(
            tree,
            traversal: .depth_first_postorder,
            root_order: .reversed
        ) == [
            "other",
            "a1",
            "a",
            "b",
            "root",
        ],
        "postorder respects forest root order"
    )

    try expect(
        values(
            tree,
            traversal: .breadth_first,
            root_order: .reversed
        ) == [
            "other",
            "root",
            "a",
            "b",
            "a1",
        ],
        "breadth-first respects forest root order"
    )

    let root_ordered = tree.located(
        root_order: .reversed
    )

    try expect(
        root_ordered.first?.address == other_root,
        "forest ordering preserves original structural root address"
    )

    try expect(
        root_ordered.first {
            $0.node.value == "root"
        }?.address == root,
        "forest ordering does not renumber structural roots"
    )

    var events: [String] = []

    for event in tree.events() {
        switch event {
        case .enter(let located):
            events.append(
                "+\(located.node.value)"
            )

        case .exit(let located):
            events.append(
                "-\(located.node.value)"
            )
        }
    }

    try expect(
        events == [
            "+root",
            "+a",
            "+a1",
            "-a1",
            "-a",
            "+b",
            "-b",
            "-root",
            "+other",
            "-other",
        ],
        "balanced enter/exit events"
    )

    let counts = tree.fold { _, children in
        1 + children.reduce(
            0,
            +
        )
    }

    try expect(
        counts == [
            4,
            1,
        ],
        "bottom-up fold"
    )

    let mapped = tree.map_values { located in
        located.node.value.uppercased()
    }

    try expect(
        values(mapped) == [
            "ROOT",
            "A",
            "A1",
            "B",
            "OTHER",
        ],
        "value mapping"
    )

    try expect(
        mapped.node(
            at: a
        )?.annotations == [
            TreeAnnotation(
                "branch annotation"
            ),
        ],
        "mapping preserves annotations"
    )

    let removed = tree.rewrite { located, _ in
        located.node.value == "a"
            ? .remove
            : .keep
    }

    try expect(
        values(removed) == [
            "root",
            "b",
            "other",
        ],
        "rewrite removal removes subtree"
    )

    let promoted = tree.rewrite { located, children in
        located.node.value == "a"
            ? .replace_many(
                children
            )
            : .keep
    }

    try expect(
        values(promoted) == [
            "root",
            "a1",
            "b",
            "other",
        ],
        "rewrite can promote rewritten children"
    )

    var updated = tree

    try updated.update(
        at: b
    ) { node in
        node.value = "b2"
    }

    try expect(
        updated.node(
            at: b
        )?.value == "b2",
        "addressed update"
    )

    let beforeInvalidInsert = updated

    do {
        try updated.insert(
            .init(
                "invalid"
            ),
            under: root,
            at: 99
        )

        throw TreeTestError.failed(
            "invalid insertion unexpectedly succeeded"
        )
    } catch TreeMutationError.insertion_index_out_of_bounds {
    }

    try expect(
        updated == beforeInvalidInsert,
        "failed mutation is transactional"
    )

    let beforeInvalidMove = updated

    do {
        try updated.move(
            from: a,
            under: a1
        )

        throw TreeTestError.failed(
            "self-descendant move unexpectedly succeeded"
        )
    } catch TreeMutationError.cannot_move_into_self {
    }

    try expect(
        updated == beforeInvalidMove,
        "failed move is transactional"
    )

    var moving = Tree<String> {
        Tree<String>.Node(
            "root"
        ) {
            Tree<String>.Node(
                "a"
            )

            Tree<String>.Node(
                "b"
            )

            Tree<String>.Node(
                "c"
            )
        }
    }

    try moving.move(
        from: address(
            0,
            0
        ),
        under: address(
            0,
            2
        )
    )

    try expect(
        values(moving) == [
            "root",
            "b",
            "c",
            "a",
        ],
        "move adjusts destination after source removal"
    )

    let adjacency: [String: [String]] = [
        "root": [
            "a",
            "b",
        ],
        "a": [
            "a1",
        ],
        "b": [],
        "a1": [],
    ]

    var expansionCalls: [
        TreeExpansion<String>.Located
    ] = []

    let expansion = TreeExpansion<String>(
        roots: [
            "root",
        ]
    ) { located in
        expansionCalls.append(
            located
        )

        return adjacency[located.value]
            ?? []
    }

    var lazyIterator = expansion
        .walk()
        .makeIterator()

    try expect(
        try lazyIterator.next()?.value == "root",
        "expansion yields root first"
    )

    try expect(
        expansionCalls.isEmpty,
        "preorder expansion does not discover root children before root is yielded"
    )

    try expect(
        try lazyIterator.next()?.value == "a",
        "expansion yields first child"
    )

    try expect(
        expansionCalls.map(\.value) == [
            "root",
        ],
        "expansion discovers children lazily"
    )

    try expect(
        expansionCalls.first?.address == root,
        "expansion child provider receives root address"
    )

    try expect(
        try expansion_values(
            expansion.walk(
                .depth_first_preorder
            )
        ) == [
            "root",
            "a",
            "a1",
            "b",
        ],
        "expansion preorder"
    )

    try expect(
        try expansion_values(
            expansion.walk(
                .depth_first_postorder
            )
        ) == [
            "a1",
            "a",
            "b",
            "root",
        ],
        "expansion postorder"
    )

    try expect(
        try expansion_values(
            expansion.walk(
                .breadth_first
            )
        ) == [
            "root",
            "a",
            "b",
            "a1",
        ],
        "expansion breadth first"
    )

    let globallyShared = TreeExpansion<String>(
        roots: [
            "root",
        ]
    ) { located in
        switch located.value {
        case "root":
            [
                "a",
                "b",
            ]

        case "a",
             "b":
            [
                "shared",
            ]

        default:
            []
        }
    }

    try expect(
        try expansion_values(
            globallyShared.walk(
                revisit: .global(
                    identity: { $0 }
                )
            )
        ) == [
            "root",
            "a",
            "shared",
            "b",
        ],
        "global revisit skips previously accepted identity"
    )

    var limitedProviderCalls: [String] = []

    let limitedExpansion = TreeExpansion<String>(
        roots: [
            "root",
        ]
    ) { located in
        limitedProviderCalls.append(
            located.value
        )

        switch located.value {
        case "root":
            return [
                "child",
            ]

        case "child":
            return [
                "grandchild",
            ]

        default:
            return []
        }
    }

    try expect(
        try expansion_values(
            limitedExpansion.walk(
                limits: .init(
                    maximum_depth: 1
                )
            )
        ) == [
            "root",
            "child",
        ],
        "expansion maximum depth limits accepted topology"
    )

    try expect(
        limitedProviderCalls == [
            "root",
        ],
        "expansion maximum depth avoids child discovery beyond limit"
    )

    let depthFirstEncounter = TreeExpansion<String>(
        roots: [
            "root",
        ]
    ) { located in
        switch located.value {
        case "root":
            [
                "a",
                "shared",
                "tail",
            ]

        case "a":
            [
                "shared",
            ]

        default:
            []
        }
    }

    var preorderIterator = depthFirstEncounter.walk(
        revisit: .global(
            identity: { $0 }
        )
    )
    .makeIterator()

    var preorderLocated: [TreeExpansion<String>.Located] = []

    while let located = try preorderIterator.next() {
        preorderLocated.append(
            located
        )
    }

    try expect(
        preorderLocated.map(\.value) == [
            "root",
            "a",
            "shared",
            "tail",
        ],
        "DFS global revisit follows actual preorder encounter"
    )

    try expect(
        preorderLocated.map(\.address) == [
            try address(0),
            try address(0, 0),
            try address(0, 0, 0),
            try address(0, 1),
        ],
        "DFS global revisit assigns dense addresses at accepted encounter points"
    )

    var postorderIterator = depthFirstEncounter.walk(
        .depth_first_postorder,
        revisit: .global(
            identity: { $0 }
        )
    )
    .makeIterator()

    var postorderLocated: [TreeExpansion<String>.Located] = []

    while let located = try postorderIterator.next() {
        postorderLocated.append(
            located
        )
    }

    try expect(
        postorderLocated.map(\.value) == [
            "shared",
            "a",
            "tail",
            "root",
        ],
        "DFS global revisit follows depth-first discovery under postorder yielding"
    )

    try expect(
        postorderLocated.map(\.address) == [
            try address(0, 0, 0),
            try address(0, 0),
            try address(0, 1),
            try address(0),
        ],
        "postorder retains dense depth-first accepted topology addresses"
    )

    let encounterMaterialized = try depthFirstEncounter.materialize(
        revisit: .global(
            identity: { $0 }
        )
    )

    try expect(
        encounterMaterialized.node(
            at: try address(0, 0, 0)
        )?.value == "shared",
        "materialization keeps first DFS shared identity under its encountered parent"
    )

    try expect(
        encounterMaterialized.node(
            at: try address(0, 1)
        )?.value == "tail",
        "materialization compacts skipped sibling addresses"
    )

    try expect(
        encounterMaterialized.node(
            at: try address(0, 2)
        ) == nil,
        "materialization has no address gap after skipped global revisit"
    )

    let cyclic = TreeExpansion<String>(
        roots: [
            "a",
        ]
    ) { located in
        located.value == "a"
            ? [
                "b",
            ]
            : [
                "a",
            ]
    }

    do {
        _ = try expansion_values(
            cyclic.walk(
                revisit: .ancestors(
                    identity: { $0 }
                )
            )
        )

        throw TreeTestError.failed(
            "ancestor cycle unexpectedly succeeded"
        )
    } catch let error as TreeExpansionRevisitError {
        try expect(
            error.scope == .ancestors,
            "ancestor cycle error scope"
        )
    }

    let diagnosticExpansion = TreeExpansion<String>(
        roots: [
            "root",
        ]
    ) { located in
        switch located.value {
        case "root":
            return [
                "a",
            ]

        case "a":
            throw TreeTestError.expansion_failed(
                located.address
            )

        default:
            return []
        }
    }

    do {
        _ = try expansion_values(
            diagnosticExpansion.walk()
        )

        throw TreeTestError.failed(
            "contextual expansion failure unexpectedly succeeded"
        )
    } catch TreeTestError.expansion_failed(
        let failureAddress
    ) {
        try expect(
            failureAddress == a,
            "expansion error can retain discovery TreeAddress"
        )
    }

    let invalidOrder = TreeExpansionChildOrderPolicy<String> {
        _, children in
        guard !children.isEmpty else {
            return []
        }

        return Array(
            repeating: 0,
            count: children.count
        )
    }

    do {
        _ = try expansion_values(
            expansion.walk(
                child_order: invalidOrder
            )
        )

        throw TreeTestError.failed(
            "invalid expansion child order unexpectedly succeeded"
        )
    } catch TreeExpansionError.duplicate_child_order_index {
    }

    let materialized = try expansion.materialize { located in
        located.value == "a"
            ? [
                TreeAnnotation(
                    "materialized annotation"
                ),
            ]
            : []
    }

    try expect(
        values(materialized) == [
            "root",
            "a",
            "a1",
            "b",
        ],
        "expansion materialization"
    )

    try expect(
        materialized.node(
            at: try address(
                0,
                0
            )
        )?.annotations == [
            TreeAnnotation(
                "materialized annotation"
            ),
        ],
        "materialization annotations"
    )

    let firstLetterIndex = try tree.index { located in
        String(
            located.node.value.prefix(1)
        )
    }

    try expect(
        firstLetterIndex.addresses(
            for: "a"
        ) == [
            a,
            a1,
        ],
        "tree index collects duplicate semantic keys in traversal order"
    )

    try expect(
        firstLetterIndex.first_address(
            for: "b"
        ) == b,
        "tree index first address"
    )

    try expect(
        firstLetterIndex.contains(
            "r"
        ),
        "tree index contains key"
    )

    try expect(
        !firstLetterIndex.contains(
            "z"
        ),
        "tree index missing key"
    )

    do {
        _ = try tree.index(
            duplicate_policy: .reject
        ) { located in
            String(
                located.node.value.prefix(1)
            )
        }

        throw TreeTestError.failed(
            "duplicate-rejecting tree index unexpectedly succeeded"
        )
    } catch TreeIndexError.duplicate_key(
        let first,
        let duplicate
    ) {
        try expect(
            first == a,
            "tree index duplicate reports first address"
        )

        try expect(
            duplicate == a1,
            "tree index duplicate reports duplicate address"
        )
    }

    let aCursor = try tree.cursor(
        at: a
    )

    try expect(
        aCursor.address == a,
        "tree cursor address"
    )

    try expect(
        aCursor.node.value == "a",
        "tree cursor focused node"
    )

    try expect(
        aCursor.parent?.address == root,
        "tree cursor parent"
    )

    try expect(
        aCursor.first_child?.address == a1,
        "tree cursor first child"
    )

    try expect(
        aCursor.last_child?.address == a1,
        "tree cursor last child"
    )

    try expect(
        aCursor.children.map(\.address) == [
            a1,
        ],
        "tree cursor children"
    )

    try expect(
        try aCursor.child(
            at: 0
        ).address == a1,
        "tree cursor addressed child"
    )

    try expect(
        aCursor.next_sibling?.address == b,
        "tree cursor next sibling"
    )

    try expect(
        aCursor.next_sibling?.previous_sibling?.address == a,
        "tree cursor previous sibling"
    )

    let otherCursor = try tree.cursor(
        at: address(
            1
        )
    )

    try expect(
        otherCursor.previous_sibling?.address == root,
        "tree cursor root sibling navigation"
    )

    try expect(
        otherCursor.next_sibling == nil,
        "tree cursor root sibling boundary"
    )

    do {
        _ = try aCursor.child(
            at: 99
        )

        throw TreeTestError.failed(
            "invalid cursor child unexpectedly succeeded"
        )
    } catch TreeCursorError.child_index_out_of_bounds(
        let parent,
        let index,
        let count
    ) {
        try expect(
            parent == a,
            "cursor child error parent"
        )

        try expect(
            index == 99,
            "cursor child error index"
        )

        try expect(
            count == 1,
            "cursor child error count"
        )
    }

    do {
        _ = try tree.cursor(
            at: address(
                99
            )
        )

        throw TreeTestError.failed(
            "invalid cursor address unexpectedly succeeded"
        )
    } catch TreeCursorError.address_not_found(
        let missing
    ) {
        let expectedMissing = try address(
            99
        )

        try expect(
            missing == expectedMissing,
            "cursor missing address error"
        )
    }

    var cursorSource = tree

    let snapshotCursor = try cursorSource.cursor(
        at: a
    )

    try cursorSource.update(
        at: a
    ) { node in
        node.value = "changed"
    }

    try expect(
        snapshotCursor.node.value == "a",
        "tree cursor retains snapshot semantics"
    )

    try expect(
        cursorSource.node(
            at: a
        )?.value == "changed",
        "cursor snapshot does not prevent later tree mutation"
    )

    try expect(
        root.is_ancestor(
            of: a1
        ),
        "tree address ancestor relation"
    )

    try expect(
        a1.is_descendant(
            of: root
        ),
        "tree address descendant relation"
    )

    try expect(
        !root.is_ancestor(
            of: root
        ),
        "tree address ancestor relation is strict"
    )

    try expect(
        tree.addresses.sorted() == tree.addresses,
        "tree address comparison follows natural preorder"
    )

    let encodedTree = try JSONEncoder().encode(
        tree
    )

    let decodedTree = try JSONDecoder().decode(
        Tree<String>.self,
        from: encodedTree
    )

    try expect(
        decodedTree == tree,
        "tree Codable round trip"
    )

    let encodedLocated = try JSONEncoder().encode(
        tree.located()
    )

    let decodedLocated = try JSONDecoder().decode(
        [Tree<String>.LocatedNode].self,
        from: encodedLocated
    )

    try expect(
        decodedLocated == tree.located(),
        "located tree nodes Codable round trip"
    )

    var movedToRoot = tree

    try movedToRoot.move_to_root(
        from: a,
        at: 1
    )

    try expect(
        values(movedToRoot) == [
            "root",
            "b",
            "a",
            "a1",
            "other",
        ],
        "move subtree to root level"
    )

    var reorderedRoots = Tree<String> {
        Tree<String>.Node(
            "first"
        )

        Tree<String>.Node(
            "second"
        )

        Tree<String>.Node(
            "third"
        )
    }

    try reorderedRoots.move_to_root(
        from: address(
            0
        )
    )

    try expect(
        values(reorderedRoots) == [
            "second",
            "third",
            "first",
        ],
        "move root to root level reorders roots"
    )

    var deepNode = Tree<String>.Node(
        "leaf"
    )

    let deepDepth = 1024

    for index in 0..<deepDepth {
        deepNode = .init(
            "level-\(index)",
            children: [
                deepNode,
            ]
        )
    }

    var deepTree = Tree<String>(
        roots: [
            deepNode,
        ]
    )

    let deepAddress = try TreeAddress(
        root: 0,
        descendants: Array(
            repeating: 0,
            count: deepDepth
        )
    )

    try deepTree.update(
        at: deepAddress
    ) { node in
        node.value = "updated-leaf"
    }

    try expect(
        deepTree.node(
            at: deepAddress
        )?.value == "updated-leaf",
        "deep addressed mutation is iterative"
    )

    let invalidCountOrder = TreeExpansionChildOrderPolicy<String> {
        _, children in
        guard !children.isEmpty else {
            return []
        }

        return []
    }

    do {
        _ = try expansion_values(
            expansion.walk(
                child_order: invalidCountOrder
            )
        )

        throw TreeTestError.failed(
            "child-order count mismatch unexpectedly succeeded"
        )
    } catch TreeExpansionError.child_order_count_mismatch {
    }

    let invalidIndexOrder = TreeExpansionChildOrderPolicy<String> {
        _, children in
        guard children.count == 2 else {
            return Array(
                children.indices
            )
        }

        return [
            0,
            99,
        ]
    }

    do {
        _ = try expansion_values(
            expansion.walk(
                child_order: invalidIndexOrder
            )
        )

        throw TreeTestError.failed(
            "child-order invalid index unexpectedly succeeded"
        )
    } catch TreeExpansionError.child_order_index_out_of_bounds {
    }

    let invalidRootAddressData = Data(
        #"{"root":-1,"descendants":[]}"#.utf8
    )

    do {
        _ = try JSONDecoder().decode(
            TreeAddress.self,
            from: invalidRootAddressData
        )

        throw TreeTestError.failed(
            "TreeAddress decoding bypassed root invariant"
        )
    } catch TreeAddress.Error.negative_root(
        let value
    ) {
        try expect(
            value == -1,
            "TreeAddress decoding preserves root validation error"
        )
    }

    let invalidDescendantAddressData = Data(
        #"{"root":0,"descendants":[0,-1]}"#.utf8
    )

    do {
        _ = try JSONDecoder().decode(
            TreeAddress.self,
            from: invalidDescendantAddressData
        )

        throw TreeTestError.failed(
            "TreeAddress decoding bypassed descendant invariant"
        )
    } catch TreeAddress.Error.negative_descendant(
        let position,
        let value
    ) {
        try expect(
            position == 1,
            "TreeAddress decoding preserves descendant error position"
        )

        try expect(
            value == -1,
            "TreeAddress decoding preserves invalid descendant value"
        )
    }
}

