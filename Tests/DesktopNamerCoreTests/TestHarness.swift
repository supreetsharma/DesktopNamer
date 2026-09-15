import Foundation

/// Minimal test harness: XCTest is unavailable under Command Line Tools, so
/// tests are plain functions run by this executable. Exit code 0 = all passed.
final class TestRun {
    static let shared = TestRun()

    private(set) var checks = 0
    private(set) var failures = 0
    private var currentSuite = ""

    func suite(_ name: String, _ body: () -> Void) {
        currentSuite = name
        print("== \(name)")
        body()
    }

    func expect(_ condition: Bool, _ label: String,
                file: StaticString = #filePath, line: UInt = #line) {
        checks += 1
        if !condition {
            failures += 1
            print("FAIL [\(currentSuite)] \(label) at \(file):\(line)")
        }
    }

    func expectEqual<T: Equatable>(_ actual: T, _ expected: T, _ label: String,
                                   file: StaticString = #filePath, line: UInt = #line) {
        checks += 1
        if actual != expected {
            failures += 1
            print("FAIL [\(currentSuite)] \(label): got \(actual), expected \(expected) at \(file):\(line)")
        }
    }

    func finish() -> Never {
        if failures == 0 {
            print("PASSED: \(checks) checks")
            exit(0)
        } else {
            print("FAILED: \(failures) of \(checks) checks")
            exit(1)
        }
    }
}
