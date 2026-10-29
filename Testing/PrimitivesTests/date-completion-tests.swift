import Foundation
import Primitives

func test_date_completion_context() throws {
    let timezone = TimeZone(secondsFromGMT: 0)!
    let leap = try DateCompletionContext(year: 2024, month: 2, timezone: timezone)
    let source = try PartialDate(year: 2024, month: 2)
    let copied = try DateCompletionContext(source, timezone: timezone)
    try expect(copied.year == 2024 && copied.month == 2, "date completion context accepts validated PartialDate")

    let inferred = DateSpecification(infer: try DayOfMonth(29))
    let date = try inferred.resolve(using: leap)
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timezone
    let parts = calendar.dateComponents([.year, .month, .day], from: date)
    try expect(parts.year == 2024 && parts.month == 2 && parts.day == 29, "leap-day inference preserves calendar date")

    let absolute = Date(timeIntervalSince1970: 1_700_000_000)
    try expect(try DateSpecification(absolute: absolute).resolve(using: leap) == absolute, "absolute dates are independent of completion context")
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    let flatInfer = try encoder.encode(inferred)
    try expect(
        String(decoding: flatInfer, as: UTF8.self) == #"{"infer":29}"#,
        "inferred date has the canonical flat encoding"
    )
    try expect(
        try decoder.decode(DateSpecification.self, from: flatInfer) == inferred,
        "flat inferred date decodes"
    )
    try expect(
        try decoder.decode(
            DateSpecification.self,
            from: Data(#"{"infer":{"day":29}}"#.utf8)
        ) == inferred,
        "legacy nested inferred date decodes"
    )
    let iso = ISO8601DateFormatter().string(from: absolute)
    let flatAbsolute = try encoder.encode(DateSpecification(absolute: absolute))
    try expect(
        String(decoding: flatAbsolute, as: UTF8.self) == "{\"absolute\":\"\(iso)\"}",
        "absolute date has canonical ISO8601 string encoding"
    )
    try expect(
        try decoder.decode(DateSpecification.self, from: flatAbsolute) == .absolute(absolute),
        "flat absolute date decodes"
    )
    let nestedISO = Data("{\"absolute\":{\"_0\":\"\(iso)\"}}".utf8)
    try expect(
        try decoder.decode(DateSpecification.self, from: nestedISO) == .absolute(absolute),
        "legacy nested Accounting ISO date decodes"
    )
    let nestedNumeric = Data("{\"absolute\":{\"_0\":\(absolute.timeIntervalSinceReferenceDate)}}".utf8)
    try expect(
        try decoder.decode(DateSpecification.self, from: nestedNumeric) == .absolute(absolute),
        "legacy synthesized numeric date decodes"
    )
    for json in [#"{"infer":0}"#, #"{"infer":{"day":32}}"#] {
        do {
            _ = try decoder.decode(DateSpecification.self, from: Data(json.utf8))
            try expect(false, "invalid inferred day must fail decoding")
        } catch DecodingError.dataCorrupted {
            // Correct: DayOfMonth is still the invariant boundary.
        }
    }

    do {
        _ = try DateCompletionContext(year: 2024, month: 13, timezone: timezone)
        try expect(false, "context rejects invalid month")
    } catch DateSpecificationError.invalidPartialDate {}

    do {
        _ = try DateCompletionContext(PartialDate(year: 2024), timezone: timezone)
        try expect(false, "context rejects missing month")
    } catch DateSpecificationError.invalidCompletionContext {}

    do {
        let complete = try PartialDate(year: 2024, month: 2, day: 15)
        _ = try DateCompletionContext(complete, timezone: timezone)
        try expect(false, "a fully specified date is not a year/month completion context")
    } catch DateSpecificationError.invalidCompletionContext {}

    do {
        let nonLeap = try DateCompletionContext(year: 2025, month: 2, timezone: timezone)
        _ = try inferred.resolve(using: nonLeap)
        try expect(false, "non-leap February 29 must fail")
    } catch DateSpecificationError.invalidPartialDate {}

    do {
        _ = try DateSpecification(infer: try DayOfMonth(31)).resolve(using: leap)
        try expect(false, "February 31 must fail without normalizing into March")
    } catch DateSpecificationError.invalidPartialDate {}
}
