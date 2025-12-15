import Foundation

public protocol TimeZoneIdentifying: Codable, Sendable, CaseIterable {
    var title: String { get }
    var identifier: String { get }
    func timezone() throws -> TimeZone
}
