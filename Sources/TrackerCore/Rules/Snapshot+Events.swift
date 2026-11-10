import Foundation

extension Snapshot {
    /// The events that happened between `old` and this snapshot. With no `old` this is the baseline, so nothing is an event.
    public func events(since old: Snapshot?) -> [Event] {
        guard let old else { return [] }
        let oldAuthored = Dictionary(old.authored.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let oldRequested = Set(old.reviewRequested.map(\.id))

        let requested = reviewRequested
            .filter { !oldRequested.contains($0.id) }
            .map { Event(kind: .reviewRequested, pullRequest: $0, url: $0.url) }

        let authoredEvents = authored.flatMap { pr -> [Event] in
            let before = oldAuthored[pr.id]
            var events = reviewEvents(for: pr, seen: Set(before?.reviews.map(\.id) ?? []))
            if pr.checks == .failing, before?.checks != .failing {
                events.append(Event(kind: .checksFailed, pullRequest: pr, url: pr.url))
            }
            if pr.mergeability == .conflicting, before?.mergeability != .conflicting {
                events.append(Event(kind: .conflicted, pullRequest: pr, url: pr.url))
            }
            return events
        }
        let oldInvolved = Dictionary(old.involved.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let involvedEvents = involved.flatMap { pr -> [Event] in
            let before = oldInvolved[pr.id]
            var events: [Event] = []
            if let mentionedAt = pr.mentionedAt, mentionedAt != before?.mentionedAt {
                events.append(Event(kind: .mentioned, pullRequest: pr, url: pr.url))
            }
            if pr.unansweredThreadCount > before?.unansweredThreadCount ?? 0 {
                events.append(Event(kind: .replied, pullRequest: pr, url: pr.url))
            }
            return events
        }
        return requested + involvedEvents + authoredEvents
    }

    /// GitHub computes mergeability lazily and often answers "unknown". Keeping the last known answer stops that from hiding or repeating a conflict.
    public func carryingMergeability(from old: Snapshot?) -> Snapshot {
        guard let old else { return self }
        let known = Dictionary((old.authored + old.reviewRequested).map { ($0.id, $0.mergeability) }, uniquingKeysWith: { first, _ in first })
        var copy = self
        func carry(_ pr: inout PullRequest) {
            if pr.mergeability == .unknown, let last = known[pr.id] { pr.mergeability = last }
        }
        for index in copy.authored.indices { carry(&copy.authored[index]) }
        for index in copy.reviewRequested.indices { carry(&copy.reviewRequested[index]) }
        return copy
    }

    /// One event per reviewer, because GitHub creates a separate review for every reply in a thread.
    private func reviewEvents(for pr: PullRequest, seen: Set<String>) -> [Event] {
        let unseen = pr.reviews.filter { !seen.contains($0.id) && $0.author != viewer }
        return Dictionary(grouping: unseen, by: \.author)
            .sorted { $0.key < $1.key }
            .compactMap { reviewer, reviews in
                reviews[0].isBot ? botEvent(for: pr, bot: reviewer, reviews: reviews) : personEvent(for: pr, reviewer: reviewer, reviews: reviews)
            }
    }

    private func personEvent(for pr: PullRequest, reviewer: String, reviews: [Review]) -> Event? {
        let ranking: [Review.State] = [.changesRequested, .approved, .commented]
        guard let review = ranking.lazy.compactMap({ state in reviews.last { $0.state == state } }).first else { return nil }
        return Event(kind: .reviewPosted(by: reviewer, state: review.state), pullRequest: pr, url: review.url)
    }

    private func botEvent(for pr: PullRequest, bot: String, reviews: [Review]) -> Event? {
        let commented = reviews.filter { $0.commentCount > 0 }
        guard let latest = commented.last else { return nil }
        let count = commented.reduce(0) { $0 + $1.commentCount }
        return Event(kind: .botReviewPosted(by: bot, commentCount: count), pullRequest: pr, url: latest.url)
    }
}
