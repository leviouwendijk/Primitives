public extension Graph {
    /// Builds the normal spatial diagram, then replaces selected edge routes.
    /// Unspecified edges retain their automatically generated routes.
    /// The resulting diagram validates endpoints and segment geometry.
    func diagram(
        positions: [NodeID: GraphDiagram<NodeID, EdgeID>.Point],
        routes: [EdgeID: [GraphDiagram<NodeID, EdgeID>.Point]]
    ) throws(GraphDiagramError<NodeID, EdgeID>) -> GraphDiagram<NodeID, EdgeID> {
        typealias Diagram = GraphDiagram<NodeID, EdgeID>
        let base = try diagram(positions: positions)
        let edgeIDs = Set(base.edges.map(\.id))

        guard routes.keys.allSatisfy({ edgeIDs.contains($0) }) else {
            throw .unmatched_routes
        }

        let placedEdges: [Diagram.Edge] = base.edges.map { edge in
            .init(
                id: edge.id,
                source: edge.source,
                destination: edge.destination,
                points: routes[edge.id] ?? edge.points
            )
        }

        return try Diagram(nodes: base.nodes, edges: placedEdges)
    }
}
