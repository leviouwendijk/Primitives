/// A snapshot of identified, movable references to typed target identities.
/// Ref movements between snapshots and their chronology belong to the owner.
public struct ReferenceSet<ReferenceID: Hashable, TargetID: Hashable> {
    public struct Reference {
        public let id: ReferenceID
        public let target: TargetID

        public init(id: ReferenceID, target: TargetID) {
            self.id = id
            self.target = target
        }
    }

    public let references: [Reference]

    public init(references: [Reference]) throws(ReferenceSetError<ReferenceID, TargetID>) {
        var known: Set<ReferenceID> = []
        for reference in references {
            guard known.insert(reference.id).inserted else {
                throw .duplicate_reference(reference.id)
            }
        }
        self.references = references
    }

    public func target(for id: ReferenceID) -> TargetID? {
        references.first(where: { $0.id == id })?.target
    }

    public func references(to target: TargetID) -> [Reference] {
        references.filter { $0.target == target }
    }

    /// Optional graph-bound integrity check. Unresolved references are legal
    /// as snapshots, e.g. when the selected graph contains only a subset.
    public func validate_targets<NodeValue, EdgeID: Hashable, EdgeValue>(
        in graph: Graph<TargetID, NodeValue, EdgeID, EdgeValue>
    ) throws(ReferenceSetError<ReferenceID, TargetID>) {
        let ids = Set(graph.nodes.map(\.id))
        for reference in references where !ids.contains(reference.target) {
            throw .unknown_target(reference: reference.id, target: reference.target)
        }
    }
}

public enum ReferenceSetError<ReferenceID: Hashable, TargetID: Hashable>: Error {
    case duplicate_reference(ReferenceID)
    case unknown_target(reference: ReferenceID, target: TargetID)
}

extension ReferenceSetError: Sendable where ReferenceID: Sendable, TargetID: Sendable {}
extension ReferenceSetError: Equatable {}

extension ReferenceSet.Reference: Sendable where ReferenceID: Sendable, TargetID: Sendable {}
extension ReferenceSet: Sendable where ReferenceID: Sendable, TargetID: Sendable {}
extension ReferenceSet.Reference: Equatable {}
extension ReferenceSet: Equatable {}
extension ReferenceSet.Reference: Hashable {}
extension ReferenceSet: Hashable {}
extension ReferenceSet.Reference: Codable where ReferenceID: Codable, TargetID: Codable {}
extension ReferenceSet: Codable where ReferenceID: Codable, TargetID: Codable {
    private enum CodingKeys: String, CodingKey {
        case references
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(references: container.decode([Reference].self, forKey: .references))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(references, forKey: .references)
    }
}
