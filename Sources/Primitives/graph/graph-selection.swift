public extension Graph {
    /// Returns an induced subgraph with stable node/edge identities and order.
    /// An edge survives only if selected AND both endpoints survive.
    /// The input graph is not mutated; the resulting graph is revalidated.
    func induced_subgraph(
        selecting_nodes select: (Node) -> Bool,
        including_edges include: (Edge) -> Bool = { _ in true }
    ) throws -> Graph {
        let selected = nodes.filter(select)
        let ids = Set(selected.map(\.id))
        let relations = edges.filter { edge in
            ids.contains(edge.source)
                && ids.contains(edge.destination)
                && include(edge)
        }
        return try Graph(nodes: selected, edges: relations)
    }
}
