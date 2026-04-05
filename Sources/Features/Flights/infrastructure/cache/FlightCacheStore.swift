import Foundation
import SharedKernel

actor FlightCacheStore {
    private let cacheURL: URL
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let fileManager = FileManager.default

    init(cacheURL: URL) {
        self.cacheURL = cacheURL
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.encoder.dateEncodingStrategy = .iso8601
    }

    func loadFlights() throws -> [Flight] {
        guard fileManager.fileExists(atPath: cacheURL.path) else {
            throw FlightError.cacheUnavailable
        }
        let data = try Data(contentsOf: cacheURL)
        return try decoder.decode([FlightRecord].self, from: data).map(\.flight)
    }

    func persist(_ flights: [Flight]) throws {
        let directoryURL = cacheURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let data = try encoder.encode(flights.map(FlightRecord.init))
        try data.write(to: cacheURL, options: .atomic)
    }
}
