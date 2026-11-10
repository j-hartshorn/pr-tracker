import Foundation
import Testing
@testable import TrackerCore

@Suite struct OverviewQueryTests {
    static let fetchedAt = Date(timeIntervalSince1970: 1_700_000_000)

    @Test func decodesAuthoredPullRequest() throws {
        let snapshot = try OverviewQuery.decode(Data(response.utf8), fetchedAt: Self.fetchedAt)
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

    @Test func leavesTheDetailsEmpty() throws {
        let pr = try OverviewQuery.decode(Data(response.utf8), fetchedAt: Self.fetchedAt).authored[0]
        #expect(pr.reviews.isEmpty)
        #expect(pr.unansweredThreadCount == 0)
        #expect(pr.waitingSince == nil)
    }

    @Test(arguments: [
        ("SUCCESS", Checks.passing), ("FAILURE", .failing), ("ERROR", .failing), ("PENDING", .pending), ("EXPECTED", .pending),
    ])
    func mapsCheckStates(state: String, expected: Checks) throws {
        let json = response.replacingOccurrences(of: "\"state\": \"FAILURE\"", with: "\"state\": \"\(state)\"")
        #expect(try OverviewQuery.decode(Data(json.utf8), fetchedAt: Self.fetchedAt).authored[0].checks == expected)
    }

    @Test func treatsMissingOptionalFieldsAsUnknown() throws {
        let json = """
        {"data": {"viewer": {"login": "joe"}, "authored": {"nodes": [null, {
          "id": "PR_2", "number": 7, "title": "From a deleted fork", "url": "https://github.com/acme/widgets/pull/7",
          "isDraft": true, "updatedAt": "2026-11-01T10:00:00Z", "author": null,
          "repository": {"nameWithOwner": "acme/widgets"}, "headRepository": null,
          "baseRefName": "main", "headRefName": "patch-1", "mergeable": "UNKNOWN", "reviewDecision": null,
          "commits": {"nodes": [{"commit": {"committedDate": "2026-11-01T08:00:00Z", "statusCheckRollup": null}}]},
          "reviewRequests": {"nodes": [{"requestedReviewer": null}]}
        }]}, "reviewRequested": {"nodes": []}}, "errors": [{"message": "Resource protected by organization SAML enforcement."}]}
        """
        let pr = try #require(try OverviewQuery.decode(Data(json.utf8), fetchedAt: Self.fetchedAt).authored.first)
        #expect(pr.author == "ghost")
        #expect(pr.isDraft)
        #expect(pr.isFromFork)
        #expect(pr.mergeability == .unknown)
        #expect(pr.checks == .none)
        #expect(pr.reviewDecision == nil)
        #expect(pr.requestedReviewers.isEmpty)
    }

    @Test func throwsTheGraphQLErrorWhenThereIsNoData() {
        let json = #"{"data": null, "errors": [{"message": "Bad credentials"}]}"#
        #expect(throws: GitHubError.graphQL("Bad credentials")) {
            try OverviewQuery.decode(Data(json.utf8), fetchedAt: Self.fetchedAt)
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
        "reviewRequests": {"nodes": [{"requestedReviewer": {"login": "alice"}}, {"requestedReviewer": {"slug": "platform"}}]}
      }]},
      "reviewRequested": {"nodes": []}
    }}
    """
}
