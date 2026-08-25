public protocol CasingCodable: Codable {}

public extension CasingCodable {
    var casing: CodableCasingAPI<Self> {
        .init(
            self
        )
    }

    func cased(
        _ casing: Casing,
        separators: Separators = .common,
        sourceCoding: JSONCoding = .default
    ) -> Cased<Self> {
        .init(
            self,
            as: casing,
            separators: separators,
            sourceCoding: sourceCoding
        )
    }
}
