import Foundation
import Testing
@testable import TrackerCore

@Suite struct DetailsQueryTests {
    @Test func decodesReviewsFromPeopleAndBots() throws {
        let reviews = try #require(try DetailsQuery.decode(Data(response.utf8), viewer: "joe")["PR_1"]).reviews
        #expect(reviews.map(\.id) == ["R_1", "R_2", "R_3"])
        #expect(reviews.map(\.state) == [.changesRequested, .commented, .pending])
        #expect(reviews.map(\.isBot) == [false, true, false])
        #expect(reviews.map(\.author) == ["alice", "copilot-pull-request-reviewer", "ghost"])
        #expect(reviews.map(\.commentCount) == [2, 3, 0])
        #expect(reviews[2].submittedAt == nil)
    }

    @Test func waitingSinceIsTheOldestRequestStillOpen() throws {
        // alice was asked twice and platform once. bob was asked earliest but is no longer requested.
        let details = try #require(try DetailsQuery.decode(Data(response.utf8), viewer: "joe")["PR_1"])
        #expect(details.waitingSince == ISO8601DateFormatter().date(from: "2026-10-30T12:00:00Z"))
    }

    @Test func lastCommentAtIgnoresBots() throws {
        let details = try #require(try DetailsQuery.decode(Data(response.utf8), viewer: "joe")["PR_1"])
        #expect(details.lastCommentAt == ISO8601DateFormatter().date(from: "2026-11-01T08:30:00Z"))
    }

    @Test func countsOpenThreadsWhereAnotherPersonSpokeLastWithoutMyReaction() throws {
        // Of six threads: alice and a deleted user wait on joe; bob has joe's reaction; one is resolved; one ends with joe; one ends with a bot.
        let details = try #require(try DetailsQuery.decode(Data(response.utf8), viewer: "joe")["PR_1"])
        #expect(details.unansweredThreadCount == 2)
    }

    @Test func skipsNodesThatAreMissingAndToleratesEmptyOnes() throws {
        let json = """
        {"data": {"nodes": [null, {
          "id": "PR_2",
          "reviewRequests": {"nodes": [{"requestedReviewer": null}]},
          "timelineItems": {"nodes": [{"createdAt": "2026-11-01T08:00:00Z", "requestedReviewer": null}, {}]},
          "comments": {"nodes": []},
          "reviews": {"nodes": []},
          "reviewThreads": {"nodes": [{"isResolved": false, "comments": {"nodes": []}}]}
        }]}}
        """
        let details = try DetailsQuery.decode(Data(json.utf8), viewer: "joe")
        #expect(details == ["PR_2": PullRequestDetails(reviews: [], unansweredThreadCount: 0, waitingSince: nil, lastCommentAt: nil)])
    }

    // MARK: Which details to fetch, and how they are filled in

    static let t0 = Date(timeIntervalSince1970: 1_700_000_000)
    static let t1 = t0.addingTimeInterval(60)

    @Test func everyPullRequestOfMineNeedsDetailsTheFirstTime() {
        let overview = Snapshot.fixture(authored: [.fixture(1), .fixture(2)], reviewRequested: [.fixture(3, author: "alice")])
        #expect(overview.idsNeedingDetails(since: nil) == ["acme/widgets#1", "acme/widgets#2"])
    }

    @Test func onlyNewAndUpdatedPullRequestsNeedDetails() {
        let previous = Snapshot.fixture(authored: [.fixture(1), .fixture(2)])
        var updated = PullRequest.fixture(2)
        updated.updatedAt = Self.t1
        let overview = Snapshot.fixture(authored: [.fixture(1), updated, .fixture(4)])
        #expect(overview.idsNeedingDetails(since: previous) == ["acme/widgets#2", "acme/widgets#4"])
    }

    @Test func aPullRequestWithAWaitingThreadNeedsDetailsEveryTime() {
        // A reaction does not change updatedAt, so this is the only way to see one.
        let snapshot = Snapshot.fixture(authored: [.fixture(1), .fixture(2, unansweredThreads: 1)])
        #expect(snapshot.idsNeedingDetails(since: snapshot) == ["acme/widgets#2"])
    }

    @Test func nothingNeedsDetailsWhenNothingChanged() {
        let snapshot = Snapshot.fixture(authored: [.fixture(1), .fixture(2)])
        #expect(snapshot.idsNeedingDetails(since: snapshot).isEmpty)
    }

    @Test func fetchedDetailsWinAndTheRestComeFromThePreviousSnapshot() {
        let oldReview = Review.fixture("r-old")
        let newReview = Review.fixture("r-new")
        let previous = Snapshot.fixture(authored: [
            .fixture(1, waitingSince: Self.t0, reviews: [oldReview], unansweredThreads: 2, lastCommentAt: Self.t0),
            .fixture(2, reviews: [oldReview]),
        ])
        // The overview knows the pull requests but none of their details, and its other fields are newer.
        let overview = Snapshot.fixture(authored: [.fixture(1, checks: .failing), .fixture(2), .fixture(3)])
        let fetched = ["acme/widgets#2": PullRequestDetails(reviews: [newReview], unansweredThreadCount: 1, waitingSince: Self.t1, lastCommentAt: Self.t1)]

        let filled = overview.withDetails(fetched, reusing: previous)

        #expect(filled.authored[0] == .fixture(1, checks: .failing, waitingSince: Self.t0, reviews: [oldReview], unansweredThreads: 2, lastCommentAt: Self.t0))
        #expect(filled.authored[1] == .fixture(2, waitingSince: Self.t1, reviews: [newReview], unansweredThreads: 1, lastCommentAt: Self.t1))
        #expect(filled.authored[2] == .fixture(3))
    }

    let response = """
    {"data": {"nodes": [{
      "id": "PR_1",
      "reviewRequests": {"nodes": [{"requestedReviewer": {"login": "alice"}}, {"requestedReviewer": {"slug": "platform"}}]},
      "timelineItems": {"nodes": [
        {"createdAt": "2026-10-29T12:00:00Z", "requestedReviewer": {"login": "bob"}},
        {"createdAt": "2026-10-29T13:00:00Z", "requestedReviewer": {"login": "alice"}},
        {"createdAt": "2026-10-30T12:00:00Z", "requestedReviewer": {"slug": "platform"}},
        {"createdAt": "2026-10-31T12:00:00Z", "requestedReviewer": {"login": "alice"}}
      ]},
      "comments": {"nodes": [
        {"createdAt": "2026-11-01T07:00:00Z", "author": {"__typename": "User", "login": "alice"}},
        {"createdAt": "2026-11-01T08:30:00Z", "author": null},
        {"createdAt": "2026-11-01T10:00:00Z", "author": {"__typename": "Bot", "login": "github-actions"}}
      ]},
      "reviewThreads": {"nodes": [
        {"isResolved": false, "comments": {"nodes": [{"author": {"__typename": "User", "login": "alice"}, "reactionGroups": [{"viewerHasReacted": false}]}]}},
        {"isResolved": false, "comments": {"nodes": [{"author": {"__typename": "User", "login": "bob"}, "reactionGroups": [{"viewerHasReacted": true}]}]}},
        {"isResolved": false, "comments": {"nodes": [{"author": null}]}},
        {"isResolved": true, "comments": {"nodes": [{"author": {"__typename": "User", "login": "alice"}}]}},
        {"isResolved": false, "comments": {"nodes": [{"author": {"__typename": "User", "login": "joe"}}]}},
        {"isResolved": false, "comments": {"nodes": [{"author": {"__typename": "Bot", "login": "copilot-pull-request-reviewer"}}]}}
      ]},
      "reviews": {"nodes": [
        {"id": "R_1", "state": "CHANGES_REQUESTED", "submittedAt": "2026-11-01T09:00:00Z", "url": "https://github.com/acme/widgets/pull/42#pullrequestreview-1", "author": {"__typename": "User", "login": "alice"}, "comments": {"totalCount": 2}},
        {"id": "R_2", "state": "COMMENTED", "submittedAt": "2026-11-01T09:30:00Z", "url": "https://github.com/acme/widgets/pull/42#pullrequestreview-2", "author": {"__typename": "Bot", "login": "copilot-pull-request-reviewer"}, "comments": {"totalCount": 3}},
        {"id": "R_3", "state": "PENDING", "submittedAt": null, "url": "https://github.com/acme/widgets/pull/42#pullrequestreview-3", "author": null, "comments": {"totalCount": 0}}
      ]}
    }]}}
    """
}
