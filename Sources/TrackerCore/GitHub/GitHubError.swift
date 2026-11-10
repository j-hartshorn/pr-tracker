import Foundation

public enum GitHubError: LocalizedError, Equatable {
    case ghNotFound
    case ghFailed(String)
    case http(status: Int)
    case graphQL(String)

    public var errorDescription: String? {
        switch self {
        case .ghNotFound:
            "The gh command was not found. Install it with `brew install gh`."
        case .ghFailed(let detail):
            "gh could not provide a token. Run `gh auth login`. (\(detail))"
        case .http(let status) where status == 401:
            "GitHub rejected the token. Run `gh auth login`."
        case .http(let status):
            "GitHub returned HTTP \(status). The next refresh will try again."
        case .graphQL(let message):
            "GitHub could not answer the query: \(message)"
        }
    }
}
