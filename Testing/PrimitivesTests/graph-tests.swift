import Foundation
import Primitives

private enum GraphTestFailure: Error {
    case missing_error
}

func run_graph_tests() throws {
    typealias G = Graph<String, String, String, String>
    let graph = try G(
        nodes: [
            .init(id: "A", value: "entry"),
            .init(id: "B", value: "branch-b"),
            .init(id: "C", value: "branch-c"),
            .init(id: "D", value: "shared"),
        ],
        edges: [
            .init(id: "ab", source: "A", destination: "B", value: "callsite-1"),
            .init(id: "ac", source: "A", destination: "C", value: "callsite-2"),
            .init(id: "bd-1", source: "B", destination: "D", value: "callsite-3"),
            .init(id: "bd-2", source: "B", destination: "D", value: "callsite-4"),
            .init(id: "cd", source: "C", destination: "D", value: "callsite-5"),
            .init(id: "db", source: "D", destination: "B", value: "recursive"),
        ]
    )
    let index = graph.index
    try expect(index.node("D")?.value == "shared", "graph index retains node values")
    try expect(index.outgoing_edges(from: "B").map(\.id) == ["bd-1", "bd-2"], "parallel edges preserve order")
    try expect(index.incoming_edges(to: "D").map(\.id) == ["bd-1", "bd-2", "cd"], "incoming adjacency")
    try expect(try graph.walk(starting_at: "A") == ["A", "B", "C", "D"], "breadth-first graph traversal")
    try expect(try graph.walk(starting_at: "A", traversal: .depth_first) == ["A", "B", "D", "C"], "depth-first traversal")

    let paths = try graph.tree_projection(roots: ["A"])
    let located = paths.walk().map(\.node.value)
    try expect(located.filter { $0.node_id == "D" && !$0.is_cycle_reference }.count == 3, "distinct graph paths remain distinct tree occurrences")
    try expect(located.filter(\.is_cycle_reference).count == 4, "cycle boundaries remain visible as leaves")
    let d_paths = located.filter { $0.node_id == "D" && !$0.is_cycle_reference }.map(\.edge_path)
    try expect(Set(d_paths).count == 3, "distinct callsites have distinct occurrence IDs")
    let bounded = try graph.tree_projection(roots: ["A"], limits: .init(maximum_depth: 1))
    try expect(Array(bounded.walk()).count == 3, "existing TreeExpansion depth limit is honored")

    let encoded = try JSONEncoder().encode(graph)
    let decoded = try JSONDecoder().decode(G.self, from: encoded)
    try expect(decoded == graph, "graph round trips through validated Codable")
    do {
        _ = try G(nodes: [.init(id: "A", value: "x"), .init(id: "A", value: "y")], edges: [])
        throw GraphTestFailure.missing_error
    } catch GraphValidationError<String, String>.duplicate_node("A") {}
    do {
        _ = try G(nodes: [.init(id: "A", value: "x")], edges: [.init(id: "dangling", source: "A", destination: "Z", value: "call")])
        throw GraphTestFailure.missing_error
    } catch GraphValidationError<String, String>.unknown_destination("dangling", "Z") {}
    let malformed = Data(#"{"nodes":[{"id":"A","value":"x"}],"edges":[{"id":"e","source":"A","destination":"MISSING","value":"call"}]}"#.utf8)
    do {
        _ = try JSONDecoder().decode(G.self, from: malformed)
        throw GraphTestFailure.missing_error
    } catch GraphValidationError<String, String>.unknown_destination("e", "MISSING") {}
}
