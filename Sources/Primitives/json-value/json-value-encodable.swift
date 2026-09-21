import Foundation

public struct JSONValueTransform {
    public var renames: [String:String] = [:]       // e.g. ["ip":"ip_address"]
    public var drops: Set<String> = []              // omit these keys
    public var extras: [String: JSONValue] = [:]    // inject or override

    public init(
        renames: [String:String] = [:],
        drops: Set<String> = [],
        extras: [String: JSONValue] = [:]
    ) {
        self.renames = renames
        self.drops = drops
        self.extras = extras
    }
}

