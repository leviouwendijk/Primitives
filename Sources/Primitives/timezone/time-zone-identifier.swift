import Foundation

public enum TimeZoneIdentifier: String, TimeZoneIdentifying {
    case utc
    
    // North America
    case hawaii
    case alaska
    case pacific
    case mountain
    case central
    case eastern
    case atlantic
    
    // South America
    case brazil
    
    // Europe & Africa
    case london
    case amsterdam
    case athens
    case moscow
    
    // Middle East & South Asia
    case israel  
    case dubai
    case kolkata
    case dhaka
    
    // Southeast Asia
    case bangkok
    case hongKong
    
    // East Asia & Oceania
    case tokyo
    case sydney
    case auckland

    public var title: String {
        self.rawValue     
    }

    public var identifier: String {
        switch self {
        // UTC std
        case .utc: return "UTC"
        
        // North America
        case .hawaii: return "Pacific/Honolulu"         // UTC-10
        case .alaska: return "America/Anchorage"         // UTC-9
        case .pacific: return "America/Los_Angeles"        // UTC-8
        case .mountain: return "America/Denver"          // UTC-7
        case .central: return "America/Chicago"          // UTC-6
        case .eastern: return "America/New_York"         // UTC-5
        case .atlantic: return "America/Halifax"         // UTC-4
        
        // South America
        case .brazil: return "America/Sao_Paulo"         // UTC-3
        
        // Europe & Africa
        case .london: return "Europe/London"             // UTC+0
        case .amsterdam: return "Europe/Amsterdam"       // UTC+1
        case .athens: return "Europe/Athens"             // UTC+2
        case .moscow: return "Europe/Moscow"             // UTC+3
        
        // Middle East & South Asia
        case .israel  : return "Asia/Jerusalem" 
        case .dubai: return "Asia/Dubai"                 // UTC+4
        case .kolkata: return "Asia/Kolkata"             // UTC+5:30
        case .dhaka: return "Asia/Dhaka"                 // UTC+6
        
        // Southeast Asia
        case .bangkok: return "Asia/Bangkok"             // UTC+7
        case .hongKong: return "Asia/Hong_Kong"           // UTC+8
        
        // East Asia & Oceania
        case .tokyo: return "Asia/Tokyo"                 // UTC+9
        case .sydney: return "Australia/Sydney"          // UTC+10
        case .auckland: return "Pacific/Auckland"        // UTC+12
        }
    }
    
    public func timezone() throws -> TimeZone {
        if let timezone = TimeZone(identifier: self.identifier) {
            return timezone
        } else {
            throw TimeZoneIdentifierError.cannotSyntesizeTimeZone
        }
    }
}
