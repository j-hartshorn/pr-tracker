import Foundation

public struct GitHubClient: Sendable {
    private static let endpoint = URL(string: "https://api.github.com/graphql")!

    private let token: @Sendable () throws -> String
    private let session: URLSession

    public init(token: @escaping @Sendable () throws -> String = GHCLI.authToken, session: URLSession = .shared) {
        self.token = token
        self.session = session
    }

    public func fetchSnapshot() async throws -> Snapshot {
        let data = try await send(query: SnapshotQuery.text, variables: [:])
        return try SnapshotQuery.decode(data, fetchedAt: Date())
    }

    private func send(query: String, variables: [String: String]) async throws -> Data {
        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("Bearer \(try token())", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(GraphQLRequest(query: query, variables: variables))
        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else { throw GitHubError.http(status: status) }
        return data
    }
}

private struct GraphQLRequest: Encodable {
    var query: String
    var variables: [String: String]
}
