import Primitives

@main
public enum PrimitivesCasingTests {
    static func expect(
        _ actual: String,
        _ expected: String,
        name: String
    ) {
        guard actual == expected else {
            fatalError("\(name): expected '\(expected)', got '\(actual)'")
        }
    }

    public static func main() {
        expect(Case.preserve(original: "optimizer", replacement: "analyzer"), "analyzer", name: "lower")
        expect(Case.preserve(original: "Optimizer", replacement: "analyzer"), "Analyzer", name: "capitalized")
        expect(Case.preserve(original: "OPTIMIZER", replacement: "analyzer"), "ANALYZER", name: "upper")
        expect(Case.preserve(original: "my_optimizer", replacement: "someAnalyzer"), "some_analyzer", name: "snake")
        expect(Case.preserve(original: "myOptimizer", replacement: "some_analyzer"), "someAnalyzer", name: "camel")
        expect(Case.preserve(original: "MyOptimizer", replacement: "some_analyzer"), "SomeAnalyzer", name: "pascal")
        expect(Case.preserve(original: "MY_OPTIMIZER", replacement: "someAnalyzer"), "SOME_ANALYZER", name: "screaming snake")
        expect(Case.preserve(original: "my-optimizer", replacement: "someAnalyzer"), "some-analyzer", name: "kebab")
        expect(Case.preserve(original: "my.optimizer", replacement: "someAnalyzer"), "some.analyzer", name: "dot")
        expect(Case.preserve(original: "OptimiZER", replacement: "analyzer"), "analyzer", name: "mixed is conservative")
        expect(Case.preserve(original: "123", replacement: "analyzer"), "analyzer", name: "uncased")
        expect(Case.preserve(original: "École", replacement: "université"), "Université", name: "unicode capitalized")
        expect(Case.substitute("optimizer Optimizer OPTIMIZER", matching: "optimizer", with: "analyzer"), "analyzer Analyzer ANALYZER", name: "basic case")
        expect(Case.substitute("my_optimizer myOptimizer MyOptimizer MY_OPTIMIZER", matching: "optimizer", with: "analyzer"), "my_analyzer myAnalyzer MyAnalyzer MY_ANALYZER", name: "inside identifiers")
        expect(Case.substitute("Optimizer Optimizer", matching: "optimizer", with: "analyzer", replacingAll: false), "Analyzer Optimizer", name: "first only")
        expect(Case.substitute("file.name FILE.NAME", matching: "file.name", with: "other.file"), "other.file OTHER.FILE", name: "literal punctuation")
        expect(Case.substitute("Optimizer optimizer", matching: "o", with: "a"), "Aptimizer aptimizer", name: "single character case")
        expect(Case.substitute("foo", matching: "", with: "bar"), "foo", name: "empty pattern")
        expect(Case.substitute("foo", matching: "none", with: "bar"), "foo", name: "no match")
        expect(Case.substitute("foofoo", matching: "foo", with: "bar"), "barbar", name: "adjacent matches")
        print("Primitives casing tests passed")
    }
}
