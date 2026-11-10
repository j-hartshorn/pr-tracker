import Foundation

public struct GitHubClient: Sendable {
    private static let endpoint = URL(string: "https://api.github.com/graphql")!

    private let token: @Sendable () throws -> String
    private let session: URLSession

    public init(token: @escaping @Sendable () throws -> String = GHCLI.authToken, session: URLSession = .shared) {
        self.token = token
        self.session = session
    }

    /// One cheap request for the overview, then one for my pull requests and one for other people's, each only if one of them changed since `previous`. Pass nil to fetch everything again.
    public func fetchSnapshot(reusing previous: Snapshot?) async throws -> Snapshot {
        let overview = try OverviewQuery.decode(await send(query: OverviewQuery.text, variables: [String: String]()), fetchedAt: Date())
        let ids = overview.idsNeedingDetails(since: previous)
        let details = ids.isEmpty ? [:] : try DetailsQuery.decode(await send(query: DetailsQuery.text, variables: ["ids": ids]))
        let involvedIDs = overview.involvedIDsNeedingDetails(since: previous)
        let involved = involvedIDs.isEmpty ? [:] : try InvolvedQuery.decode(await send(query: InvolvedQuery.text, variables: ["ids": involvedIDs]), viewer: overview.viewer)
        return overview.withDetails(details, reusing: previous).withInvolvedDetails(involved, reusing: previous)
    }

    private func send(query: String, variables: some Encodable) async throws -> Data {
        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("Bearer \(try token())", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(GraphQLRequest(query: query, variables: variables))
        let (data, response) = try await session.data(for: request)
        let http = response as? HTTPURLResponse
        let status = http?.statusCode ?? 0
        if let until = RateLimit.pausedUntil(status: status, header: { http?.value(forHTTPHeaderField: $0) }, body: data, now: Date()) {
            throw GitHubError.rateLimited(until: until)
        }
        guard status == 200 else { throw GitHubError.http(status: status) }
        return data
    }
}

private struct GraphQLRequest<Variables: Encodable>: Encodable {
    var query: String
    var variables: Variables
}
