import Foundation

public struct YearQuarter:
    Equatable,
    Hashable,
    Sendable,
    Codable
{
    public let year: Int
    public let quarter: Int

    private enum CodingKeys:
        String,
        CodingKey
    {
        case year
        case quarter
    }

    public init(
        year: Int,
        quarter: Int
    ) throws(YearQuarterError) {
        guard (1...4).contains(
            quarter
        ) else {
            throw .invalidQuarter(
                quarter
            )
        }

        self.year = year
        self.quarter = quarter
    }

    public init(
        label: String
    ) throws(YearQuarterError) {
        let normalized =
            label
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .uppercased()

        let parts =
            normalized.split(
                separator: "Q",
                omittingEmptySubsequences: false
            )

        guard
            parts.count == 2,
            let year = Int(
                parts[0]
            ),
            let quarter = Int(
                parts[1]
            )
        else {
            throw .invalidLabel(
                label
            )
        }

        try self.init(
            year: year,
            quarter: quarter
        )
    }

    public init(
        containing date: Date,
        calendar: Calendar
    ) {
        self.year =
            calendar.component(
                .year,
                from: date
            )

        let month =
            calendar.component(
                .month,
                from: date
            )

        self.quarter =
            ((month - 1) / 3) + 1
    }

    public init(
        from decoder: Decoder
    ) throws {
        let container =
            try decoder.container(
                keyedBy: CodingKeys.self
            )

        let year =
            try container.decode(
                Int.self,
                forKey: .year
            )

        let quarter =
            try container.decode(
                Int.self,
                forKey: .quarter
            )

        do {
            try self.init(
                year: year,
                quarter: quarter
            )
        } catch {
            throw DecodingError
                .dataCorruptedError(
                    forKey: .quarter,
                    in: container,
                    debugDescription:
                        "Invalid quarter: \(quarter)"
                )
        }
    }

    public func encode(
        to encoder: Encoder
    ) throws {
        var container =
            encoder.container(
                keyedBy: CodingKeys.self
            )

        try container.encode(
            year,
            forKey: .year
        )

        try container.encode(
            quarter,
            forKey: .quarter
        )
    }

    public var label: String {
        "\(year)Q\(quarter)"
    }

    public var slug: String {
        label
    }

    public func startDate(
        timeZone: TimeZone,
        calendar: Calendar =
            Calendar(
                identifier: .gregorian
            )
    ) -> Date {
        var calendar = calendar

        calendar.timeZone =
            timeZone

        return calendar.date(
            from: DateComponents(
                timeZone: timeZone,
                year: year,
                month:
                    ((quarter - 1) * 3)
                        + 1,
                day: 1
            )
        )!
    }
}

public enum YearQuarterError:
    Error,
    LocalizedError,
    Sendable,
    Equatable
{
    case invalidLabel(
        String
    )

    case invalidQuarter(
        Int
    )

    public var errorDescription: String? {
        switch self {
        case .invalidLabel(
            let label
        ):
            return "Invalid year-quarter label: \(label)"

        case .invalidQuarter(
            let quarter
        ):
            return "Invalid quarter: \(quarter)"
        }
    }
}

public extension YearQuarter {
    static func lastCompleted(
        timeZone: TimeZone,
        calendar: Calendar =
            Calendar(
                identifier: .gregorian
            ),
        now: Date = Date()
    ) -> YearQuarter {
        var calendar = calendar

        calendar.timeZone =
            timeZone

        let current =
            YearQuarter(
                containing: now,
                calendar: calendar
            )

        if current.quarter > 1 {
            return try! YearQuarter(
                year: current.year,
                quarter:
                    current.quarter
                        - 1
            )
        }

        return try! YearQuarter(
            year:
                current.year
                    - 1,
            quarter: 4
        )
    }
}
