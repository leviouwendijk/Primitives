import Foundation

extension JSONValue {
    /// Render this JSONValue as a JSON string
    public func toJSONString(prettyPrinted: Bool = true) throws -> String {
        let encoder = JSONEncoder()
        if prettyPrinted {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        }
        
        let data = try encoder.encode(self)
        guard let json = String(data: data, encoding: .utf8) else {
            throw JSONValueError.invalidCast(description: "Failed to encode JSONValue to UTF-8")
        }
        return json
    }
}
