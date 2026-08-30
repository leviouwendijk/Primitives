import TestFlows

@main
enum PrimitivesFlowTestMain {
    static func main() async {
        await TestFlowCLI.run(
            suite: PrimitivesFlowSuite.self
        )
    }
}

enum PrimitivesFlowSuite: TestFlowRegistry {
    static let title = "Primitives flow tests"

    static let flows: [TestFlow] = [
        TestFlow(
            "json-decoding-diagnostics",
            tags: [
                "primitives",
                "json",
                "decoding",
                "diagnostics",
            ]
        ) {
            try await PrimitivesFlowTesting.runJSONDecodingDiagnostics()
        },
        TestFlow(
            "json-diagnostics-collection",
            tags: [
                "primitives",
                "json",
                "diagnostics",
                "validation",
            ]
        ) {
            try await PrimitivesFlowTesting.runJSONDiagnosticsCollection()
        },
    ]
}
