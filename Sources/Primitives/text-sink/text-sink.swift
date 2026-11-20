import Foundation

/// Which stream a piece of text belongs to. Sinks keep the identity even when they display
/// both streams together, so diagnostics never pass for output.
public enum TextStream: String, Sendable, Hashable, CaseIterable, Codable {
    case output
    case error
}

/// Where text goes: the terminal, a buffer, nowhere, or several of those at once. Writes are
/// synchronous and keep their order, so a sink can stand in for `print` anywhere: the CLI
/// passes `.standard`, a caller that returns the text (an Agentic tool) passes a buffer's sink.
///
///     let buffer = TextBuffer(limit: 64_000)
///     let sink = TextSink.standard.tee(.collecting(into: buffer))
///     sink.line("Running t_name…")
///     sink.write(chunk)                    // process bytes, decoded as UTF-8
///     sink.line("failed", to: .error)
public struct TextSink: Sendable {
    private let receive: @Sendable (TextStream, String) -> Void

    public init(
        _ receive: @escaping @Sendable (TextStream, String) -> Void
    ) {
        self.receive = receive
    }

    public init(
        output: @escaping @Sendable (String) -> Void,
        error: @escaping @Sendable (String) -> Void
    ) {
        self.init { stream, text in
            switch stream {
            case .output: output(text)
            case .error: error(text)
            }
        }
    }

    public func write(
        _ text: String,
        to stream: TextStream = .output
    ) {
        guard !text.isEmpty else { return }
        receive(stream, text)
    }

    public func line(
        _ text: String = "",
        to stream: TextStream = .output
    ) {
        receive(stream, text + "\n")
    }

    /// Bytes as UTF-8; invalid sequences become replacement characters.
    public func write(
        _ data: Data,
        to stream: TextStream = .output
    ) {
        write(String(decoding: data, as: UTF8.self), to: stream)
    }
}

public extension TextSink {
    /// Standard output and standard error, flushed after each write so the text keeps its
    /// place among the process's own `print`s and a child's terminal output.
    static let standard = TextSink { stream, text in
        switch stream {
        case .output:
            fputs(text, stdout)
            fflush(stdout)
        case .error:
            fputs(text, stderr)
        }
    }

    static let discard = TextSink { _, _ in }

    static func collecting(
        into buffer: TextBuffer
    ) -> TextSink {
        TextSink { stream, text in
            buffer.append(text, to: stream)
        }
    }

    /// Every write goes to each sink, in order.
    static func fanout(
        _ sinks: [TextSink]
    ) -> TextSink {
        TextSink { stream, text in
            for sink in sinks {
                sink.receive(stream, text)
            }
        }
    }

    func tee(
        _ other: TextSink
    ) -> TextSink {
        .fanout([self, other])
    }

    /// Both streams into one: for a display that shows them together.
    func merged(
        into stream: TextStream = .output
    ) -> TextSink {
        TextSink { _, text in
            receive(stream, text)
        }
    }

    /// Only one stream; the other is dropped.
    func only(
        _ stream: TextStream
    ) -> TextSink {
        TextSink { written, text in
            guard written == stream else { return }
            receive(written, text)
        }
    }

    /// Text rewritten before it arrives (stripping escapes, redacting). Writes that come
    /// out empty are dropped.
    func map(
        _ transform: @escaping @Sendable (TextStream, String) -> String
    ) -> TextSink {
        TextSink { stream, text in
            let mapped = transform(stream, text)
            guard !mapped.isEmpty else { return }
            receive(stream, mapped)
        }
    }
}
