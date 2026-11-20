import Foundation
import Primitives

private enum TopologyExpectedError: Error {
    case missing_cycle
}

func run_graph_topology_tests() throws {
    typealias G = Graph<String, String, String, String>
    let graph = try G(
        nodes: [
            .init(id: "A", value: "root"),
            .init(id: "B", value: "branch"),
            .init(id: "C", value: "branch"),
            .init(id: "D", value: "merge"),
            .init(id: "X", value: "isolated"),
        ],
        edges: [
            .init(id: "ab1", source: "A", destination: "B", value: "ancestry"),
            .init(id: "ab2", source: "A", destination: "B", value: "ancestry"),
            .init(id: "ac", source: "A", destination: "C", value: "ancestry"),
            .init(id: "bd", source: "B", destination: "D", value: "ancestry"),
            .init(id: "cd", source: "C", destination: "D", value: "ancestry"),
            .init(id: "db", source: "D", destination: "B", value: "annotation"),
        ]
    )
    let ordered = try graph.topological_order(including: { $0.value == "ancestry" })
    try expect(ordered == ["A", "X", "B", "C", "D"], "stable source-first topological order")
    try expect(graph.is_acyclic(including: { $0.value == "ancestry" }), "selected DAG")
    try expect(!graph.is_acyclic(), "unselected annotation cycle remains visible")

    do {
        _ = try graph.topological_order()
        throw TopologyExpectedError.missing_cycle
    } catch GraphTopologyError<String>.cycle_detected(let remaining) {
        try expect(remaining == ["B", "D"], "cycle residual follows node order")
    }

    let selfLoop = try G(
        nodes: [.init(id: "loop", value: "node")],
        edges: [.init(id: "self", source: "loop", destination: "loop", value: "ancestry")]
    )
    try expect(!selfLoop.is_acyclic(), "self-loop is cyclic")
    let loopWithoutEdges = try selfLoop.topological_order(including: { _ in false })
    try expect(loopWithoutEdges.count == 1, "excluded loop leaves isolated node")
    let empty = try G(nodes: [], edges: [])
    let emptyOrder = try empty.topological_order()
    try expect(emptyOrder.isEmpty, "empty graph is a DAG")
}
