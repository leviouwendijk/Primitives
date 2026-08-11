import Foundation

public extension JSONEncoder.KeyEncodingStrategy {
    static func casing(
        _ casing: Casing,
        separators: Separators = .common
    ) -> Self {
        .custom { path in
            CasingCodingKey(
                Case.convert(
                    path.last!.stringValue,
                    to: casing,
                    separators: separators
                )
            )
        }
    }
}

public extension JSONDecoder.KeyDecodingStrategy {
    static func casing(
        _ casing: Casing,
        separators: Separators = .common
    ) -> Self {
        .custom { path in
            CasingCodingKey(
                Case.convert(
                    path.last!.stringValue,
                    to: casing,
                    separators: separators
                )
            )
        }
    }
}
