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

    /// Canonical wire format: {"absolute":"ISO8601"} or {"infer":29}.
    /// Decoding also accepts the older nested enum representations.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .absolute(let date):
            try container.encode(
                ISO8601DateFormatter().string(from: date),
                forKey: .absolute
            )
        case .infer(let day):
            try container.encode(day.value, forKey: .infer)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if container.contains(.absolute) {
            let formatter = ISO8601DateFormatter()

            if let text = try? container.decode(String.self, forKey: .absolute),
               let date = formatter.date(from: text) {
                self = .absolute(date)
                return
            }

            // Old synthesized enum encoding (including user-configured
            // JSONDecoder date strategies), and Accounting's nested ISO form.
            let nested = try container.nestedContainer(
                keyedBy: AbsoluteCodingKeys.self, forKey: .absolute
            )
            if let date = try? nested.decode(Date.self, forKey: ._0) {
                self = .absolute(date)
                return
            }
            if let text = try? nested.decode(String.self, forKey: ._0),
               let date = formatter.date(from: text) {
                self = .absolute(date)
                return
            }
            throw DecodingError.dataCorruptedError(
                forKey: .absolute, in: container,
                debugDescription: "Invalid absolute date"
            )
        }

        if container.contains(.infer) {
            let day: Int
            if let flat = try? container.decode(Int.self, forKey: .infer) {
                day = flat
            } else {
                let nested = try container.nestedContainer(
                    keyedBy: InferCodingKeys.self, forKey: .infer
                )
                day = try nested.decode(Int.self, forKey: .day)
            }

            do {
                self = .infer(day: try DayOfMonth(day))
            } catch {
                throw DecodingError.dataCorruptedError(
                    forKey: .infer, in: container,
                    debugDescription: "Invalid day of month: \(day)"
                )
            }
            return
        }

        throw DecodingError.dataCorrupted(
            .init(codingPath: decoder.codingPath,
                  debugDescription: "Invalid DateSpecification")
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
    case invalidCompletionContext(
        year: Int?,
        month: Int?,
        day: Int?
    )
    case invalidDateComponents(
        year: Int,
        month: Int,
        day: Int,
        timezoneIdentifier: String
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

        case .invalidCompletionContext(let year, let month, let day):
            return "Date completion requires year and month, without a day; got year=\(String(describing: year)) month=\(String(describing: month)) day=\(String(describing: day))"
        case .invalidDateComponents(
            let year,
            let month,
            let day,
            let timezoneIdentifier
        ):
            return "Invalid date components year=\(year) month=\(month) day=\(day) timezone=\(timezoneIdentifier)"
        }
    }
}
