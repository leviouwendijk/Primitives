import Foundation
import Primitives
import TestFlows

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

private enum JSONDecodingFlowError: Error {
    case expectedFailure
}

enum PrimitivesFlowTesting {
    static func runJSONDecodingDiagnostics() async throws
        -> [TestFlowDiagnostic]
    {
        let path = JSONCodingPath(
            [
                .key("root"),
                .key("needs-escaping"),
                .index(2),
            ]
        )

        try Expect.equal(
            path.jsonPath,
            "$.root[\"needs-escaping\"][2]",
            "JSON coding path renders keys and indices"
        )

        let casing = try JSONCoding
            .casing(
                decodeTo: .camel
            )
            .decode(
                CasingFixture.self,
                from: Data(
                    #"{"some_value":7}"#.utf8
                )
            )

        try Expect.equal(
            casing.someValue,
            7,
            "JSONCoding.decode uses its configured decoder"
        )

        let missing = try decodingError(
            EnvelopeFixture.self,
            json: #"{"root":{"children":[{}]}}"#
        )

        try Expect.equal(
            missing.kind,
            .keyNotFound,
            "missing key classification"
        )

        try Expect.equal(
            missing.path.jsonPath,
            "$.root.children[0].name",
            "missing key includes the missing key in its path"
        )

        try Expect.equal(
            missing.key,
            "name",
            "missing key retains key identity"
        )

        let mismatch = try decodingError(
            EnvelopeFixture.self,
            json: #"{"root":{"children":[{"name":7}]}}"#
        )

        try Expect.equal(
            mismatch.kind,
            .typeMismatch,
            "type mismatch classification"
        )

        try Expect.equal(
            mismatch.path.jsonPath,
            "$.root.children[0].name",
            "type mismatch retains its path"
        )

        try Expect.equal(
            mismatch.expectedType,
            "String",
            "type mismatch retains expected type"
        )

        let missingValue = try decodingError(
            ChildFixture.self,
            json: #"{"name":null}"#
        )

        try Expect.equal(
            missingValue.kind,
            .valueNotFound,
            "null nonoptional value classification"
        )

        try Expect.equal(
            missingValue.path.jsonPath,
            "$.name",
            "null nonoptional value retains its path"
        )

        let corrupted = try decodingError(
            DayOfMonth.self,
            json: #"{"value":99}"#
        )

        try Expect.equal(
            corrupted.kind,
            .dataCorrupted,
            "domain validation remains data corruption"
        )

        try Expect.equal(
            corrupted.path.jsonPath,
            "$.value",
            "domain validation retains its coding path"
        )

        try Expect.true(
            corrupted.reason.contains(
                "Invalid day of month: 99"
            ),
            "domain validation reason survives normalization"
        )

        let malformed = try decodingError(
            EnvelopeFixture.self,
            json: #"{"root":"#
        )

        try Expect.equal(
            malformed.kind,
            .dataCorrupted,
            "malformed JSON classification"
        )

        try Expect.equal(
            malformed.path.jsonPath,
            "$",
            "malformed JSON remains at root when no deeper path exists"
        )

        return [
            .field(
                "missing_key_path",
                missing.path.jsonPath
            ),
            .field(
                "type_mismatch_path",
                mismatch.path.jsonPath
            ),
            .field(
                "data_corruption_path",
                corrupted.path.jsonPath
            ),
        ]
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

    throw JSONDecodingFlowError.expectedFailure
}
