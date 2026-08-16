import Foundation

public struct PartialDate:
    Equatable,
    Hashable,
    Sendable,
    Codable
{
    private enum Storage:
        Equatable,
        Hashable,
        Sendable
    {
        case empty

        case year(
            Int
        )

        case month(
            year: Int,
            month: Int
        )

        case day(
            year: Int,
            month: Int,
            day: Int
        )
    }

    private enum CodingKeys:
        String,
        CodingKey
    {
        case year
        case month
        case day
    }

    private let storage: Storage

    public init() {
        self.storage = .empty
    }

    public init(
        year: Int
    ) {
        self.storage = .year(
            year
        )
    }

    public init(
        year: Int? = nil,
        month: Int? = nil,
        day: Int? = nil
    ) throws(DateSpecificationError) {
        switch (
            year,
            month,
            day
        ) {
        case (
            nil,
            nil,
            nil
        ):
            self.init()

        case (
            .some(
                let year
            ),
            nil,
            nil
        ):
            self.init(
                year: year
            )

        case (
            .some(
                let year
            ),
            .some(
                let month
            ),
            nil
        ):
            try self.init(
                year: year,
                month: month
            )

        case (
            .some(
                let year
            ),
            .some(
                let month
            ),
            .some(
                let day
            )
        ):
            try self.init(
                year: year,
                month: month,
                day: day
            )

        default:
            throw .incompleteDateParts(
                year: year,
                month: month,
                day: day
            )
        }
    }

    public init(
        year: Int,
        month: Int
    ) throws(DateSpecificationError) {
        try Self.validateMonth(
            year: year,
            month: month
        )

        self.storage = .month(
            year: year,
            month: month
        )
    }

    public init(
        year: Int,
        month: Int,
        day: Int
    ) throws(DateSpecificationError) {
        try Self.validateDay(
            year: year,
            month: month,
            day: day
        )

        self.storage = .day(
            year: year,
            month: month,
            day: day
        )
    }

    public var year: Int? {
        switch storage {
        case .empty:
            return nil

        case .year(
            let year
        ):
            return year

        case .month(
            let year,
            _
        ):
            return year

        case .day(
            let year,
            _,
            _
        ):
            return year
        }
    }

    public var month: Int? {
        switch storage {
        case .empty,
             .year:
            return nil

        case .month(
            _,
            let month
        ):
            return month

        case .day(
            _,
            let month,
            _
        ):
            return month
        }
    }

    public var day: Int? {
        switch storage {
        case .empty,
             .year,
             .month:
            return nil

        case .day(
            _,
            _,
            let day
        ):
            return day
        }
    }

    public var isEmpty: Bool {
        if case .empty = storage {
            return true
        }

        return false
    }

    public var isComplete: Bool {
        if case .day = storage {
            return true
        }

        return false
    }

    public var precision: DatePrecision? {
        switch storage {
        case .empty:
            return nil

        case .year:
            return .year

        case .month:
            return .month

        case .day:
            return .day
        }
    }

    public func requireComplete()
        throws(DateSpecificationError)
        -> (
            year: Int,
            month: Int,
            day: Int
        )
    {
        guard
            case .day(
                let year,
                let month,
                let day
            ) = storage
        else {
            throw .incompleteDateParts(
                year: self.year,
                month: self.month,
                day: self.day
            )
        }

        return (
            year,
            month,
            day
        )
    }

    public func resolve(
        in timeZone: TimeZone
    ) throws(DateSpecificationError) -> Date {
        let (
            year,
            month,
            day
        ) =
            try requireComplete()

        var components =
            DateComponents()

        components.calendar =
            Calendar(
                identifier: .gregorian
            )

        components.timeZone =
            timeZone

        components.year =
            year

        components.month =
            month

        components.day =
            day

        components.hour = 0
        components.minute = 0
        components.second = 0

        guard
            let date =
                components.date
        else {
            throw .invalidDateComponents(
                year: year,
                month: month,
                day: day,
                timeZoneIdentifier:
                    timeZone.identifier
            )
        }

        return date
    }

    public init(
        from decoder: Decoder
    ) throws {
        let container =
            try decoder.container(
                keyedBy: CodingKeys.self
            )

        let year =
            try container.decodeIfPresent(
                Int.self,
                forKey: .year
            )

        let month =
            try container.decodeIfPresent(
                Int.self,
                forKey: .month
            )

        let day =
            try container.decodeIfPresent(
                Int.self,
                forKey: .day
            )

        do {
            switch (
                year,
                month,
                day
            ) {
            case (
                nil,
                nil,
                nil
            ):
                self.init()

            case (
                .some(
                    let year
                ),
                nil,
                nil
            ):
                self.init(
                    year: year
                )

            case (
                .some(
                    let year
                ),
                .some(
                    let month
                ),
                nil
            ):
                try self.init(
                    year: year,
                    month: month
                )

            case (
                .some(
                    let year
                ),
                .some(
                    let month
                ),
                .some(
                    let day
                )
            ):
                try self.init(
                    year: year,
                    month: month,
                    day: day
                )

            default:
                throw DateSpecificationError
                    .incompleteDateParts(
                        year: year,
                        month: month,
                        day: day
                    )
            }
        } catch {
            throw DecodingError
                .dataCorrupted(
                    .init(
                        codingPath:
                            decoder.codingPath,
                        debugDescription:
                            "Invalid PartialDate: \(error.localizedDescription)"
                    )
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

        try container.encodeIfPresent(
            year,
            forKey: .year
        )

        try container.encodeIfPresent(
            month,
            forKey: .month
        )

        try container.encodeIfPresent(
            day,
            forKey: .day
        )
    }

    internal static func validateMonth(
        year: Int,
        month: Int
    ) throws(DateSpecificationError) {
        guard (1...12).contains(
            month
        ) else {
            throw .invalidPartialDate(
                year: year,
                month: month,
                day: nil
            )
        }
    }

    internal static func validateDay(
        year: Int,
        month: Int,
        day: Int
    ) throws(DateSpecificationError) {
        try validateMonth(
            year: year,
            month: month
        )

        guard (
            1...lastDay(
                year: year,
                month: month
            )
        ).contains(
            day
        ) else {
            throw .invalidPartialDate(
                year: year,
                month: month,
                day: day
            )
        }
    }

    internal static func lastDay(
        year: Int,
        month: Int
    ) -> Int {
        switch month {
        case 1,
             3,
             5,
             7,
             8,
             10,
             12:
            return 31

        case 4,
             6,
             9,
             11:
            return 30

        case 2:
            return isLeapYear(
                year
            )
                ? 29
                : 28

        default:
            return 31
        }
    }

    private static func isLeapYear(
        _ year: Int
    ) -> Bool {
        if year.isMultiple(
            of: 400
        ) {
            return true
        }

        if year.isMultiple(
            of: 100
        ) {
            return false
        }

        return year.isMultiple(
            of: 4
        )
    }
}
