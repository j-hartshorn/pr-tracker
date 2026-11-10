import Foundation
import Testing
@testable import TrackerCore

@Suite struct RateLimitTests {
    static let now = Date(timeIntervalSince1970: 1_700_000_000)
    static let rateLimitedBody = Data(#"{"errors": [{"type": "RATE_LIMITED", "message": "API rate limit exceeded for user ID 1."}]}"#.utf8)
    static let okBody = Data(#"{"data": {"viewer": {"login": "joe"}}}"#.utf8)

    func pausedUntil(status: Int, headers: [String: String] = [:], body: Data = okBody) -> Date? {
        RateLimit.pausedUntil(status: status, header: { headers[$0] }, body: body, now: Self.now)
    }

    @Test func anOrdinaryResponseIsNotALimit() {
        #expect(pausedUntil(status: 200, headers: ["x-ratelimit-remaining": "4790", "x-ratelimit-reset": "1700003600"]) == nil)
    }

    @Test func theLastPointSpentIsNotYetALimit() {
        #expect(pausedUntil(status: 200, headers: ["x-ratelimit-remaining": "0", "x-ratelimit-reset": "1700003600"]) == nil)
    }

    @Test func theHourlyLimitPausesUntilItResets() {
        let until = pausedUntil(status: 200, headers: ["x-ratelimit-remaining": "0", "x-ratelimit-reset": "1700003600"], body: Self.rateLimitedBody)
        #expect(until == Date(timeIntervalSince1970: 1_700_003_600))
    }

    @Test(arguments: [403, 429])
    func aBurstLimitPausesForAsLongAsGitHubAsks(status: Int) {
        #expect(pausedUntil(status: status, headers: ["retry-after": "90"]) == Self.now.addingTimeInterval(90))
    }

    @Test func aForbiddenResponseWithNoPointsLeftIsALimit() {
        let until = pausedUntil(status: 403, headers: ["x-ratelimit-remaining": "0", "x-ratelimit-reset": "1700003600"])
        #expect(until == Date(timeIntervalSince1970: 1_700_003_600))
    }

    @Test func aForbiddenResponseForAnotherReasonIsNotALimit() {
        #expect(pausedUntil(status: 403, headers: ["x-ratelimit-remaining": "4000"]) == nil)
    }

    @Test func aLimitWithoutAResetTimePausesForTenMinutes() {
        #expect(pausedUntil(status: 200, body: Self.rateLimitedBody) == Self.now.addingTimeInterval(600))
    }
}
