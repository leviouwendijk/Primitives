public protocol StringParsableEnum: RawRepresentable, CaseIterable where RawValue == String {
    static var available: [String] { get }
    static func available_list() -> String
    static func parse(from string: String) throws (EnumParsingError) -> Self
    init(parsing string: String) throws(EnumParsingError)
}

public extension StringParsableEnum {
    static var available: [String] {
        allCases.map(\.rawValue)
    }

    static func available_list() -> String {
        available.joined(separator: "\n")
    }

    init(parsing string: String) throws(EnumParsingError) {
        self = try Self.parse(from: string)
    }
    
    static func parse(from string: String) throws (EnumParsingError) -> Self {
        if let found = allCases.first(where: { $0.rawValue == string }) {
            return found
        }
        throw .init(
            enumName: String(describing: Self.self),
            provided: string,
            cases: available_list()
        )
    }
}
