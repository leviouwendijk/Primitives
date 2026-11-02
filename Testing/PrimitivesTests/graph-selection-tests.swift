import Foundation
import Primitives

func run_graph_selection_tests() throws {
    typealias G = Graph<String, String, String, String>
    let graph = try G(
        nodes: [
            .init(id: "A", value: "keep"),
            .init(id: "B", value: "drop"),
            .init(id: "C", value: "keep"),
            .init(id: "D", value: "keep"),
        ],
        edges: [
            .init(id: "ac1", source: "A", destination: "C", value: "selected"),
            .init(id: "ab", source: "A", destination: "B", value: "selected"),
            .init(id: "ac2", source: "A", destination: "C", value: "selected"),
            .init(id: "cd", source: "C", destination: "D", value: "annotation"),
            .init(id: "dc", source: "D", destination: "C", value: "selected"),
        ]
    )
    let selected = try graph.induced_subgraph(
        selecting_nodes: { $0.value == "keep" },
        including_edges: { $0.value == "selected" }
    )
    try expect(selected.nodes.map(\.id) == ["A", "C", "D"], "node order preserved")
    try expect(selected.edges.map(\.id) == ["ac1", "ac2", "dc"], "selected edge order and parallel identities")
    try expect(selected.index.incoming_edges(to: "C").map(\.id) == ["ac1", "ac2", "dc"], "reindexed adjacency")
    try expect(graph.nodes.count == 4 && graph.edges.count == 5, "source graph unchanged")
    let empty = try graph.induced_subgraph(selecting_nodes: { _ in false })
    try expect(empty.nodes.isEmpty && empty.edges.isEmpty, "empty selection")
    let restored = try JSONDecoder().decode(G.self, from: JSONEncoder().encode(selected))
    try expect(restored == selected, "selected graph remains valid through Codable")
}
