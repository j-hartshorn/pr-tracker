import Foundation
import Testing
@testable import TrackerCore

@Suite struct StatusTests {
    func status(_ pr: PullRequest, in snapshot: Snapshot? = nil) -> Status {
        (snapshot ?? .fixture(authored: [pr])).status(of: pr)
    }

    @Test func failingWhenChecksFail() {
        #expect(status(.fixture(checks: .failing, reviewDecision: .approved)) == .failing)
    }

    @Test func failingWhenThereIsAConflict() {
        #expect(status(.fixture(mergeability: .conflicting, reviewDecision: .approved)) == .failing)
    }

    @Test func failingBeatsChangesRequested() {
        #expect(status(.fixture(checks: .failing, reviewDecision: .changesRequested)) == .failing)
    }

    @Test func draftsCanFail() {
        #expect(status(.fixture(isDraft: true, checks: .failing)) == .failing)
    }

    @Test func attentionWhenChangesAreRequested() {
        #expect(status(.fixture(reviewDecision: .changesRequested)) == .attention)
    }

    @Test func attentionWhenMyReviewIsRequested() {
        let theirs = PullRequest.fixture(2, author: "alice", mergeability: .conflicting, checks: .failing)
        #expect(status(theirs, in: .fixture(reviewRequested: [theirs])) == .attention)
    }

    @Test func readyWhenApprovedGreenAndClean() {
        #expect(status(.fixture(reviewDecision: .approved)) == .ready)
    }

    @Test func readyWithoutAnyChecks() {
        #expect(status(.fixture(checks: .none, reviewDecision: .approved)) == .ready)
    }

    @Test(arguments: [
        PullRequest.fixture(reviewDecision: .reviewRequired),
        .fixture(reviewDecision: nil),
        .fixture(isDraft: true, reviewDecision: .approved),
        .fixture(checks: .pending, reviewDecision: .approved),
        .fixture(mergeability: .unknown, reviewDecision: .approved),
    ])
    func waitingWhenSomethingElseHasToHappenFirst(pr: PullRequest) {
        #expect(status(pr) == .waiting)
    }

    @Test func waitingWhenApprovedButStackedOnAnOpenPullRequest() {
        let bottom = PullRequest.fixture(1, head: "bottom", reviewDecision: .approved)
        let top = PullRequest.fixture(2, base: "bottom", reviewDecision: .approved)
        let snapshot = Snapshot.fixture(authored: [bottom, top])
        #expect(snapshot.status(of: bottom) == .ready)
        #expect(snapshot.status(of: top) == .waiting)
    }

    @Test func approvalFallsBackToEachPersonsLatestOpinion() {
        let approved = PullRequest.fixture(reviews: [.fixture("r1", by: "alice", .changesRequested), .fixture("r2", by: "alice", .approved), .fixture("r3", by: "alice", .commented)])
        #expect(approved.approval == .approved)
        #expect(status(approved) == .ready)

        let blocked = PullRequest.fixture(reviews: [.fixture("r1", by: "alice", .approved), .fixture("r2", by: "bob", .changesRequested)])
        #expect(blocked.approval == .changesRequested)

        let botOnly = PullRequest.fixture(reviews: [.fixture("r1", by: "copilot", isBot: true, .approved), .fixture("r2", by: "alice", .dismissed)])
        #expect(botOnly.approval == nil)
    }

    @Test func reviewDecisionBeatsTheFallback() {
        let pr = PullRequest.fixture(reviewDecision: .reviewRequired, reviews: [.fixture("r1", by: "alice", .approved)])
        #expect(pr.approval == .reviewRequired)
    }

    @Test func mostUrgentStatusIsTheWorstAcrossEverything() {
        let theirs = PullRequest.fixture(9, author: "alice")
        #expect(Snapshot.fixture().mostUrgentStatus == .waiting)
        #expect(Snapshot.fixture(authored: [.fixture(1)]).mostUrgentStatus == .waiting)
        #expect(Snapshot.fixture(authored: [.fixture(1), .fixture(2, reviewDecision: .approved)]).mostUrgentStatus == .ready)
        #expect(Snapshot.fixture(authored: [.fixture(2, reviewDecision: .approved)], reviewRequested: [theirs]).mostUrgentStatus == .attention)
        #expect(Snapshot.fixture(authored: [.fixture(1, checks: .failing)], reviewRequested: [theirs]).mostUrgentStatus == .failing)
    }
}
