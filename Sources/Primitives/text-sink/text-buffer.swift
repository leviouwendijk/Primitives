import Foundation

/// Text collected from a `TextSink`, safe to write from any thread. It keeps the order the
/// streams were written in (adjacent writes to one stream join into one segment), so the
/// combined text reads chronologically while each stream can still be read alone.
///
/// Each segment records when its first and last write arrived, so a reader can tell when
/// output came and how long it went quiet without timestamps in the text itself. With
/// `splitAfter`, a write after that much silence starts a new segment even on the same
/// stream, so pauses stay visible.
///
/// With a `limit`, the oldest text is dropped once the total exceeds it, and `dropped`
/// counts what went, so a reader always knows the text is a tail. A trimmed segment keeps
/// its `start`.
public final class TextBuffer: @unchecked Sendable {
    public struct Segment: Sendable, Hashable {
        public let stream: TextStream
        public internal(set) var text: String
        /// When the segment's first write arrived (the buffer's clock).
        public let start: Date
        /// When its last write arrived.
        public internal(set) var end: Date

        public init(
            stream: TextStream,
            text: String,
            start: Date,
            end: Date
        ) {
            self.stream = stream
            self.text = text
            self.start = start
            self.end = end
        }
    }

    /// Maximum characters kept; nil keeps everything.
    public let limit: Int?
    /// Seconds of silence after which a write starts a new segment; nil joins every
    /// adjacent write to one stream.
    public let splitAfter: TimeInterval?

    /// What dates the segments: the system's wall clock unless injected.
    public let clock: WallClock
    private let lock = NSLock()
    private var storage: [Segment] = []
    private var count = 0
    private var droppedCount = 0

    public init(
        limit: Int? = nil,
        splitAfter: TimeInterval? = nil,
        clock: WallClock = .system
    ) {
        precondition(limit.map { $0 > 0 } ?? true, "A TextBuffer limit must be positive.")
        precondition(splitAfter.map { $0 >= 0 } ?? true, "A TextBuffer splitAfter must not be negative.")
        self.limit = limit
        self.splitAfter = splitAfter
        self.clock = clock
    }

    public var sink: TextSink {
        .collecting(into: self)
    }

    public func append(
        _ text: String,
        to stream: TextStream = .output
    ) {
        guard !text.isEmpty else { return }
        lock.lock()
        defer { lock.unlock() }
        // Read under the lock, so segment times follow the order of the writes.
        let time = Date(clock.now)
        if let last = storage.indices.last,
           storage[last].stream == stream,
           splitAfter.map({ time.timeIntervalSince(storage[last].end) <= $0 }) ?? true {
            storage[last].text += text
            storage[last].end = time
        } else {
            storage.append(.init(stream: stream, text: text, start: time, end: time))
        }
        count += text.count
        trim()
    }

    public var segments: [Segment] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    /// Characters dropped to stay within `limit`.
    public var dropped: Int {
        lock.lock()
        defer { lock.unlock() }
        return droppedCount
    }

    public var isEmpty: Bool {
        lock.lock()
        defer { lock.unlock() }
        return storage.isEmpty
    }

    /// One stream's text, or both in the order they were written.
    public func text(
        of stream: TextStream? = nil
    ) -> String {
        segments
            .filter { stream == nil || $0.stream == stream }
            .map(\.text)
            .joined()
    }

    /// The last `characters` of `text(of:)`.
    public func tail(
        _ characters: Int,
        of stream: TextStream? = nil
    ) -> String {
        String(text(of: stream).suffix(max(0, characters)))
    }

    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        storage.removeAll()
        count = 0
        droppedCount = 0
    }

    private func trim() {
        guard let limit else { return }
        while count > limit, !storage.isEmpty {
            let excess = count - limit
            let first = storage[0].text.count
            if first <= excess {
                storage.removeFirst()
                count -= first
                droppedCount += first
            } else {
                storage[0].text.removeFirst(excess)
                count -= excess
                droppedCount += excess
            }
        }
    }
}
