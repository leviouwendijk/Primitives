public extension Graph {
    /// Reachable node identities, visited once, starting with the root.
    /// This is a graph traversal, not a path-occurrence traversal.
    func walk(
        starting_at root: NodeID,
        direction: GraphDirection = .outgoing,
        traversal: GraphTraversal = .breadth_first
    ) throws -> [NodeID] {
        let index = self.index
        guard index.node(root) != nil else {
            throw GraphValidationError<NodeID, EdgeID>.unknown_root(root)
        }
        var visited: Set<NodeID> = []
        var order: [NodeID] = []
        var pending: [NodeID] = [root]
        var cursor = 0
        while traversal == .depth_first ? !pending.isEmpty : cursor < pending.count {
            let id: NodeID
            switch traversal {
            case .depth_first:
                id = pending.removeLast()
            case .breadth_first:
                id = pending[cursor]
                cursor += 1
            }
            guard visited.insert(id).inserted else { continue }
            order.append(id)
            let neighbours: [NodeID]
            switch direction {
            case .outgoing:
                neighbours = index.outgoing_edges(from: id).map(\.destination)
            case .incoming:
                neighbours = index.incoming_edges(to: id).map(\.source)
            }
            if traversal == .depth_first {
                pending.append(contentsOf: neighbours.reversed())
            } else {
                pending.append(contentsOf: neighbours)
            }
        }
        return order
    }
}
