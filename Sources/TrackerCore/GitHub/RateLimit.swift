import Foundation

enum RateLimit {
    private static let fallbackPause: TimeInterval = 600

    /// When requests may start again, if this response says a rate limit was hit. Nil for any other response.
    ///
    /// GitHub reports the hourly limit as a 200 with a RATE_LIMITED error, and its burst limits as a 403 or 429 with a retry-after header.
    static func pausedUntil(status: Int, header: (String) -> String?, body: Data, now: Date) -> Date? {
        let retryAfter = header("retry-after").flatMap(TimeInterval.init)
        let isOutOfPoints = header("x-ratelimit-remaining") == "0"
        let hitBurstLimit = (status == 403 || status == 429) && (retryAfter != nil || isOutOfPoints)
        guard hitBurstLimit || saysRateLimited(body) else { return nil }
        if let retryAfter { return now.addingTimeInterval(retryAfter) }
        if isOutOfPoints, let reset = header("x-ratelimit-reset").flatMap(TimeInterval.init) {
            return Date(timeIntervalSince1970: reset)
        }
        return now.addingTimeInterval(fallbackPause)
    }

    private static func saysRateLimited(_ body: Data) -> Bool {
        struct Envelope: Decodable { var errors: [GraphQL.ResponseError]? }
        let errors = (try? JSONDecoder().decode(Envelope.self, from: body))?.errors ?? []
        return errors.contains { $0.type == "RATE_LIMITED" }
    }
}
