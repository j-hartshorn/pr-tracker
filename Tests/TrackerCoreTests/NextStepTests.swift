import Foundation
import Testing
@testable import TrackerCore

@Suite struct NextStepTests {
    static let t0 = Date(timeIntervalSince1970: 1_700_000_000)
    static let t1 = t0.addingTimeInterval(3600)
    static let t2 = t0.addingTimeInterval(7200)

    func steps(_ pr: PullRequest, in snapshot: Snapshot? = nil) -> [NextStep] {
        (snapshot ?? .fixture(authored: [pr])).nextSteps(for: pr)
    }

    // MARK: Mine

    @Test func reviewWhenMyReviewIsRequested() {
        let theirs = PullRequest.fixture(2, author: "alice", mergeability: .conflicting, checks: .failing)
        #expect(steps(theirs, in: .fixture(reviewRequested: [theirs])) == [.review])
    }

    @Test func answerCommentsWhenThreadsAreUnanswered() {
        #expect(steps(.fixture(requestedReviewers: ["bob"], unansweredThreads: 2)) == [.answerComments(2)])
    }

    @Test(arguments: [Review.State.commented, .changesRequested])
    func respondWhenAReviewDidNotApprove(state: Review.State) {
        let pr = PullRequest.fixture(reviews: [.fixture("r1", by: "alice", state, at: Self.t1)], lastCommitAt: Self.t0)
        #expect(steps(pr) == [.respond(to: ["alice"])])
    }

    @Test func respondNamesEveryReviewerStillOwedAnAnswer() {
        let pr = PullRequest.fixture(reviews: [
            .fixture("r1", by: "carol", .changesRequested, at: Self.t1),
            .fixture("r2", by: "alice", .commented, at: Self.t1),
            .fixture("r3", by: "bob", .approved, at: Self.t1),
        ], lastCommitAt: Self.t0)
        #expect(steps(pr) == [.respond(to: ["alice", "carol"])])
    }

    @Test func answerCommentsReplacesRespond() {
        let pr = PullRequest.fixture(reviews: [.fixture("r1", by: "alice", .changesRequested, at: Self.t1)], unansweredThreads: 1, lastCommitAt: Self.t0)
        #expect(steps(pr) == [.answerComments(1)])
    }

    @Test func aCommentAfterAnApprovalDoesNotNeedAResponse() {
        let pr = PullRequest.fixture(reviews: [.fixture("r1", by: "alice", .approved, at: Self.t0), .fixture("r2", by: "alice", .commented, at: Self.t1)])
        #expect(steps(pr) == [.merge])
    }

    @Test func botAndDismissedReviewsDoNotNeedAResponse() {
        let pr = PullRequest.fixture(requestedReviewers: ["bob"], reviews: [
            .fixture("r1", by: "copilot", isBot: true, .commented, comments: 3, at: Self.t1),
            .fixture("r2", by: "alice", .dismissed, at: Self.t1),
        ], lastCommitAt: Self.t0)
        #expect(steps(pr) == [.waitingOnReviewers(["bob"], since: nil)])
    }

    @Test func fixChecksWhenTheyFail() {
        #expect(steps(.fixture(checks: .failing, requestedReviewers: ["bob"])) == [.fixChecks])
    }

    @Test func resolveConflictsWhenThereAreSome() {
        #expect(steps(.fixture(mergeability: .conflicting, requestedReviewers: ["bob"])) == [.resolveConflicts])
    }

    @Test func draftsStillNeedTheirChecksAndConflictsFixed() {
        #expect(steps(.fixture(isDraft: true, mergeability: .conflicting, checks: .failing)) == [.fixChecks, .resolveConflicts])
    }

    @Test func requestReviewWhenNobodyIsAsked() {
        #expect(steps(.fixture()) == [.requestReview])
        #expect(steps(.fixture(reviewDecision: .reviewRequired)) == [.requestReview])
    }

    @Test func mergeWhenApprovedGreenAndClean() {
        #expect(steps(.fixture(reviewDecision: .approved)) == [.merge])
        #expect(steps(.fixture(checks: .none, reviewDecision: .approved)) == [.merge])
    }

    @Test func mergeEvenWhileAnotherReviewerIsStillAsked() {
        #expect(steps(.fixture(reviewDecision: .approved, requestedReviewers: ["bob"])) == [.merge])
    }

    @Test func everyStepThatIsMineIsListedInOrder() {
        let pr = PullRequest.fixture(mergeability: .conflicting, checks: .failing, unansweredThreads: 3)
        #expect(steps(pr) == [.answerComments(3), .fixChecks, .resolveConflicts])

        let approvedWithComments = PullRequest.fixture(reviewDecision: .approved, unansweredThreads: 1)
        #expect(steps(approvedWithComments) == [.answerComments(1), .merge])

        let redWithNobodyAsked = PullRequest.fixture(checks: .failing)
        #expect(steps(redWithNobodyAsked) == [.fixChecks, .requestReview])
    }

    // MARK: Handing the ball back

    @Test func askingTheReviewerAgainHandsTheBallBack() {
        let pr = PullRequest.fixture(
            reviewDecision: .changesRequested, requestedReviewers: ["alice"], waitingSince: Self.t2,
            reviews: [.fixture("r1", by: "alice", .changesRequested, at: Self.t1)], lastCommitAt: Self.t0
        )
        #expect(steps(pr) == [.waitingOnReviewers(["alice"], since: Self.t2)])
    }

    @Test func aCommitAfterTheReviewLeavesOnlyTheRequestToMake() {
        let pr = PullRequest.fixture(reviews: [.fixture("r1", by: "alice", .commented, at: Self.t1)], lastCommitAt: Self.t2)
        #expect(steps(pr) == [.requestReview])
    }

    @Test func aReplyAfterTheReviewLeavesOnlyTheRequestToMake() {
        let pr = PullRequest.fixture(reviews: [
            .fixture("r1", by: "alice", .commented, at: Self.t1),
            .fixture("r2", by: "joe", .commented, at: Self.t2),
        ], lastCommitAt: Self.t0)
        #expect(steps(pr) == [.requestReview])
    }

    @Test func aNewReviewAfterMyReplyIsMineAgain() {
        let pr = PullRequest.fixture(reviews: [
            .fixture("r1", by: "alice", .commented, at: Self.t0),
            .fixture("r2", by: "joe", .commented, at: Self.t1),
            .fixture("r3", by: "alice", .commented, at: Self.t2),
        ], lastCommitAt: Self.t0)
        #expect(steps(pr) == [.respond(to: ["alice"])])
    }

    // MARK: Someone else's

    @Test func waitingOnReviewersWhenTheyAreAsked() {
        let pr = PullRequest.fixture(reviewDecision: .reviewRequired, requestedReviewers: ["alice", "platform"], waitingSince: Self.t0)
        #expect(steps(pr) == [.waitingOnReviewers(["alice", "platform"], since: Self.t0)])
    }

    @Test func waitingOnChecksWhenApprovedButStillRunning() {
        #expect(steps(.fixture(checks: .pending, reviewDecision: .approved)) == [.waitingOnChecks])
        #expect(steps(.fixture(mergeability: .unknown, reviewDecision: .approved)) == [.waitingOnChecks])
    }

    @Test func waitingOnStackWhenApprovedButStackedOnAnOpenPullRequest() {
        let bottom = PullRequest.fixture(1, head: "bottom", reviewDecision: .approved)
        let top = PullRequest.fixture(2, base: "bottom", reviewDecision: .approved)
        let snapshot = Snapshot.fixture(authored: [bottom, top])
        #expect(snapshot.nextSteps(for: bottom) == [.merge])
        #expect(snapshot.nextSteps(for: top) == [.waitingOnStack(below: 1)])
    }

    @Test func draftWhenNothingIsBroken() {
        #expect(steps(.fixture(isDraft: true)) == [.draft])
        #expect(steps(.fixture(isDraft: true, reviewDecision: .approved)) == [.draft])
    }

    // MARK: Approval

    @Test func approvalFallsBackToEachPersonsLatestVerdict() {
        let approved = PullRequest.fixture(reviews: [.fixture("r1", by: "alice", .changesRequested), .fixture("r2", by: "alice", .approved), .fixture("r3", by: "alice", .commented)])
        #expect(approved.approval == .approved)

        let blocked = PullRequest.fixture(reviews: [.fixture("r1", by: "alice", .approved), .fixture("r2", by: "bob", .changesRequested)])
        #expect(blocked.approval == .changesRequested)

        let botOnly = PullRequest.fixture(reviews: [.fixture("r1", by: "copilot", isBot: true, .approved), .fixture("r2", by: "alice", .dismissed)])
        #expect(botOnly.approval == nil)
    }

    @Test func reviewDecisionBeatsTheFallback() {
        let pr = PullRequest.fixture(reviewDecision: .reviewRequired, reviews: [.fixture("r1", by: "alice", .approved)])
        #expect(pr.approval == .reviewRequired)
    }

    // MARK: Other people's pull requests that I took part in

    @Test func answerCommentsWhenSomeoneRepliedToMyReview() {
        let theirs = PullRequest.fixture(2, author: "alice", unansweredThreads: 2, mentionedAt: Self.t1)
        #expect(steps(theirs, in: .fixture(involved: [theirs])) == [.answerComments(2)])
    }

    @Test func answerMentionWhenIWasTaggedAndHaveNotSpokenSince() {
        let theirs = PullRequest.fixture(2, author: "alice", mentionedAt: Self.t1)
        #expect(steps(theirs, in: .fixture(involved: [theirs])) == [.answerMention])
    }

    @Test func waitingOnAuthorWhenNothingIsOwedToAnyone() {
        let theirs = PullRequest.fixture(2, author: "alice")
        let snapshot = Snapshot.fixture(involved: [theirs])
        #expect(steps(theirs, in: snapshot) == [.waitingOnAuthor])
        #expect(snapshot.needingAttention().isEmpty)
        #expect(snapshot.status(of: theirs) == .waiting)
    }

    @Test func aMentionNeedsAttentionAfterReviewsAndWithAnswers() {
        let toReview = PullRequest.fixture(7, author: "alice")
        let mentioned = PullRequest.fixture(8, author: "bob", mentionedAt: Self.t1)
        let toMerge = PullRequest.fixture(1, reviewDecision: .approved)
        let snapshot = Snapshot.fixture(authored: [toMerge], reviewRequested: [toReview], involved: [mentioned])
        #expect(snapshot.needingAttention().map(\.number) == [7, 8, 1])
        #expect(snapshot.status(of: mentioned) == .attention)
    }

    // MARK: Needing attention and status

    @Test func needingAttentionIsOrderedByWhatToLookAtFirst() {
        let toMerge = PullRequest.fixture(1, reviewDecision: .approved)
        let waiting = PullRequest.fixture(2, requestedReviewers: ["bob"])
        let red = PullRequest.fixture(3, checks: .failing, requestedReviewers: ["bob"])
        let toAnswer = PullRequest.fixture(4, requestedReviewers: ["bob"], unansweredThreads: 1)
        let draft = PullRequest.fixture(5, isDraft: true)
        let toRequest = PullRequest.fixture(6)
        let toReview = PullRequest.fixture(7, author: "alice")
        let alsoRed = PullRequest.fixture(8, mergeability: .conflicting, requestedReviewers: ["bob"])
        let snapshot = Snapshot.fixture(authored: [toMerge, waiting, red, toAnswer, draft, toRequest, alsoRed], reviewRequested: [toReview])
        #expect(snapshot.needingAttention().map(\.number) == [7, 4, 3, 8, 6, 1])
    }

    @Test func statusIsTheMostUrgentOfTheSteps() {
        let theirs = PullRequest.fixture(9, author: "alice")
        #expect(Snapshot.fixture(reviewRequested: [theirs]).status(of: theirs) == .attention)
        #expect(Snapshot.fixture().status(of: .fixture(checks: .failing, unansweredThreads: 1)) == .failing)
        #expect(Snapshot.fixture().status(of: .fixture(reviewDecision: .approved, unansweredThreads: 1)) == .attention)
        #expect(Snapshot.fixture().status(of: .fixture(reviewDecision: .approved)) == .ready)
        #expect(Snapshot.fixture().status(of: .fixture(requestedReviewers: ["bob"])) == .waiting)
        #expect(Snapshot.fixture().status(of: .fixture(isDraft: true)) == .waiting)
    }

    @Test func approvedAndWaitingOnItsStackIsReadyButDoesNotNeedMe() {
        let bottom = PullRequest.fixture(1, head: "bottom", requestedReviewers: ["bob"])
        let top = PullRequest.fixture(2, base: "bottom", reviewDecision: .approved)
        let snapshot = Snapshot.fixture(authored: [bottom, top])
        #expect(snapshot.status(of: top) == .ready)
        #expect(snapshot.needingAttention().isEmpty)
        #expect(snapshot.mostUrgentStatus() == .waiting)
    }

    @Test func mostUrgentStatusIsTheWorstAmongThoseThatNeedMe() {
        let theirs = PullRequest.fixture(9, author: "alice")
        let waiting = PullRequest.fixture(1, requestedReviewers: ["bob"])
        #expect(Snapshot.fixture().mostUrgentStatus() == .waiting)
        #expect(Snapshot.fixture(authored: [waiting]).mostUrgentStatus() == .waiting)
        #expect(Snapshot.fixture(authored: [waiting, .fixture(2, reviewDecision: .approved)]).mostUrgentStatus() == .ready)
        #expect(Snapshot.fixture(authored: [.fixture(2, reviewDecision: .approved)], reviewRequested: [theirs]).mostUrgentStatus() == .attention)
        #expect(Snapshot.fixture(authored: [.fixture(1, checks: .failing)], reviewRequested: [theirs]).mostUrgentStatus() == .failing)
    }

    @Test func hidingDraftsLeavesThemOutOfWhatNeedsMe() {
        let brokenDraft = PullRequest.fixture(1, isDraft: true, checks: .failing)
        let theirDraft = PullRequest.fixture(2, author: "alice", isDraft: true)
        let broken = PullRequest.fixture(3, checks: .failing)
        let snapshot = Snapshot.fixture(authored: [brokenDraft, broken], reviewRequested: [theirDraft])
        #expect(snapshot.needingAttention().map(\.number) == [2, 1, 3])
        #expect(snapshot.needingAttention(hidingDrafts: true).map(\.number) == [3])
        #expect(snapshot.statusesNeedingAttention(hidingDrafts: true) == [.failing])
        #expect(Snapshot.fixture(authored: [brokenDraft]).mostUrgentStatus(hidingDrafts: true) == .waiting)
    }

    @Test func statusesNeedingAttentionAreMostUrgentFirst() {
        let toMerge = PullRequest.fixture(1, reviewDecision: .approved)
        let waiting = PullRequest.fixture(2, requestedReviewers: ["bob"])
        let red = PullRequest.fixture(3, checks: .failing, requestedReviewers: ["bob"])
        let toReview = PullRequest.fixture(7, author: "alice")
        let snapshot = Snapshot.fixture(authored: [toMerge, waiting, red], reviewRequested: [toReview])
        #expect(snapshot.statusesNeedingAttention() == [.failing, .attention, .ready])
        #expect(Snapshot.fixture(authored: [waiting]).statusesNeedingAttention() == [])
    }
}
