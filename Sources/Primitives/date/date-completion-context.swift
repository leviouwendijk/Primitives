import Foundation

/// Calendar context sufficient to complete an inferred day of the month.
/// It contains no source-file, directory or application-specific semantics.
/// Construction validates the year/month pair through PartialDate.
public struct DateCompletionContext: Invariant, Sendable {
    public typealias Error = DateSpecificationError

    public struct Raw: Sendable {
        public let year: Int
        public let month: Int
        public let timezone: TimeZone

        public init(year: Int, month: Int, timezone: TimeZone) {
            self.year = year
            self.month = month
            self.timezone = timezone
        }
    }

    public let year: Int
    public let month: Int
    public let timezone: TimeZone

    public init(_ raw: Raw) throws(DateSpecificationError) {
        _ = try PartialDate(year: raw.year, month: raw.month)
        self.year = raw.year
        self.month = raw.month
        self.timezone = raw.timezone
    }

    public init(
        year: Int,
        month: Int,
        timezone: TimeZone
    ) throws(DateSpecificationError) {
        try self.init(.init(year: year, month: month, timezone: timezone))
    }

    /// Accept a previously validated year/month PartialDate as context.
    /// A complete date is not a completion context: its day is already fixed.
    public init(
        _ partial: PartialDate,
        timezone: TimeZone
    ) throws(DateSpecificationError) {
        guard
            let year = partial.year,
            let month = partial.month,
            partial.day == nil
        else {
            throw .invalidCompletionContext(
                year: partial.year,
                month: partial.month,
                day: partial.day
            )
        }
        try self.init(year: year, month: month, timezone: timezone)
    }

    public func complete(day: DayOfMonth) throws(DateSpecificationError) -> Date {
        let completed = try PartialDate(
            year: year,
            month: month,
            day: day.value
        )
        return try completed.resolve(in: timezone)
    }
}

public extension DateSpecification {
    /// Resolve an inferred day against a validated calendar context.
    /// An already absolute date is returned unchanged.
    func resolve(
        using context: DateCompletionContext
    ) throws(DateSpecificationError) -> Date {
        switch self {
        case .absolute(let date):
            return date
        case .infer(let day):
            return try context.complete(day: day)
        }
    }
}
