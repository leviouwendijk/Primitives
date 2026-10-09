import Foundation

public extension Case {
    static func preserve(
        original: String,
        replacement: String
    ) -> String {
        CasingPattern.infer(from: original).apply(to: replacement)
    }

    static func substitute(
        _ source: String,
        matching needle: String,
        with replacement: String,
        replacingAll: Bool = true
    ) -> String {
        guard !needle.isEmpty else {
            return source
        }

        var result = ""
        result.reserveCapacity(source.utf8.count)
        var cursor = source.startIndex

        while cursor < source.endIndex,
            let match = source.range(
                of: needle,
                options: [.caseInsensitive],
                range: cursor..<source.endIndex
            ) {
            result.append(contentsOf: source[cursor..<match.lowerBound])
            result.append(
                preserve(
                    original: String(source[match]),
                    replacement: replacement
                )
            )
            cursor = match.upperBound

            if !replacingAll {
                break
            }
        }

        result.append(contentsOf: source[cursor...])
        return result
    }
}
