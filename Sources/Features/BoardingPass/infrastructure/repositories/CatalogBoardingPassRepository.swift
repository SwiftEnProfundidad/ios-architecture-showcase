import Foundation
import OSLog
import SharedKernel

public struct CatalogBoardingPassRepository: BoardingPassRepositoryProtocol {
    private let logger = Logger(subsystem: "com.swiftenprofundidad.iOSArchitectureShowcase", category: "boarding-pass.repository")
    private let bundle: Bundle
    private let decoder = JSONDecoder()

    public init() {
        self.bundle = .module
        decoder.dateDecodingStrategy = .iso8601
    }

    public func fetch(forFlightID flightID: FlightID) async throws -> BoardingPassData {
        try await Task.sleep(nanoseconds: 150_000_000)
        guard let url = bundle.url(forResource: "boarding-pass-catalog", withExtension: "json") else {
            logger.error("Boarding pass catalog is not available")
            throw BoardingPassError.network
        }
        let data = try Data(contentsOf: url)
        let records = try decoder.decode([BoardingPassRecord].self, from: data)
        guard let record = records.first(where: { $0.flightID == flightID.value }) else {
            logger.error("Boarding pass not found for flight \(flightID.value, privacy: .public)")
            throw BoardingPassError.notFound
        }
        return BoardingPassData(
            flightID: FlightID(record.flightID),
            passengerID: PassengerID(record.passengerID),
            passengerName: record.passengerName,
            seat: record.seat,
            gate: record.gate,
            boardingDeadline: record.boardingDeadline,
            boardingTimeZoneIdentifier: record.boardingTimeZoneIdentifier ?? "UTC",
            qrPayload: record.qrPayload
        )
    }
}

private struct BoardingPassRecord: Codable {
    let flightID: String
    let passengerID: String
    let passengerName: String
    let seat: String
    let gate: String
    let boardingDeadline: Date
    let boardingTimeZoneIdentifier: String?
    let qrPayload: String
}
