import Foundation

public enum DateSpecification: Equatable, Hashable, Sendable, Codable {
    case absolute(Date)
    case infer(day: Int)

    public init(absolute date: Date) {
        self = .absolute(date)
    }

    public init(inferDay day: Int) throws(DateSpecificationError) {
        guard (1...31).contains(day) else {
            throw .invalidInferDay(day)
        }
        self = .infer(day: day)
    }

    public init(infer day: DayOfMonth) {
        self = .infer(day: day.value)
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
            case .absolute(let date):
                return date
            case .infer:
                return nil
        }
    }

    public var inferredDay: Int? {
        switch self {
            case .absolute:
                return nil
            case .infer(let day):
                return day
        }
    }

    public func requireAbsolute() throws(DateSpecificationError) -> Date {
        switch self {
            case .absolute(let date):
                return date
            case .infer:
                throw .inferNotAbsolute
        }
    }
}

public enum DateSpecificationError: Error, LocalizedError, Sendable, Equatable {
    case inferNotAbsolute
    case invalidInferDay(Int)
    case incompleteDateParts(year: Int?, month: Int?, day: Int?)
    case invalidDateComponents(year: Int, month: Int, day: Int, timeZoneIdentifier: String)

    public var errorDescription: String? {
        switch self {
            case .inferNotAbsolute:
                return "Expected absolute date, got inferred date"
            case .invalidInferDay(let day):
                return "Invalid inferred day: \(day)"
            case .incompleteDateParts(let year, let month, let day):
                return "Incomplete date parts year=\(String(describing: year)) month=\(String(describing: month)) day=\(String(describing: day))"
            case .invalidDateComponents(let year, let month, let day, let timeZoneIdentifier):
                return "Invalid date components year=\(year) month=\(month) day=\(day) timeZone=\(timeZoneIdentifier)"
        }
    }
}
