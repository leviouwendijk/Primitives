import Foundation

public extension JSONEncoder.KeyEncodingStrategy {
    static func casing(
        _ casing: Casing,
        separators: Separators = .common
    ) -> Self {
        Self.casing(
            style: casing.style,
            separators: separators
        )
    }

    static func casing(
        style: Casing.Style,
        separators: Separators = .common
    ) -> Self {
        .custom { path in
            CasingCodingKey(
                Case.convert(
                    path.last!.stringValue,
                    style: style,
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
        Self.casing(
            style: casing.style,
            separators: separators
        )
    }

    static func casing(
        style: Casing.Style,
        separators: Separators = .common
    ) -> Self {
        .custom { path in
            CasingCodingKey(
                Case.convert(
                    path.last!.stringValue,
                    style: style,
                    separators: separators
                )
            )
        }
    }
}
