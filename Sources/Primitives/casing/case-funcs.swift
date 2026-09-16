public enum Case {
    public static func components(
        _ value: String,
        separators: Separators = .common
    ) -> [String] {
        tokenize_identifier(
            value,
            separators: separators
        )
    }

    public static func convert(
        _ value: String,
        to casing: Casing,
        separators: Separators = .common
    ) -> String {
        convert(
            value,
            style: casing.style,
            separators: separators
        )
    }

    public static func convert(
        _ value: String,
        style: Casing.Style,
        separators: Separators = .common
    ) -> String {
        let words = components(
            value,
            separators: separators
        )

        guard !words.isEmpty else {
            return value
        }

        // 
        // return words
        //     .enumerated()
        //     .map { index, word in
        //         let wordCase =
        //             index == 0
        //             ? style.firstWord
        //             : style.remainingWords

        //         return wordCase.apply(
        //             to: word
        //         )
        //     }
        //     .joined(
        //         separator: style.separator.rawValue
        //     )

        return words
        .enumerated()
        .map { index, word in
            let wordCase =
                index == 0
                ? style.firstWord
                : style.remainingWords

            return wordCase.apply(
                to: word
            )
        }.joined(
            separator: style.separator.rawValue
        )
    }
}
