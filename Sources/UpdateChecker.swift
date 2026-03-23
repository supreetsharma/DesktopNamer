import Foundation
import AppKit

@Observable
final class UpdateChecker {
    var updateAvailable = false
    var latestVersion: String?
    var downloadURL: String?
    var isChecking = false

    private let repo = "supreetsharma/DesktopNamer"
    private let currentVersion: String

    init() {
        currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0"
    }

    func checkForUpdates(silent: Bool = false) {
        guard !isChecking else { return }
        isChecking = true

        let url = URL(string: "https://api.github.com/repos/\(repo)/releases/latest")!
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isChecking = false

                guard let data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let tagName = json["tag_name"] as? String else {
                    if !silent {
                        self.showAlert(
                            title: "Update Check Failed",
                            message: "Could not reach GitHub. Please check your internet connection and try again."
                        )
                    }
                    return
                }

                // Strip leading "v" from tag (e.g., "v2.1.0" → "2.1.0")
                let remoteVersion = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName

                // Find DMG asset URL
                if let assets = json["assets"] as? [[String: Any]] {
                    for asset in assets {
                        if let name = asset["name"] as? String, name.hasSuffix(".dmg"),
                           let url = asset["browser_download_url"] as? String {
                            self.downloadURL = url
                            break
                        }
                    }
                }

                if self.isNewer(remote: remoteVersion, current: self.currentVersion) {
                    self.updateAvailable = true
                    self.latestVersion = remoteVersion
                    self.showUpdateAlert(newVersion: remoteVersion)
                } else if !silent {
                    self.showAlert(
                        title: "You're Up to Date",
                        message: "Desktop Namer \(self.currentVersion) is the latest version."
                    )
                }
            }
        }.resume()
    }

    private func isNewer(remote: String, current: String) -> Bool {
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

    private func showUpdateAlert(newVersion: String) {
        let alert = NSAlert()
        alert.messageText = "Update Available"
        alert.informativeText = "Desktop Namer \(newVersion) is available. You're currently on \(currentVersion)."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Download")
        alert.addButton(withTitle: "Later")

        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let urlStr = downloadURL, let url = URL(string: urlStr) {
                NSWorkspace.shared.open(url)
            } else {
                NSWorkspace.shared.open(URL(string: "https://github.com/\(repo)/releases/latest")!)
            }
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}
