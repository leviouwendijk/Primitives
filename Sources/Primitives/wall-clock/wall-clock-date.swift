import Foundation

/// Atomos has no Foundation; Primitives bridges its wall clock to `Date`.
public extension Date {
    init(
        _ instant: WallClock.Instant
    ) {
        self.init(
            timeIntervalSince1970: instant.secondsSinceUnixEpoch
        )
    }
}

public extension WallClock.Instant {
    /// Rounds to the nearest nanosecond.
    init(
        _ date: Date
    ) {
        self.init(
            secondsSinceUnixEpoch: date.timeIntervalSince1970
        )
    }
}
