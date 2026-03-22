import Foundation

public struct PartialDate: Equatable, Hashable, Sendable, Codable {
    public var year: Int?
    public var month: Int?
    public var day: Int?

    public init(
        year: Int? = nil,
        month: Int? = nil,
        day: Int? = nil
    ) {
        self.year = year
        self.month = month
        self.day = day
    }

    public var isEmpty: Bool {
        year == nil && month == nil && day == nil
    }

    public var isComplete: Bool {
        year != nil && month != nil && day != nil
    }

    public var precision: DatePrecision? {
        switch (year, month, day) {
            case (.some, .some, .some):
                return .day
            case (.some, .some, .none):
                return .month
            case (.some, .none, .none):
                return .year
            default:
                return nil
        }
    }

    public func requireComplete() throws(DateSpecificationError) -> (year: Int, month: Int, day: Int) {
        guard
            let year,
            let month,
            let day
        else {
            throw .incompleteDateParts(
                year: self.year,
                month: self.month,
                day: self.day
            )
        }

        return (year, month, day)
    }

    public func resolve(
        in timeZone: TimeZone
    ) throws(DateSpecificationError) -> Date {
        let (year, month, day) = try requireComplete()

        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = timeZone
        components.year = year
        components.month = month
        components.day = day
        components.hour = 0
        components.minute = 0
        components.second = 0

        guard let date = components.date else {
            throw .invalidDateComponents(
                year: year,
                month: month,
                day: day,
                timeZoneIdentifier: timeZone.identifier
            )
        }

        return date
    }
}
