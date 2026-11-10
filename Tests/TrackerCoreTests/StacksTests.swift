import Foundation
import Testing
@testable import TrackerCore

@Suite struct StacksTests {
    @Test func aLonePullRequestIsAStackOfOne() {
        let pr = PullRequest.fixture(1)
        #expect(Snapshot.fixture(authored: [pr]).stacks == [Stack(pullRequest: pr)])
    }

    @Test func aChainNestsFromTheBottomUp() {
        let bottom = PullRequest.fixture(1, head: "a")
        let middle = PullRequest.fixture(2, base: "a", head: "b")
        let top = PullRequest.fixture(3, base: "b", head: "c")
        let stacks = Snapshot.fixture(authored: [top, bottom, middle]).stacks
        #expect(stacks == [Stack(pullRequest: bottom, children: [Stack(pullRequest: middle, children: [Stack(pullRequest: top)])])])
    }

    @Test func aBranchingStackKeepsEveryChild() {
        let bottom = PullRequest.fixture(1, head: "a")
        let left = PullRequest.fixture(2, base: "a", head: "b")
        let right = PullRequest.fixture(3, base: "a", head: "c")
        let stacks = Snapshot.fixture(authored: [bottom, left, right]).stacks
        #expect(stacks == [Stack(pullRequest: bottom, children: [Stack(pullRequest: left), Stack(pullRequest: right)])])
    }

    @Test func rootsKeepTheirFetchOrder() {
        let first = PullRequest.fixture(1)
        let second = PullRequest.fixture(2)
        #expect(Snapshot.fixture(authored: [second, first]).stacks.map(\.pullRequest) == [second, first])
    }

    @Test func theSameBranchNameInAnotherRepositoryIsNotAStack() {
        let bottom = PullRequest.fixture(1, repository: "acme/widgets", head: "a")
        let other = PullRequest.fixture(2, repository: "acme/gadgets", base: "a")
        #expect(Snapshot.fixture(authored: [bottom, other]).stacks == [Stack(pullRequest: bottom), Stack(pullRequest: other)])
    }

    @Test func aHeadInAForkIsNotABase() {
        let fromFork = PullRequest.fixture(1, head: "main", isFromFork: true)
        let other = PullRequest.fixture(2, base: "main")
        #expect(Snapshot.fixture(authored: [fromFork, other]).stacks == [Stack(pullRequest: fromFork), Stack(pullRequest: other)])
    }

    @Test func aLoopOfBasesStillShowsEveryPullRequest() {
        let one = PullRequest.fixture(1, base: "b", head: "a")
        let two = PullRequest.fixture(2, base: "a", head: "b")
        let stacks = Snapshot.fixture(authored: [one, two]).stacks
        #expect(stacks == [Stack(pullRequest: one, children: [Stack(pullRequest: two)])])
    }

    @Test func pullRequestsIAmReviewingAreNotInMyStacks() {
        let theirs = PullRequest.fixture(2, author: "alice", head: "a")
        let mine = PullRequest.fixture(1, base: "a")
        let snapshot = Snapshot.fixture(authored: [mine], reviewRequested: [theirs])
        #expect(snapshot.stacks == [Stack(pullRequest: mine)])
        #expect(snapshot.parent(of: mine) == nil)
    }
}
