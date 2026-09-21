import Foundation
import Primitives

private struct JSONCodingFixture:
    Codable,
    Equatable,
    JSONCodingProviding
{
    static let jsonCoding = JSONCoding.casing(
        decoded: .camel,
        encoded: .snake
    )

    let someValue: Int
}

func run_json_coding_tests() throws {
    let conversion = CasingConversion(
        from: .snake,
        to: .camel
    )

    try expect(
        conversion.source == .snake,
        "casing conversion retains source representation"
    )

    try expect(
        conversion.destination == .camel,
        "casing conversion retains destination representation"
    )

    try expect(
        conversion("some_value") == "someValue",
        "casing conversion is directly callable"
    )

    let separatorData = try JSONEncoder().encode(
        Separators.common
    )
    let decodedSeparators = try JSONDecoder().decode(
        Separators.self,
        from: separatorData
    )

    try expect(
        decodedSeparators == .common,
        "separators round-trip through Codable"
    )

    let conversionData = try JSONEncoder().encode(
        conversion
    )
    let decodedConversion = try JSONDecoder().decode(
        CasingConversion.self,
        from: conversionData
    )

    try expect(
        decodedConversion == conversion,
        "casing conversion round-trips through Codable"
    )

    let fixture = JSONCodingFixture(
        someValue: 7
    )
    let coding = JSONCodingFixture.jsonCoding

    let encodedValue = try JSONValue.encoding(
        fixture,
        using: coding
    )
    let object = try encodedValue.objectValue

    try expect(
        object["some_value"] == .int(7),
        "JSONValue.encoding applies configured encoded casing"
    )

    let decoded: JSONCodingFixture = try encodedValue.decode(
        using: coding
    )

    try expect(
        decoded == fixture,
        "JSONValue.decode applies configured decoded casing"
    )

    let encodedData = try coding.encode(
        fixture
    )
    let dataValue = try JSONDecoder().decode(
        JSONValue.self,
        from: encodedData
    )

    try expect(
        try dataValue.objectValue["some_value"] == .int(7),
        "JSONCoding.encode applies configured casing"
    )

    let protocolValue = try fixture.jsonValue()
    let protocolDecoded = try JSONCodingFixture.decode(
        protocolValue
    )

    try expect(
        protocolDecoded == fixture,
        "JSONCodingProviding uses the type's declared coding policy"
    )

    let transformed = try coding.object(
        fixture,
        transform: .init(
            renames: [
                "some_value": "renamed_value",
            ],
            extras: [
                "extra": .bool(true),
            ]
        )
    )

    try expect(
        transformed["some_value"] == nil,
        "JSONCoding.object applies renames"
    )

    try expect(
        transformed["renamed_value"] == .int(7),
        "JSONCoding.object retains renamed values"
    )

    try expect(
        transformed["extra"] == .bool(true),
        "JSONCoding.object applies extras"
    )
}
