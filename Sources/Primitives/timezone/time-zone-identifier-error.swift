import Foundation

public enum TimeZoneIdentifierError: Error, LocalizedError {
    case cannotSyntesizeTimeZone
    
    public var errorDescription: String? {
        switch self {
        case .cannotSyntesizeTimeZone:
            return "Failed to synthesize time zone object"
        }
    }
}
