public extension GraphLayout {
    /// A named reference projected onto the layout. `position == nil` means
    /// its target is outside the visible graph, not that the reference is invalid.
    struct ReferencePlacement<ReferenceID: Hashable> {
        public let id: ReferenceID
        public let target: NodeID
        public let position: Point?

        public init(id: ReferenceID, target: NodeID, position: Point?) {
            self.id = id
            self.target = target
            self.position = position
        }
    }

    /// Preserves reference identities and ordering, including off-layout targets.
    func place_references<ReferenceID: Hashable>(
        _ references: ReferenceSet<ReferenceID, NodeID>
    ) -> [ReferencePlacement<ReferenceID>] {
        let positions = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0.position) })
        return references.references.map { reference in
            ReferencePlacement(
                id: reference.id,
                target: reference.target,
                position: positions[reference.target]
            )
        }
    }
}

extension GraphLayout.ReferencePlacement: Sendable where NodeID: Sendable, ReferenceID: Sendable {}
extension GraphLayout.ReferencePlacement: Equatable {}
extension GraphLayout.ReferencePlacement: Hashable {}
extension GraphLayout.ReferencePlacement: Codable where NodeID: Codable, ReferenceID: Codable {}
