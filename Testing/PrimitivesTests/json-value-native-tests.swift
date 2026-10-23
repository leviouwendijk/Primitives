import Foundation
import Primitives

func run_json_value_native_tests() throws {
    guard let uuid = UUID(uuidString: "123E4567-E89B-12D3-A456-426614174000") else {
        try expect(false, "UUID test fixture must be valid")
        return
    }
    let value = JSONValue(uuid)

    try expect(
        value == .string(uuid.uuidString),
        "UUID construction preserves the JSON string representation"
    )
    try expect(
        try value.uuidValue == uuid,
        "UUID extraction returns the typed value"
    )
    try expect(
        value.valueOrNil.uuid == uuid,
        "optional UUID accessor returns valid UUIDs"
    )

    let encoded = try JSONEncoder().encode(value)
    let decoded = try JSONDecoder().decode(JSONValue.self, from: encoded)
    try expect(
        decoded == .string(uuid.uuidString),
        "Codable does not introduce UUID enum semantics"
    )
    try expect(
        try decoded.uuidValue == uuid,
        "UUID survives JSONValue serialization"
    )

    let invalid = JSONValue.string("not-a-uuid")
    try expect(
        invalid.valueOrNil.uuid == nil,
        "optional UUID accessor rejects malformed strings"
    )
    do {
        _ = try invalid.uuidValue
        try expect(false, "invalid UUID must throw")
    } catch let error as JSONValueError {
        guard case .invalidCast = error else { throw error }
    }

    try expect(
        JSONValue.int(1).valueOrNil.uuid == nil,
        "optional UUID accessor rejects non-string JSON types"
    )
    do {
        _ = try JSONValue.int(1).uuidValue
        try expect(false, "non-string UUID must throw")
    } catch let error as JSONValueError {
        guard case .typeMismatch = error else { throw error }
    }

    try expect(
        try JSONValue.double(3.0).intValue == 3,
        "exact integral doubles convert to Int"
    )
    try expect(
        try JSONValue.string("42").intValue == 42,
        "existing string-to-Int conversion remains supported"
    )
    for invalid_integer in [1.5, 1e300, Double.nan, Double.infinity] {
        let value = JSONValue.double(invalid_integer)
        try expect(
            value.valueOrNil.int == nil,
            "non-integral, out-of-range or non-finite doubles cannot be Int"
        )
        do {
            _ = try value.intValue
            try expect(false, "invalid Double-to-Int conversion must throw")
        } catch let error as JSONValueError {
            guard case .invalidCast = error else { throw error }
        }
    }

    let integral_json = try JSONDecoder().decode(
        JSONValue.self,
        from: Data("3.0".utf8)
    )
    try expect(
        integral_json == .int(3),
        "decoding still folds exactly integral doubles"
    )

    let large_json = try JSONDecoder().decode(
        JSONValue.self,
        from: Data("1e300".utf8)
    )
    try expect(
        large_json == .double(1e300),
        "very large JSON numbers decode without overflowing Int"
    )

    let just_outside_int = try JSONDecoder().decode(
        JSONValue.self,
        from: Data("9223372036854775808".utf8)
    )
    try expect(
        just_outside_int == .double(9_223_372_036_854_775_808.0),
        "JSON numbers beyond Int.max remain double values"
    )
}
