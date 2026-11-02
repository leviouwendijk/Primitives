/// A selected edge relation cannot be ordered as a DAG.
/// `remaining` contains nodes with unresolved incoming edges after Kahn's
/// algorithm; it can also include downstream nodes, not only cycle members.
public enum GraphTopologyError<NodeID: Hashable>: Error {
    case cycle_detected(remaining: [NodeID])
}

extension GraphTopologyError: Sendable where NodeID: Sendable {}
extension GraphTopologyError: Equatable {}

public extension Graph {
    /// Source-before-destination order for selected directed edges.
    /// Initial zero-indegree nodes follow `nodes` order. Newly ready nodes
    /// are queued in the original `edges` order. Parallel edges count separately.
    /// This is topology, not chronological or visual lane ordering.
    func topological_order(
        including include: (Edge) -> Bool = { _ in true }
    ) throws -> [NodeID] {
        var indegree = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, 0) })
        var outgoing: [NodeID: [NodeID]] = [:]

        for edge in edges where include(edge) {
            indegree[edge.destination, default: 0] += 1
            outgoing[edge.source, default: []].append(edge.destination)
        }

        var ready = nodes.compactMap { node in
            indegree[node.id] == 0 ? node.id : nil
        }
        var cursor = 0
        var ordered: [NodeID] = []
        ordered.reserveCapacity(nodes.count)

        while cursor < ready.count {
            let id = ready[cursor]
            cursor += 1
            ordered.append(id)

            for target in outgoing[id] ?? [] {
                let remaining = indegree[target, default: 0] - 1
                indegree[target] = remaining
                if remaining == 0 {
                    ready.append(target)
                }
            }
        }

        guard ordered.count == nodes.count else {
            let remaining = nodes.compactMap { node in
                (indegree[node.id] ?? 0) > 0 ? node.id : nil
            }
            throw GraphTopologyError<NodeID>.cycle_detected(remaining: remaining)
        }
        return ordered
    }

    func is_acyclic(
        including include: (Edge) -> Bool = { _ in true }
    ) -> Bool {
        (try? topological_order(including: include)) != nil
    }
}
