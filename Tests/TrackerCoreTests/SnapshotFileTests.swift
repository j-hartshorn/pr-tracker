import Foundation
import Testing
@testable import TrackerCore

@Suite struct SnapshotFileTests {
    let file = SnapshotFile(url: FileManager.default.temporaryDirectory.appending(path: "gh-tracker-tests-\(UUID().uuidString)/snapshot.json"))

    @Test func loadsWhatItSaved() throws {
        let snapshot = Snapshot.fixture(
            authored: [.fixture(1, reviews: [.fixture("r1", .approved)])],
            reviewRequested: [.fixture(2, author: "alice")]
        )
        try file.save(snapshot)
        #expect(file.load() == snapshot)
    }

    @Test func loadsNothingWhenThereIsNoFile() {
        #expect(file.load() == nil)
    }

    @Test func loadsNothingFromAnIncompatibleFile() throws {
        try FileManager.default.createDirectory(at: file.url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(#"{"viewer": 1}"#.utf8).write(to: file.url)
        #expect(file.load() == nil)
    }

    @Test func loadsNothingFromAnUnversionedOrOlderVersionSnapshot() throws {
        try FileManager.default.createDirectory(at: file.url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let snapshot = Snapshot.fixture(authored: [.fixture(1)])
        try JSONEncoder().encode(snapshot).write(to: file.url)
        #expect(file.load() == nil)

        try Data(#"{"version": 1, "snapshot": {}}"#.utf8).write(to: file.url)
        #expect(file.load() == nil)
    }
}
