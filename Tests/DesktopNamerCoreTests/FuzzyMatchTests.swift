import Foundation
import DesktopNamerCore

func runFuzzyMatchTests(_ t: TestRun) {
    t.suite("FuzzyMatch") {
        t.expect(fuzzyMatch(query: "", candidate: "Code"), "empty query matches everything")
        t.expect(fuzzyMatch(query: "code", candidate: "Code"), "case-insensitive exact match")
        t.expect(fuzzyMatch(query: "cd", candidate: "Code"), "subsequence matches")
        t.expect(fuzzyMatch(query: "ml", candidate: "Mail"), "sparse subsequence matches")
        t.expect(!fuzzyMatch(query: "dc", candidate: "Code"), "out-of-order does not match")
        t.expect(!fuzzyMatch(query: "codex", candidate: "Code"), "query longer than candidate fails")
        t.expect(!fuzzyMatch(query: "a", candidate: ""), "empty candidate fails a non-empty query")
        t.expect(fuzzyMatch(query: "désk", candidate: "DÉSK 1"), "case folding handles accents")
    }
}
