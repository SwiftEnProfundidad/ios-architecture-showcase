import SharedNetworking

actor HTTPClientSpy: HTTPClient {
    private var result: Result<HTTPResponse, HTTPClientError> = .failure(.transport)

    func stub(result: Result<HTTPResponse, HTTPClientError>) {
        self.result = result
    }

    func execute(_ request: HTTPRequest) async throws -> HTTPResponse {
        try result.get()
    }
}
