/// A path occurrence is distinct from the canonical node it references.
/// The edge path distinguishes parallel edges and repeated graph nodes.
public extension Graph {
    struct Occurrence {
        public let node_id: NodeID
        public let incoming_edge_id: EdgeID?
        public let edge_path: [EdgeID]
        public let node_path: [NodeID]
        /// A cycle remains visible as a leaf instead of disappearing or recursing.
        public let is_cycle_reference: Bool

        public init(
            node_id: NodeID,
            incoming_edge_id: EdgeID?,
            edge_path: [EdgeID],
            node_path: [NodeID],
            is_cycle_reference: Bool
        ) {
            self.node_id = node_id
            self.incoming_edge_id = incoming_edge_id
            self.edge_path = edge_path
            self.node_path = node_path
            self.is_cycle_reference = is_cycle_reference
        }
    }

    /// Unfolds selected graph roots into a call-path-like tree through the
    /// existing TreeExpansion engine. This never mutates canonical topology.
    func tree_projection(
        roots: [NodeID],
        direction: GraphDirection = .outgoing,
        limits: TreeTraversalLimits = .unlimited
    ) throws -> Tree<Occurrence> {
        let index = self.index
        for root in roots {
            guard index.node(root) != nil else {
                throw GraphValidationError<NodeID, EdgeID>.unknown_root(root)
            }
        }
        let starts = roots.map { root in
            Occurrence(
                node_id: root,
                incoming_edge_id: nil,
                edge_path: [],
                node_path: [root],
                is_cycle_reference: false
            )
        }
        let expansion = TreeExpansion<Occurrence>(roots: starts) { located in
            let parent = located.value
            guard !parent.is_cycle_reference else { return [] }
            let relations: [(NodeID, EdgeID)]
            switch direction {
            case .outgoing:
                relations = index.outgoing_edges(from: parent.node_id).map { ($0.destination, $0.id) }
            case .incoming:
                relations = index.incoming_edges(to: parent.node_id).map { ($0.source, $0.id) }
            }
            return relations.map { next_id, edge_id in
                Occurrence(
                    node_id: next_id,
                    incoming_edge_id: edge_id,
                    edge_path: parent.edge_path + [edge_id],
                    node_path: parent.node_path + [next_id],
                    is_cycle_reference: parent.node_path.contains(next_id)
                )
            }
        }
        return try expansion.materialize(
            limits: limits,
            annotations: { located in
                located.value.is_cycle_reference ? [.init("cycle_reference")] : []
            }
        )
    }
}

extension Graph.Occurrence: Sendable where NodeID: Sendable, EdgeID: Sendable {}
extension Graph.Occurrence: Equatable {}
extension Graph.Occurrence: Hashable {}
extension Graph.Occurrence: Codable where NodeID: Codable, EdgeID: Codable {}
