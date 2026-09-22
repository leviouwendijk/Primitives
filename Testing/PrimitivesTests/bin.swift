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
            "tree",
            tags: [
                "tree",
            ]
        ) {
            try run_tree_tests()
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
    }
}
