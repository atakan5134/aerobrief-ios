import Foundation

enum APIError: LocalizedError {
    case invalidResponse
    case server(String)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from server."
        case .server(let message): return message
        case .decoding(let error): return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}

/// Matches the FastAPI-style error bodies the backend returns, e.g.
/// `{"detail": "message"}` or `{"detail": [{"msg": "message", ...}, ...]}`
/// for 422 validation errors.
struct BackendErrorBody: Decodable {
    let detail: Detail?

    enum Detail: Decodable {
        case message(String)
        case validationErrors([ValidationError])

        struct ValidationError: Decodable { let msg: String }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let string = try? container.decode(String.self) {
                self = .message(string)
            } else {
                self = .validationErrors(try container.decode([ValidationError].self))
            }
        }
    }

    var friendlyMessage: String? {
        switch detail {
        case .message(let text): return text
        case .validationErrors(let errors) where !errors.isEmpty:
            return errors.map(\.msg).joined(separator: "\n")
        default: return nil
        }
    }
}

/// Produces a user-facing message for a failed HTTP response. Prefers the
/// backend's structured error body; falls back to a friendly, generic
/// message per status code rather than ever showing raw HTML/JSON to a pilot
/// mid-flight-planning.
func friendlyServerMessage(status: Int, data: Data) -> String {
    if let body = try? JSONDecoder().decode(BackendErrorBody.self, from: data),
       let message = body.friendlyMessage, !message.isEmpty {
        return message
    }
    switch status {
    case 400: return "The server couldn't process this request. Please check the file and try again."
    case 401, 403: return "Not authorized to reach the backend. Check your Backend URL in Settings."
    case 404: return "The backend endpoint wasn't found. Check your Backend URL in Settings."
    case 413: return "This PDF is too large for the server to accept."
    case 422: return "The uploaded file couldn't be validated. Please confirm it's a valid OFP PDF."
    case 429: return "Too many requests — please wait a moment and try again."
    case 500...599: return "The backend is having trouble processing this briefing. Please try again shortly."
    default: return "Server error (\(status)). Please try again."
    }
}

/// Thin networking layer. Base URL is configurable via SettingsView / AppSettings
/// so the app can point at a local dev backend or a deployed environment.
struct APIClient {
    let baseURL: URL

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        return decoder
    }()

    func get<T: Decodable>(_ path: String) async throws -> T {
        let request = URLRequest(url: baseURL.appendingPathComponent(path))
        return try await send(request)
    }

    func postJSON<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return try await send(request)
    }

    func uploadMultipart<T: Decodable>(
        _ path: String,
        fileData: Data,
        fileName: String,
        mimeType: String,
        fields: [String: String]
    ) async throws -> T {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"

        let boundary = "AeroBriefAI-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        for (key, value) in fields {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body
        return try await send(request)
    }

    /// Requests are retried once on transient network failures (timeout,
    /// dropped connection) — common on airport wifi/cellular — but never on
    /// a real server error response, since retrying a 4xx/5xx won't help.
    private static let requestTimeout: TimeInterval = 30
    private static let maxAttempts = 2

    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        var request = request
        request.timeoutInterval = Self.requestTimeout

        var lastTransientError: Error?
        for attempt in 1...Self.maxAttempts {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                guard (200..<300).contains(httpResponse.statusCode) else {
                    throw APIError.server(friendlyServerMessage(status: httpResponse.statusCode, data: data))
                }
                do {
                    return try decoder.decode(T.self, from: data)
                } catch {
                    throw APIError.decoding(error)
                }
            } catch let urlError as URLError where Self.isTransient(urlError) && attempt < Self.maxAttempts {
                lastTransientError = urlError
                continue
            }
        }
        // Unreachable in practice (the loop always returns or throws), but
        // required to satisfy the compiler; surface the last transient error.
        throw lastTransientError ?? APIError.invalidResponse
    }

    private static func isTransient(_ error: URLError) -> Bool {
        switch error.code {
        case .timedOut, .networkConnectionLost, .notConnectedToInternet, .dnsLookupFailed:
            return true
        default:
            return false
        }
    }
}
