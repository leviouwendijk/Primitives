import Foundation

public struct YearQuarter: Equatable, Hashable, Sendable, Codable {
    public var year: Int
    public var quarter: Int

    public init(
        year: Int,
        quarter: Int
    ) throws {
        guard (1...4).contains(quarter) else {
            throw YearQuarterError.invalidQuarter(quarter)
        }

        self.year = year
        self.quarter = quarter
    }

    public init(
        containing date: Date,
        calendar: Calendar
    ) {
        self.year = calendar.component(
            .year,
            from: date
        )

        let month = calendar.component(
            .month,
            from: date
        )

        self.quarter = ((month - 1) / 3) + 1
    }

    public var label: String {
        "\(year)Q\(quarter)"
    }

    public var slug: String {
        label
    }

    public func startDate(
        timeZone: TimeZone,
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> Date {
        var calendar = calendar
        calendar.timeZone = timeZone

        return calendar.date(
            from: DateComponents(
                timeZone: timeZone,
                year: year,
                month: ((quarter - 1) * 3) + 1,
                day: 1
            )
        )!
    }
}

public enum YearQuarterError: Error, LocalizedError, Sendable, Equatable {
    case invalidQuarter(Int)

    public var errorDescription: String? {
        switch self {
        case .invalidQuarter(let quarter):
            return "Invalid quarter: \(quarter)"
        }
    }
}

public extension YearQuarter {
    static func lastCompleted(
        timeZone: TimeZone,
        calendar: Calendar = Calendar(identifier: .gregorian),
        now: Date = Date()
    ) -> YearQuarter {
        var calendar = calendar
        calendar.timeZone = timeZone

        let current = YearQuarter(
            containing: now,
            calendar: calendar
        )

        if current.quarter > 1 {
            return try! YearQuarter(
                year: current.year,
                quarter: current.quarter - 1
            )
        }

        return try! YearQuarter(
            year: current.year - 1,
            quarter: 4
        )
    }
}
