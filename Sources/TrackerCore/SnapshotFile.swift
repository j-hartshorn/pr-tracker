import Foundation

/// The last snapshot on disk, so a restart does not notify about everything again.
public struct SnapshotFile: Sendable {
    private static let formatVersion = 2

    public var url: URL

    public init(url: URL) {
        self.url = url
    }

    public static var applicationSupport: SnapshotFile {
        SnapshotFile(url: URL.applicationSupportDirectory.appending(path: "gh-tracker/snapshot.json"))
    }

    /// Nil when there is no file or it was written by an incompatible version. Both mean "start from a new baseline".
    public func load() -> Snapshot? {
        guard let data = try? Data(contentsOf: url),
              let box = try? JSONDecoder().decode(Box.self, from: data),
              box.version == Self.formatVersion else { return nil }
        return box.snapshot
    }

    public func save(_ snapshot: Snapshot) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(Box(version: Self.formatVersion, snapshot: snapshot)).write(to: url, options: .atomic)
    }

    private struct Box: Codable {
        var version: Int
        var snapshot: Snapshot
    }
}
