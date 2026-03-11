import Foundation

public actor URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func execute(_ request: HTTPRequest) async throws -> HTTPResponse {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body
        for (field, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: field)
        }

        do {
            let (data, response) = try await session.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw HTTPClientError.invalidResponse
            }
            return HTTPResponse(statusCode: httpResponse.statusCode, data: data)
        } catch let error as HTTPClientError {
            throw error
        } catch {
            throw HTTPClientError.transport
        }
    }
}
