import Foundation

public enum PartialDateSortCompletion: Sendable, Codable, Hashable {
    case earliest
    case latest
}

public extension PartialDate {
    static func year(
        _ year: Int
    ) -> PartialDate {
        PartialDate(
            year: year
        )
    }

    static func month(
        _ year: Int,
        _ month: Int
    ) throws(DateSpecificationError) -> PartialDate {
        try validateMonth(
            year: year,
            month: month
        )

        return PartialDate(
            year: year,
            month: month
        )
    }

    static func day(
        _ year: Int,
        _ month: Int,
        _ day: Int
    ) throws(DateSpecificationError) -> PartialDate {
        try validateDay(
            year: year,
            month: month,
            day: day
        )

        return PartialDate(
            year: year,
            month: month,
            day: day
        )
    }

    static func iso8601(
        _ value: String
    ) throws(DateSpecificationError) -> PartialDate {
        let parts = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "-", omittingEmptySubsequences: false)

        guard
            parts.count == 1 || parts.count == 2 || parts.count == 3,
            let year = Int(parts[0])
        else {
            throw .incompleteDateParts(
                year: nil,
                month: nil,
                day: nil
            )
        }

        if parts.count == 1 {
            return .year(year)
        }

        guard let month = Int(parts[1]) else {
            throw .incompleteDateParts(
                year: year,
                month: nil,
                day: nil
            )
        }

        if parts.count == 2 {
            return try .month(
                year,
                month
            )
        }

        guard let day = Int(parts[2]) else {
            throw .incompleteDateParts(
                year: year,
                month: month,
                day: nil
            )
        }

        return try .day(
            year,
            month,
            day
        )
    }

    var iso8601String: String? {
        guard let year else {
            return nil
        }

        guard let month else {
            return String(format: "%04d", year)
        }

        guard let day else {
            return String(format: "%04d-%02d", year, month)
        }

        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    func sortKey(
        completion: PartialDateSortCompletion
    ) -> Int? {
        guard let year else {
            return nil
        }

        let completedMonth: Int
        let completedDay: Int

        switch completion {
        case .earliest:
            completedMonth = month ?? 1
            completedDay = day ?? 1

        case .latest:
            completedMonth = month ?? 12
            completedDay = day ?? Self.lastDay(
                year: year,
                month: completedMonth
            )
        }

        return year * 10_000 + completedMonth * 100 + completedDay
    }

    private static func validateMonth(
        year: Int,
        month: Int
    ) throws(DateSpecificationError) {
        guard (1...12).contains(month) else {
            throw .invalidPartialDate(
                year: year,
                month: month,
                day: nil
            )
        }
    }

    private static func validateDay(
        year: Int,
        month: Int,
        day: Int
    ) throws(DateSpecificationError) {
        try validateMonth(
            year: year,
            month: month
        )

        guard (1...lastDay(year: year, month: month)).contains(day) else {
            throw .invalidPartialDate(
                year: year,
                month: month,
                day: day
            )
        }
    }

    private static func lastDay(
        year: Int,
        month: Int
    ) -> Int {
        switch month {
        case 1, 3, 5, 7, 8, 10, 12:
            return 31

        case 4, 6, 9, 11:
            return 30

        case 2:
            return isLeapYear(year) ? 29 : 28

        default:
            return 31
        }
    }

    private static func isLeapYear(
        _ year: Int
    ) -> Bool {
        if year.isMultiple(of: 400) {
            return true
        }

        if year.isMultiple(of: 100) {
            return false
        }

        return year.isMultiple(of: 4)
    }
}
