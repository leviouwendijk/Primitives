import Foundation

public protocol JSONWritable: Codable {}

public extension JSONWritable {
    func json(to url: URL) throws {
        try self.data()
        .write(to: url, options: .atomic)
    }

    func data() throws -> Data {
        let enc = JSONEncoder()
        enc.outputFormatting = [
            .prettyPrinted, 
            .sortedKeys
        ]
        return try enc.encode(self)
    }
}
