public struct PercentEncoder: Sendable, Hashable {
    public var allowed: Set<UInt8>

    public init(
        allowed: Set<UInt8>
    ) {
        self.allowed = allowed
    }

    public init(
        allowed scalars: String
    ) {
        self.allowed = Set(
            scalars.utf8
        )
    }

    public func encode(
        _ value: String
    ) -> String {
        let hex = Array(
            "0123456789ABCDEF".utf8
        )

        var encoded = String()
        encoded.reserveCapacity(
            value.utf8.count
        )

        for byte in value.utf8 {
            if allowed.contains(byte) {
                encoded.append(
                    Character(
                        UnicodeScalar(byte)
                    )
                )
            } else {
                encoded.append("%")
                encoded.append(
                    Character(
                        UnicodeScalar(
                            hex[Int(byte >> 4)]
                        )
                    )
                )
                encoded.append(
                    Character(
                        UnicodeScalar(
                            hex[Int(byte & 0x0F)]
                        )
                    )
                )
            }
        }

        return encoded
    }
}
