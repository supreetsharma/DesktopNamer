import Foundation

/// Compares dotted version strings numerically, padding shorter versions with zeros.
/// Non-numeric segments are dropped by the Int conversion.
public func isVersionNewer(remote: String, current: String) -> Bool {
    let r = remote.split(separator: ".").compactMap { Int($0) }
    let c = current.split(separator: ".").compactMap { Int($0) }
    let maxLen = max(r.count, c.count)
    for i in 0..<maxLen {
        let rv = i < r.count ? r[i] : 0
        let cv = i < c.count ? c[i] : 0
        if rv > cv { return true }
        if rv < cv { return false }
    }
    return false
}
