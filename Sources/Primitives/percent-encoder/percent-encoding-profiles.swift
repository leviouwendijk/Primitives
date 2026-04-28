public enum PercentEncodingProfiles {
    public static let rfc3986Unreserved = PercentEncoder(
        allowed: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~"
    )
}
