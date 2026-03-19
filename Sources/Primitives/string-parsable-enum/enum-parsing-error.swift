import Foundation

public struct EnumParsingError: LocalizedError {
    public let enumName: String
    public let provided: String
    public let cases: String

    public var errorDescription: String? {
        """
        Failed to parse "\(provided)" to a valid case of enum '\(enumName)'

        Valid options are:
        \(cases)
        """
    }
}
