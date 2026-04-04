import Foundation
import SharedKernel

struct CatalogFlightDataSource {
    private let bundle: Bundle
    private let decoder: JSONDecoder

    init(bundle: Bundle) {
        self.bundle = bundle
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    func loadFlights() throws -> [Flight] {
        guard let url = bundle.url(forResource: "flight-catalog", withExtension: "json") else {
            throw FlightError.network
        }
        let data = try Data(contentsOf: url)
        return try decoder.decode([FlightRecord].self, from: data).map(\.flight)
    }
}

struct FlightRecord: Codable {
    let id: String
    let passengerID: String
    let number: String
    let origin: String
    let destination: String
    let status: FlightStatusRecord
    let scheduledDeparture: Date
    let scheduledDepartureTimeZoneIdentifier: String?
    let gate: String

    init(_ flight: Flight) {
        id = flight.id.value
        passengerID = flight.passengerID.value
        number = flight.number
        origin = flight.origin
        destination = flight.destination
        status = FlightStatusRecord(flight.status)
        scheduledDeparture = flight.scheduledDeparture
        scheduledDepartureTimeZoneIdentifier = flight.departureTimeZoneIdentifier
        gate = flight.gate
    }

    var flight: Flight {
        Flight(
            id: FlightID(id),
            passengerID: PassengerID(passengerID),
            number: number,
            origin: origin,
            destination: destination,
            status: status.flightStatus,
            scheduledDeparture: scheduledDeparture,
            departureTimeZoneIdentifier: scheduledDepartureTimeZoneIdentifier ?? timeZoneIdentifier(for: origin),
            gate: gate
        )
    }

    private func timeZoneIdentifier(for airportCode: String) -> String {
        switch airportCode {
        case "AGP", "BCN", "BIO", "MAD", "PMI", "SVQ", "VLC":
            "Europe/Madrid"
        case "LHR":
            "Europe/London"
        case "LIS", "OPO":
            "Europe/Lisbon"
        case "CDG":
            "Europe/Paris"
        case "FCO":
            "Europe/Rome"
        case "AMS":
            "Europe/Amsterdam"
        case "BER":
            "Europe/Berlin"
        case "ZRH":
            "Europe/Zurich"
        default:
            "UTC"
        }
    }
}

enum FlightStatusRecord: String, Codable {
    case onTime
    case delayed
    case boarding
    case departed
    case cancelled

    init(_ status: Flight.Status) {
        switch status {
        case .onTime:
            self = .onTime
        case .delayed:
            self = .delayed
        case .boarding:
            self = .boarding
        case .departed:
            self = .departed
        case .cancelled:
            self = .cancelled
        }
    }

    var flightStatus: Flight.Status {
        switch self {
        case .onTime:
            .onTime
        case .delayed:
            .delayed
        case .boarding:
            .boarding
        case .departed:
            .departed
        case .cancelled:
            .cancelled
        }
    }
}
