import Foundation

/// An invariant whose wire format is exactly its raw representation.
///
/// Decoding decodes `Raw` and then constructs through `init(_:)`, so a decoded
/// value carries the same guarantee as a directly constructed one. A
/// construction failure surfaces as `DecodingError.dataCorrupted` at the
/// current coding path, with the typed construction error preserved as
/// `underlyingError`.
///
/// Adopt this only when `Raw`'s encoding is the intended wire format; types
/// with an established keyed format should keep explicit coding.
public protocol CodableInvariant: MutableInvariant, Codable
where Raw: Codable {}

public extension CodableInvariant {
    init(
        from decoder: Decoder
    ) throws {
        let raw = try Raw(
            from: decoder
        )

        do {
            try self.init(
                raw
            )
        } catch {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Invalid \(Self.self): \(error)",
                    underlyingError: error
                )
            )
        }
    }

    func encode(
        to encoder: Encoder
    ) throws {
        try raw.encode(
            to: encoder
        )
    }
}
