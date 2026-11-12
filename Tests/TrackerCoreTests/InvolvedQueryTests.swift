import Foundation
import Testing
@testable import TrackerCore

@Suite struct InvolvedQueryTests {
    static let t0 = Date(timeIntervalSince1970: 1_700_000_000)
    static let t1 = t0.addingTimeInterval(60)

    func details(timeline: String = "", threads: String = "") throws -> InvolvedDetails {
        let json = """
        {"data": {"nodes": [null, {"id": "PR_1", "timelineItems": {"nodes": [\(timeline)]}, "reviewThreads": {"nodes": [\(threads)]}}]}}
        """
        return try #require(try InvolvedQuery.decode(Data(json.utf8), viewer: "joe")["PR_1"])
    }

    @Test func aMentionStandsUntilICommentOrReview() throws {
        let mention = #"{"__typename": "MentionedEvent", "createdAt": "2026-11-01T10:00:00Z", "actor": {"login": "joe"}}"#
        let theirMention = #"{"__typename": "MentionedEvent", "createdAt": "2026-11-01T12:00:00Z", "actor": {"login": "bob"}}"#
        let theirComment = #"{"__typename": "IssueComment", "createdAt": "2026-11-01T11:00:00Z", "author": {"login": "alice"}}"#
        let myComment = #"{"__typename": "IssueComment", "createdAt": "2026-11-01T11:00:00Z", "author": {"login": "joe"}}"#
        let myReview = #"{"__typename": "PullRequestReview", "createdAt": "2026-11-01T11:00:00Z", "author": {"login": "joe"}}"#
        let myEarlierReview = #"{"__typename": "PullRequestReview", "createdAt": "2026-11-01T09:00:00Z", "author": {"login": "joe"}}"#
        let at = ISO8601DateFormatter().date(from: "2026-11-01T10:00:00Z")

        #expect(try details().mentionedAt == nil)
        #expect(try details(timeline: "\(myEarlierReview), \(mention), \(theirComment), \(theirMention)").mentionedAt == at)
        #expect(try details(timeline: "\(mention), \(myComment)").mentionedAt == nil)
        #expect(try details(timeline: "\(mention), \(myReview)").mentionedAt == nil)
    }

    @Test func countsOpenThreadsIBeganWhereAnotherPersonSpokeLast() throws {
        func thread(resolved: Bool = false, first: String, last: String, lastType: String = "User", reacted: Bool = false) -> String {
            """
            {"isResolved": \(resolved), "first": {"nodes": [{"author": {"login": "\(first)"}}]}, "last": {"nodes": [{"author": {"__typename": "\(lastType)", "login": "\(last)"}, "reactionGroups": [{"viewerHasReacted": \(reacted)}]}]}}
            """
        }
        let threads = [
            thread(first: "joe", last: "alice"),
            thread(first: "joe", last: "bob"),
            thread(first: "joe", last: "joe"),
            thread(resolved: true, first: "joe", last: "alice"),
            thread(first: "bob", last: "alice"),
            thread(first: "joe", last: "copilot", lastType: "Bot"),
            thread(first: "joe", last: "alice", reacted: true),
            #"{"isResolved": false, "first": {"nodes": []}, "last": {"nodes": []}}"#,
        ]
        #expect(try details(threads: threads.joined(separator: ",")).unansweredThreadCount == 2)
    }

    @Test func onlyNewAndUpdatedInvolvedPullRequestsNeedDetails() {
        var updated = PullRequest.fixture(2, author: "alice")
        updated.updatedAt = Self.t1
        let previous = Snapshot.fixture(involved: [.fixture(1, author: "alice"), .fixture(2, author: "alice")])
        let overview = Snapshot.fixture(authored: [.fixture(9)], involved: [.fixture(1, author: "alice"), updated, .fixture(3, author: "alice")])
        #expect(overview.involvedIDsNeedingDetails(since: previous) == ["acme/widgets#2", "acme/widgets#3"])
    }

    @Test func anInvolvedPullRequestWithAWaitingThreadNeedsDetailsEveryTime() {
        let snapshot = Snapshot.fixture(involved: [.fixture(1, author: "alice"), .fixture(2, author: "alice", unansweredThreads: 1)])
        #expect(snapshot.involvedIDsNeedingDetails(since: snapshot) == ["acme/widgets#2"])
    }

    @Test func fillsInFetchedDetailsAndKeepsTheRest() {
        let known = PullRequest.fixture(1, author: "alice", unansweredThreads: 1, mentionedAt: Self.t0)
        let previous = Snapshot.fixture(involved: [known])
        let overview = Snapshot.fixture(involved: [.fixture(1, author: "alice"), .fixture(2, author: "alice")])
        let filled = overview.withInvolvedDetails(["acme/widgets#2": InvolvedDetails(unansweredThreadCount: 3, mentionedAt: Self.t1)], reusing: previous)
        #expect(filled.involved.map(\.unansweredThreadCount) == [1, 3])
        #expect(filled.involved.map(\.mentionedAt) == [Self.t0, Self.t1])
    }
}
