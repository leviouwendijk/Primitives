import Foundation

public enum PartialDateSortCompletion:
    Sendable,
    Codable,
    Hashable
{
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
        try PartialDate(
            year: year,
            month: month
        )
    }

    static func day(
        _ year: Int,
        _ month: Int,
        _ day: Int
    ) throws(DateSpecificationError) -> PartialDate {
        try PartialDate(
            year: year,
            month: month,
            day: day
        )
    }

    static func iso8601(
        _ value: String
    ) throws(DateSpecificationError) -> PartialDate {
        let parts =
            value
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .split(
                    separator: "-",
                    omittingEmptySubsequences:
                        false
                )

        guard
            parts.count == 1
                || parts.count == 2
                || parts.count == 3,
            let year =
                Int(
                    parts[0]
                )
        else {
            throw .incompleteDateParts(
                year: nil,
                month: nil,
                day: nil
            )
        }

        if parts.count == 1 {
            return .year(
                year
            )
        }

        guard
            let month =
                Int(
                    parts[1]
                )
        else {
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

        guard
            let day =
                Int(
                    parts[2]
                )
        else {
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
        guard
            let year
        else {
            return nil
        }

        guard
            let month
        else {
            return String(
                format: "%04d",
                year
            )
        }

        guard
            let day
        else {
            return String(
                format: "%04d-%02d",
                year,
                month
            )
        }

        return String(
            format: "%04d-%02d-%02d",
            year,
            month,
            day
        )
    }

    func sortKey(
        completion:
            PartialDateSortCompletion
    ) -> Int? {
        guard
            let year
        else {
            return nil
        }

        let completedMonth: Int
        let completedDay: Int

        switch completion {
        case .earliest:
            completedMonth =
                month ?? 1

            completedDay =
                day ?? 1

        case .latest:
            completedMonth =
                month ?? 12

            completedDay =
                day
                    ?? Self.lastDay(
                        year: year,
                        month:
                            completedMonth
                    )
        }

        return
            year * 10_000
            + completedMonth * 100
            + completedDay
    }
}
