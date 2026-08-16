import Foundation

public enum DateSpecification:
    Equatable,
    Hashable,
    Sendable,
    Codable
{
    case absolute(Date)
    case infer(
        day: DayOfMonth
    )

    private enum CodingKeys:
        String,
        CodingKey
    {
        case absolute
        case infer
    }

    private enum AbsoluteCodingKeys:
        String,
        CodingKey
    {
        case _0
    }

    private enum InferCodingKeys:
        String,
        CodingKey
    {
        case day
    }

    public init(
        absolute date: Date
    ) {
        self = .absolute(
            date
        )
    }

    public init(
        inferDay day: Int
    ) throws(DateSpecificationError) {
        do {
            self = .infer(
                day: try DayOfMonth(
                    day
                )
            )
        } catch {
            throw .invalidInferDay(
                day
            )
        }
    }

    public init(
        infer day: DayOfMonth
    ) {
        self = .infer(
            day: day
        )
    }

    public var isAbsolute: Bool {
        switch self {
        case .absolute:
            return true

        case .infer:
            return false
        }
    }

    public var isInfer: Bool {
        !isAbsolute
    }

    public var absoluteDate: Date? {
        switch self {
        case .absolute(
            let date
        ):
            return date

        case .infer:
            return nil
        }
    }

    public var inferredDay: Int? {
        switch self {
        case .absolute:
            return nil

        case .infer(
            let day
        ):
            return day.value
        }
    }

    public func requireAbsolute()
        throws(DateSpecificationError) -> Date
    {
        switch self {
        case .absolute(
            let date
        ):
            return date

        case .infer:
            throw .inferNotAbsolute
        }
    }

    public func encode(
        to encoder: Encoder
    ) throws {
        var container =
            encoder.container(
                keyedBy: CodingKeys.self
            )

        switch self {
        case .absolute(
            let date
        ):
            var nested =
                container.nestedContainer(
                    keyedBy:
                        AbsoluteCodingKeys.self,
                    forKey: .absolute
                )

            try nested.encode(
                date,
                forKey: ._0
            )

        case .infer(
            let day
        ):
            var nested =
                container.nestedContainer(
                    keyedBy:
                        InferCodingKeys.self,
                    forKey: .infer
                )

            try nested.encode(
                day.value,
                forKey: .day
            )
        }
    }

    public init(
        from decoder: Decoder
    ) throws {
        let container =
            try decoder.container(
                keyedBy: CodingKeys.self
            )

        if container.contains(
            .absolute
        ) {
            let nested =
                try container.nestedContainer(
                    keyedBy:
                        AbsoluteCodingKeys.self,
                    forKey: .absolute
                )

            self = .absolute(
                try nested.decode(
                    Date.self,
                    forKey: ._0
                )
            )

            return
        }

        if container.contains(
            .infer
        ) {
            let nested =
                try container.nestedContainer(
                    keyedBy:
                        InferCodingKeys.self,
                    forKey: .infer
                )

            let value =
                try nested.decode(
                    Int.self,
                    forKey: .day
                )

            do {
                self = .infer(
                    day: try DayOfMonth(
                        value
                    )
                )
            } catch {
                throw DecodingError
                    .dataCorruptedError(
                        forKey: .day,
                        in: nested,
                        debugDescription:
                            "Invalid day of month: \(value)"
                    )
            }

            return
        }

        throw DecodingError.dataCorrupted(
            .init(
                codingPath:
                    decoder.codingPath,
                debugDescription:
                    "Invalid DateSpecification"
            )
        )
    }
}

public enum DateSpecificationError:
    Error,
    LocalizedError,
    Sendable,
    Equatable
{
    case inferNotAbsolute
    case invalidInferDay(Int)
    case incompleteDateParts(
        year: Int?,
        month: Int?,
        day: Int?
    )
    case invalidPartialDate(
        year: Int,
        month: Int?,
        day: Int?
    )
    case invalidDateComponents(
        year: Int,
        month: Int,
        day: Int,
        timeZoneIdentifier: String
    )

    public var errorDescription: String? {
        switch self {
        case .inferNotAbsolute:
            return "Expected absolute date, got inferred date"

        case .invalidInferDay(
            let day
        ):
            return "Invalid inferred day: \(day)"

        case .incompleteDateParts(
            let year,
            let month,
            let day
        ):
            return "Incomplete date parts year=\(String(describing: year)) month=\(String(describing: month)) day=\(String(describing: day))"

        case .invalidPartialDate(
            let year,
            let month,
            let day
        ):
            return "Invalid partial date year=\(year) month=\(String(describing: month)) day=\(String(describing: day))"

        case .invalidDateComponents(
            let year,
            let month,
            let day,
            let timeZoneIdentifier
        ):
            return "Invalid date components year=\(year) month=\(month) day=\(day) timeZone=\(timeZoneIdentifier)"
        }
    }
}
