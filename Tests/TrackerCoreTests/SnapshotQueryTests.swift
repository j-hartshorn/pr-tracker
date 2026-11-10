import Foundation
import Testing
@testable import TrackerCore

@Suite struct SnapshotQueryTests {
    static let fetchedAt = Date(timeIntervalSince1970: 1_700_000_000)

    @Test func decodesAuthoredPullRequest() throws {
        let snapshot = try SnapshotQuery.decode(Data(response.utf8), fetchedAt: Self.fetchedAt)
        #expect(snapshot.viewer == "joe")
        #expect(snapshot.fetchedAt == Self.fetchedAt)
        #expect(snapshot.reviewRequested.isEmpty)

        let pr = try #require(snapshot.authored.first)
        #expect(snapshot.authored.count == 1)
        #expect(pr.id == "PR_1")
        #expect(pr.number == 42)
        #expect(pr.title == "Add the thing")
        #expect(pr.url.absoluteString == "https://github.com/acme/widgets/pull/42")
        #expect(pr.repository == "acme/widgets")
        #expect(pr.author == "joe")
        #expect(pr.isDraft == false)
        #expect(pr.baseRef == "main")
        #expect(pr.headRef == "joe/thing")
        #expect(pr.isFromFork == false)
        #expect(pr.mergeability == .conflicting)
        #expect(pr.checks == .failing)
        #expect(pr.reviewDecision == .changesRequested)
        #expect(pr.requestedReviewers == ["alice", "platform"])
        #expect(pr.updatedAt == ISO8601DateFormatter().date(from: "2026-11-01T10:00:00Z"))
        #expect(pr.lastCommitAt == ISO8601DateFormatter().date(from: "2026-11-01T08:00:00Z"))
    }

    @Test func waitingSinceIsTheOldestRequestStillOpen() throws {
        // alice was asked twice and platform once. bob was asked earliest but is no longer requested.
        let pr = try SnapshotQuery.decode(Data(response.utf8), fetchedAt: Self.fetchedAt).authored[0]
        #expect(pr.waitingSince == ISO8601DateFormatter().date(from: "2026-10-30T12:00:00Z"))
    }

    @Test func countsOpenThreadsWhereAnotherPersonSpokeLast() throws {
        // Of five threads, one is resolved, one ends with the author and one ends with a bot.
        let pr = try SnapshotQuery.decode(Data(response.utf8), fetchedAt: Self.fetchedAt).authored[0]
        #expect(pr.unansweredThreadCount == 2)
    }

    @Test func decodesReviewsFromPeopleAndBots() throws {
        let reviews = try SnapshotQuery.decode(Data(response.utf8), fetchedAt: Self.fetchedAt).authored[0].reviews
        #expect(reviews.map(\.id) == ["R_1", "R_2", "R_3"])
        #expect(reviews.map(\.state) == [.changesRequested, .commented, .pending])
        #expect(reviews.map(\.isBot) == [false, true, false])
        #expect(reviews.map(\.author) == ["alice", "copilot-pull-request-reviewer", "ghost"])
        #expect(reviews.map(\.commentCount) == [2, 3, 0])
        #expect(reviews[2].submittedAt == nil)
    }

    @Test(arguments: [
        ("SUCCESS", Checks.passing), ("FAILURE", .failing), ("ERROR", .failing), ("PENDING", .pending), ("EXPECTED", .pending),
    ])
    func mapsCheckStates(state: String, expected: Checks) throws {
        let json = response.replacingOccurrences(of: "\"state\": \"FAILURE\"", with: "\"state\": \"\(state)\"")
        #expect(try SnapshotQuery.decode(Data(json.utf8), fetchedAt: Self.fetchedAt).authored[0].checks == expected)
    }

    @Test func treatsMissingOptionalFieldsAsUnknown() throws {
        let json = """
        {"data": {"viewer": {"login": "joe"}, "authored": {"nodes": [null, {
          "id": "PR_2", "number": 7, "title": "From a deleted fork", "url": "https://github.com/acme/widgets/pull/7",
          "isDraft": true, "updatedAt": "2026-11-01T10:00:00Z", "author": null,
          "repository": {"nameWithOwner": "acme/widgets"}, "headRepository": null,
          "baseRefName": "main", "headRefName": "patch-1", "mergeable": "UNKNOWN", "reviewDecision": null,
          "commits": {"nodes": [{"commit": {"committedDate": "2026-11-01T08:00:00Z", "statusCheckRollup": null}}]},
          "reviewRequests": {"nodes": [{"requestedReviewer": null}]},
          "timelineItems": {"nodes": [{"createdAt": "2026-11-01T08:00:00Z", "requestedReviewer": null}, {}]},
          "reviews": {"nodes": []},
          "reviewThreads": {"nodes": [{"isResolved": false, "comments": {"nodes": []}}]}
        }]}, "reviewRequested": {"nodes": []}}, "errors": [{"message": "Resource protected by organization SAML enforcement."}]}
        """
        let pr = try #require(try SnapshotQuery.decode(Data(json.utf8), fetchedAt: Self.fetchedAt).authored.first)
        #expect(pr.author == "ghost")
        #expect(pr.isDraft)
        #expect(pr.isFromFork)
        #expect(pr.mergeability == .unknown)
        #expect(pr.checks == .none)
        #expect(pr.reviewDecision == nil)
        #expect(pr.requestedReviewers.isEmpty)
        #expect(pr.waitingSince == nil)
        #expect(pr.unansweredThreadCount == 0)
    }

    @Test func throwsTheGraphQLErrorWhenThereIsNoData() {
        let json = #"{"data": null, "errors": [{"message": "Bad credentials"}]}"#
        #expect(throws: GitHubError.graphQL("Bad credentials")) {
            try SnapshotQuery.decode(Data(json.utf8), fetchedAt: Self.fetchedAt)
        }
    }

    let response = """
    {"data": {
      "viewer": {"login": "joe"},
      "authored": {"nodes": [{
        "id": "PR_1", "number": 42, "title": "Add the thing", "url": "https://github.com/acme/widgets/pull/42",
        "isDraft": false, "updatedAt": "2026-11-01T10:00:00Z",
        "author": {"login": "joe"},
        "repository": {"nameWithOwner": "acme/widgets"},
        "headRepository": {"nameWithOwner": "acme/widgets"},
        "baseRefName": "main", "headRefName": "joe/thing",
        "mergeable": "CONFLICTING", "reviewDecision": "CHANGES_REQUESTED",
        "commits": {"nodes": [{"commit": {"committedDate": "2026-11-01T08:00:00Z", "statusCheckRollup": {"state": "FAILURE"}}}]},
        "reviewRequests": {"nodes": [{"requestedReviewer": {"login": "alice"}}, {"requestedReviewer": {"slug": "platform"}}]},
        "timelineItems": {"nodes": [
          {"createdAt": "2026-10-29T12:00:00Z", "requestedReviewer": {"login": "bob"}},
          {"createdAt": "2026-10-29T13:00:00Z", "requestedReviewer": {"login": "alice"}},
          {"createdAt": "2026-10-30T12:00:00Z", "requestedReviewer": {"slug": "platform"}},
          {"createdAt": "2026-10-31T12:00:00Z", "requestedReviewer": {"login": "alice"}}
        ]},
        "reviewThreads": {"nodes": [
          {"isResolved": false, "comments": {"nodes": [{"author": {"__typename": "User", "login": "alice"}}]}},
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
      }]},
      "reviewRequested": {"nodes": []}
    }}
    """
}
