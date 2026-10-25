import Testing

private enum PrimitivesTestMainError: Error {
    case failed
}

@main
enum PrimitivesTestMain {
    static func main() async throws {
        let reporter = PlainTextTestReporter()
        let result = await TestRunner.run(
            PrimitivesTestSuite.suite,
            sink: reporter
        )

        print(
            await reporter.rendered()
        )

        if result.isFailure {
            throw PrimitivesTestMainError.failed
        }
    }
}

enum PrimitivesTestSuite {
    static let suite = TestSuite(
        "primitives",
        title: "Primitives tests",
        tags: [
            "primitives",
        ]
    ) {
        Test(
            "json-coding",
            tags: [
                "json",
                "coding",
            ]
        ) {
            try run_json_coding_tests()
        }

        Test(
            "json-value-native",
            tags: [
                "json",
                "native",
            ]
        ) {
            try run_json_value_native_tests()
        }

        Test(
            "tree",
            tags: [
                "tree",
            ]
        ) {
            try run_tree_tests()
        }

        Test(
            "graph",
            tags: [
                "graph",
            ]
        ) {
            try run_graph_tests()
        }

        Test(
            "json-decoding-diagnostics",
            tags: [
                "json",
                "decoding",
                "diagnostics",
            ]
        ) { test in
            try await PrimitivesTesting
                .runJSONDecodingDiagnostics(
                    test
                )
        }

        Test(
            "json-diagnostics-collection",
            tags: [
                "json",
                "diagnostics",
                "validation",
            ]
        ) { test in
            await PrimitivesTesting
                .runJSONDiagnosticsCollection(
                    test
                )
        }

        Test("invariant-nonthrowing", tags: ["invariant"]) {
            try test_invariant_nonthrowing()
        }

        Test("invariant-shared-error", tags: ["invariant"]) {
            try test_invariant_shared_error()
        }

        Test("invariant-nested-error", tags: ["invariant"]) {
            try test_invariant_nested_error()
        }

        Test("invariant-unrestricted-errors", tags: ["invariant"]) {
            try test_invariant_unrestricted_errors()
        }

        Test("invariant-composition", tags: ["invariant"]) {
            try test_invariant_composition()
        }
    }
}
