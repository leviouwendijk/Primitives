import Foundation
import Primitives

func run_text_sink_tests() throws {
    let buffer = TextBuffer()
    let sink = buffer.sink
    sink.line("building")
    sink.write("warning\n", to: .error)
    sink.write(Data("done".utf8))
    sink.write("")
    try expect(buffer.text() == "building\nwarning\ndone", "both streams in written order")
    try expect(buffer.text(of: .output) == "building\ndone", "output alone")
    try expect(buffer.text(of: .error) == "warning\n", "error alone")
    try expect(buffer.segments.map(\.stream) == [.output, .error, .output], "adjacent writes join, streams alternate")
    try expect(buffer.tail(4) == "done", "tail")

    let bounded = TextBuffer(limit: 5)
    bounded.append("abc")
    bounded.append("def", to: .error)
    bounded.append("gh", to: .error)
    try expect(bounded.text() == "cdefgh".suffix(5).description, "keeps the newest characters")
    try expect(bounded.dropped == 3, "counts what it dropped")
    try expect(bounded.segments.map(\.stream) == [.error], "fully dropped segments go")

    let left = TextBuffer(), right = TextBuffer()
    let composed = left.sink.tee(right.sink.only(.error))
    composed.line("out")
    composed.line("err", to: .error)
    try expect(left.text() == "out\nerr\n", "tee reaches the first sink")
    try expect(right.text() == "err\n", "only keeps one stream")

    let merged = TextBuffer()
    merged.sink.merged().map { _, text in text.uppercased() }.line("x", to: .error)
    try expect(merged.text(of: .output) == "X\n", "merged into output, then mapped")
    try expect(merged.text(of: .error).isEmpty, "nothing left on error")

    let dropped = TextBuffer()
    dropped.sink.map { _, _ in "" }.line("gone")
    try expect(dropped.isEmpty, "a write mapped to nothing is dropped")

    let concurrent = TextBuffer()
    DispatchQueue.concurrentPerform(iterations: 200) { _ in concurrent.sink.write("a") }
    try expect(concurrent.text().count == 200, "concurrent writes are all kept")

    concurrent.clear()
    try expect(concurrent.isEmpty && concurrent.dropped == 0, "clear empties the buffer")
}
