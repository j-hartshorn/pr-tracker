import Foundation
import Testing
@testable import TrackerCore

@Suite struct EventsTests {
    @Test func firstSnapshotIsABaselineWithNoEvents() {
        let new = Snapshot.fixture(
            authored: [.fixture(1, mergeability: .conflicting, checks: .failing, reviews: [.fixture("r1", .approved)])],
            reviewRequested: [.fixture(2, author: "alice")]
        )
        #expect(new.events(since: nil).isEmpty)
    }

    @Test func unchangedSnapshotHasNoEvents() {
        let snapshot = Snapshot.fixture(
            authored: [.fixture(1, mergeability: .conflicting, checks: .failing, reviews: [.fixture("r1", .approved)])],
            reviewRequested: [.fixture(2, author: "alice")]
        )
        #expect(snapshot.events(since: snapshot).isEmpty)
    }

    @Test func reviewRequestedWhenAPullRequestNewlyNamesMe() {
        let theirs = PullRequest.fixture(2, author: "alice")
        let events = Snapshot.fixture(reviewRequested: [theirs]).events(since: .fixture())
        #expect(events == [Event(kind: .reviewRequested, pullRequest: theirs, url: theirs.url)])
        #expect(events[0].title == "alice requested your review")
        #expect(events[0].body == "acme/widgets #2: Change 2")
    }

    @Test func hidingDraftsDropsTheirEvents() {
        let draft = PullRequest.fixture(1, isDraft: true, checks: .failing)
        let ready = PullRequest.fixture(2, checks: .failing)
        let theirDraft = PullRequest.fixture(3, author: "alice", isDraft: true)
        let new = Snapshot.fixture(authored: [draft, ready], reviewRequested: [theirDraft])
        #expect(new.events(since: .fixture()).map(\.pullRequest.number) == [3, 1, 2])
        #expect(new.events(since: .fixture(), hidingDrafts: true).map(\.pullRequest.number) == [2])
    }

    @Test func mentionedWhenIAmNewlyTagged() {
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        let quiet = PullRequest.fixture(2, author: "alice")
        let tagged = PullRequest.fixture(2, author: "alice", mentionedAt: t0)
        let taggedAgain = PullRequest.fixture(2, author: "alice", mentionedAt: t0.addingTimeInterval(60))
        let events = Snapshot.fixture(involved: [tagged]).events(since: .fixture(involved: [quiet]))
        #expect(events == [Event(kind: .mentioned, pullRequest: tagged, url: tagged.url)])
        #expect(events[0].title == "You were mentioned")
        #expect(Snapshot.fixture(involved: [tagged]).events(since: .fixture()).map(\.kind) == [.mentioned])
        #expect(Snapshot.fixture(involved: [taggedAgain]).events(since: .fixture(involved: [tagged])).map(\.kind) == [.mentioned])
        #expect(Snapshot.fixture(involved: [tagged]).events(since: .fixture(involved: [tagged])).isEmpty)
        #expect(Snapshot.fixture(involved: [quiet]).events(since: .fixture(involved: [tagged])).isEmpty)
    }

    @Test func repliedWhenMoreOfMyThreadsWaitOnMe() {
        let one = PullRequest.fixture(2, author: "alice", unansweredThreads: 1)
        let two = PullRequest.fixture(2, author: "alice", unansweredThreads: 2)
        let events = Snapshot.fixture(involved: [two]).events(since: .fixture(involved: [one]))
        #expect(events == [Event(kind: .replied, pullRequest: two, url: two.url)])
        #expect(events[0].title == "alice replied to your review")
        #expect(Snapshot.fixture(involved: [one]).events(since: .fixture(involved: [two])).isEmpty)
    }

    @Test func reviewPostedLinksToTheReview() {
        let review = Review.fixture("r1", by: "alice", .approved)
        let pr = PullRequest.fixture(1, reviews: [review])
        let events = Snapshot.fixture(authored: [pr]).events(since: .fixture(authored: [.fixture(1)]))
        #expect(events == [Event(kind: .reviewPosted(by: "alice", state: .approved), pullRequest: pr, url: review.url)])
        #expect(events[0].title == "alice approved")
    }

    @Test func severalReviewsFromOneReviewerCollapseToTheMostSignificant() {
        let old = Snapshot.fixture(authored: [.fixture(1, reviews: [.fixture("r0", by: "alice")])])
        let blocking = Review.fixture("r2", by: "alice", .changesRequested)
        let pr = PullRequest.fixture(1, reviews: [.fixture("r0", by: "alice"), .fixture("r1", by: "alice"), blocking, .fixture("r3", by: "alice")])
        let events = Snapshot.fixture(authored: [pr]).events(since: old)
        #expect(events == [Event(kind: .reviewPosted(by: "alice", state: .changesRequested), pullRequest: pr, url: blocking.url)])
        #expect(events[0].title == "alice requested changes")
    }

    @Test func eachReviewerGetsTheirOwnEvent() {
        let pr = PullRequest.fixture(1, reviews: [.fixture("r1", by: "bob", .approved), .fixture("r2", by: "alice")])
        let events = Snapshot.fixture(authored: [pr]).events(since: .fixture(authored: [.fixture(1)]))
        #expect(events.map(\.kind) == [.reviewPosted(by: "alice", state: .commented), .reviewPosted(by: "bob", state: .approved)])
        #expect(Set(events.map(\.id)).count == 2)
    }

    @Test func myOwnReviewsAndPendingOnesAreNotEvents() {
        let pr = PullRequest.fixture(1, reviews: [.fixture("r1", by: "joe"), .fixture("r2", by: "alice", .pending), .fixture("r3", by: "bob", .dismissed)])
        #expect(Snapshot.fixture(authored: [pr]).events(since: .fixture(authored: [.fixture(1)])).isEmpty)
    }

    @Test func reviewsOnAPullRequestIAmOnlyReviewingAreNotEvents() {
        let theirs = PullRequest.fixture(2, author: "alice")
        var reviewed = theirs
        reviewed.reviews = [.fixture("r1", by: "bob", .approved)]
        #expect(Snapshot.fixture(reviewRequested: [reviewed]).events(since: .fixture(reviewRequested: [theirs])).isEmpty)
    }

    @Test func botReviewWithCommentsIsAnEvent() {
        let first = Review.fixture("r1", by: "copilot-pull-request-reviewer", isBot: true, comments: 2)
        let second = Review.fixture("r2", by: "copilot-pull-request-reviewer", isBot: true, comments: 1)
        let pr = PullRequest.fixture(1, reviews: [first, second])
        let events = Snapshot.fixture(authored: [pr]).events(since: .fixture(authored: [.fixture(1)]))
        #expect(events == [Event(kind: .botReviewPosted(by: "copilot-pull-request-reviewer", commentCount: 3), pullRequest: pr, url: second.url)])
        #expect(events[0].title == "Copilot left 3 comments")
    }

    @Test func botReviewWithoutCommentsIsNotAnEvent() {
        let pr = PullRequest.fixture(1, reviews: [.fixture("r1", by: "copilot-pull-request-reviewer", isBot: true, comments: 0)])
        #expect(Snapshot.fixture(authored: [pr]).events(since: .fixture(authored: [.fixture(1)])).isEmpty)
    }

    @Test(arguments: [Checks.none, .pending, .passing])
    func checksFailedWhenTheyTurnRed(before: Checks) {
        let pr = PullRequest.fixture(1, checks: .failing)
        let events = Snapshot.fixture(authored: [pr]).events(since: .fixture(authored: [.fixture(1, checks: before)]))
        #expect(events == [Event(kind: .checksFailed, pullRequest: pr, url: pr.url)])
        #expect(events[0].title == "CI failed")
    }

    @Test func checksFailedAgainAfterGoingGreenIsANewEvent() {
        let red = Snapshot.fixture(authored: [.fixture(1, checks: .failing)])
        let green = Snapshot.fixture(authored: [.fixture(1, checks: .passing)])
        #expect(green.events(since: red).isEmpty)
        #expect(red.events(since: green).map(\.kind) == [.checksFailed])
    }

    @Test func conflictedWhenAPullRequestStartsConflicting() {
        let pr = PullRequest.fixture(1, mergeability: .conflicting)
        let events = Snapshot.fixture(authored: [pr]).events(since: .fixture(authored: [.fixture(1)]))
        #expect(events == [Event(kind: .conflicted, pullRequest: pr, url: pr.url)])
        #expect(events[0].title == "Merge conflict")
    }

    @Test func aPullRequestFirstSeenRedOrConflictingIsAnEvent() {
        let pr = PullRequest.fixture(1, mergeability: .conflicting, checks: .failing)
        #expect(Snapshot.fixture(authored: [pr]).events(since: .fixture()).map(\.kind) == [.checksFailed, .conflicted])
    }

    @Test func redAndConflictingPullRequestsOfOthersAreNotEvents() {
        let old = Snapshot.fixture(reviewRequested: [.fixture(2, author: "alice")])
        let new = Snapshot.fixture(reviewRequested: [.fixture(2, author: "alice", mergeability: .conflicting, checks: .failing)])
        #expect(new.events(since: old).isEmpty)
    }

    @Test func unknownMergeabilityKeepsTheLastKnownAnswer() {
        let conflicting = Snapshot.fixture(authored: [.fixture(1, mergeability: .conflicting)])
        let unknown = Snapshot.fixture(authored: [.fixture(1, mergeability: .unknown)]).carryingMergeability(from: conflicting)
        #expect(unknown.authored[0].mergeability == .conflicting)
        #expect(unknown.events(since: conflicting).isEmpty)

        let stillConflicting = Snapshot.fixture(authored: [.fixture(1, mergeability: .conflicting)]).carryingMergeability(from: unknown)
        #expect(stillConflicting.events(since: unknown).isEmpty)
    }

    @Test func unknownMergeabilityStaysUnknownWhenNeverKnown() {
        let unknown = Snapshot.fixture(authored: [.fixture(1, mergeability: .unknown)])
        #expect(unknown.carryingMergeability(from: nil) == unknown)
        #expect(unknown.carryingMergeability(from: .fixture()) == unknown)
    }
}
