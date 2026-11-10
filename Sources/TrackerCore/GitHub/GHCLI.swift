import Foundation

/// The token comes from the gh CLI so the app stores no credentials of its own.
public enum GHCLI {
    // Apps launched from Finder do not get the shell's PATH.
    private static let candidates = ["/opt/homebrew/bin/gh", "/usr/local/bin/gh", "/usr/bin/gh"]

    public static func authToken() throws -> String {
        guard let path = candidates.first(where: FileManager.default.isExecutableFile(atPath:)) else {
            throw GitHubError.ghNotFound
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = ["auth", "token"]
        let output = Pipe()
        let errors = Pipe()
        process.standardOutput = output
        process.standardError = errors
        try process.run()
        let token = String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        let detail = String(decoding: errors.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw GitHubError.ghFailed(detail.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return token.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
