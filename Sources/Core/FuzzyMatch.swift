import Foundation

/// Case-insensitive subsequence match: every character of `query` must appear
/// in `candidate` in order (not necessarily contiguously). An empty query
/// matches everything.
public func fuzzyMatch(query: String, candidate: String) -> Bool {
    if query.isEmpty { return true }
    var remaining = query.lowercased().makeIterator()
    var next = remaining.next()
    for character in candidate.lowercased() {
        if let wanted = next, wanted == character {
            next = remaining.next()
        }
    }
    return next == nil
}
