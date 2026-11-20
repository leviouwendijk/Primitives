import Foundation
import Primitives
import Testing

private struct CasingFixture: Decodable {
    let someValue: Int
}

private struct EnvelopeFixture: Decodable {
    let root: RootFixture
}

private struct RootFixture: Decodable {
    let children: [ChildFixture]
}

private struct ChildFixture: Decodable {
    let name: String
}

private enum JSONDecodingTestError: Error {
    case expectedFailure
}

enum PrimitivesTesting {
    static func runJSONDecodingDiagnostics(
        _ test: TestContext
    ) async throws {
        let path = JSONCodingPath(
            [
                .key("root"),
                .key("needs-escaping"),
                .index(2),
            ]
        )

        await test.expect(
            path.jsonPath,
            equals: "$.root[\"needs-escaping\"][2]",
            "JSON coding path renders keys and indices"
        )

        let casing = try JSONCoding
            .casing(
                decode: .init(
                    to: .camel
                )
            )
            .decode(
                CasingFixture.self,
                from: Data(
                    #"{"some_value":7}"#.utf8
                )
            )

        await test.expect(
            casing.someValue,
            equals: 7,
            "JSONCoding.decode uses its configured decoder"
        )

        let missing = try decodingError(
            EnvelopeFixture.self,
            json: #"{"root":{"children":[{}]}}"#
        )

        await test.expect(
            missing.kind,
            equals: .keyNotFound,
            "missing key classification"
        )

        await test.expect(
            missing.path.jsonPath,
            equals: "$.root.children[0].name",
            "missing key includes the missing key in its path"
        )

        await test.expect(
            missing.key,
            equals: "name",
            "missing key retains key identity"
        )

        let mismatch = try decodingError(
            EnvelopeFixture.self,
            json: #"{"root":{"children":[{"name":7}]}}"#
        )

        await test.expect(
            mismatch.kind,
            equals: .typeMismatch,
            "type mismatch classification"
        )

        await test.expect(
            mismatch.path.jsonPath,
            equals: "$.root.children[0].name",
            "type mismatch retains its path"
        )

        await test.expect(
            mismatch.expectedType,
            equals: "String",
            "type mismatch retains expected type"
        )

        let missingValue = try decodingError(
            ChildFixture.self,
            json: #"{"name":null}"#
        )

        await test.expect(
            missingValue.kind,
            equals: .valueNotFound,
            "null nonoptional value classification"
        )

        await test.expect(
            missingValue.path.jsonPath,
            equals: "$.name",
            "null nonoptional value retains its path"
        )

        let corrupted = try decodingError(
            DayOfMonth.self,
            json: #"{"value":99}"#
        )

        await test.expect(
            corrupted.kind,
            equals: .dataCorrupted,
            "domain validation remains data corruption"
        )

        await test.expect(
            corrupted.path.jsonPath,
            equals: "$.value",
            "domain validation retains its coding path"
        )

        await test.expect(
            corrupted.reason.contains(
                "Invalid day of month: 99"
            ),
            "domain validation reason survives normalization"
        )

        let malformed = try decodingError(
            EnvelopeFixture.self,
            json: #"{"root":"#
        )

        await test.expect(
            malformed.kind,
            equals: .dataCorrupted,
            "malformed JSON classification"
        )

        await test.expect(
            malformed.path.jsonPath,
            equals: "$",
            "malformed JSON remains at root when no deeper path exists"
        )

        await test.record(
            .field(
                "missing_key_path",
                missing.path.jsonPath
            )
        )
        await test.record(
            .field(
                "type_mismatch_path",
                mismatch.path.jsonPath
            )
        )
        await test.record(
            .field(
                "data_corruption_path",
                corrupted.path.jsonPath
            )
        )
    }
}

private func decodingError<Value: Decodable>(
    _ type: Value.Type,
    json: String,
    coding: JSONCoding = .default
) throws -> JSONDecodingError {
    do {
        _ = try coding.decode(
            type,
            from: Data(
                json.utf8
            )
        )
    } catch {
        return error
    }

    throw JSONDecodingTestError.expectedFailure
}
