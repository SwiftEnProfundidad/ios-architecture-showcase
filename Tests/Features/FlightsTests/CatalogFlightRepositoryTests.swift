import Foundation
import FlightsFeature
import SharedKernel
import Testing

@Suite("CatalogFlightRepository")
struct CatalogFlightRepositoryTests {

    @Test("Given the evaluation passenger catalog, when paging through the repository, then all twenty six flights are exposed without duplicates")
    func repositoryExposesTwentySixFlightsAcrossPages() async throws {
        let fileManager = FileManager.default
        let cacheDirectoryURL = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let tracked = makeCatalogFlightRepositorySUT(cacheDirectoryURL: cacheDirectoryURL)
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        let passengerID = PassengerID("PAX-001")
        defer {
            try? fileManager.removeItem(at: cacheDirectoryURL)
        }

        var currentPage = 1
        var collectedFlights: [Flight] = []
        var hasMorePages = true

        while hasMorePages {
            let result = try await context.sut.fetchPage(
                passengerID: passengerID,
                page: currentPage,
                pageSize: 10
            )
            collectedFlights.append(contentsOf: result.flights)
            hasMorePages = result.hasMorePages
            currentPage += 1
        }

        let uniqueFlightIDs = Set(collectedFlights.map(\.id.value))
        #expect(collectedFlights.count == 26)
        #expect(uniqueFlightIDs.count == 26)
        #expect(currentPage == 4)
    }

    @Test("Given cache persistence fails, when the remote catalog is readable, then the repository still returns the remote page")
    func cacheWriteFailureDoesNotInvalidateRemoteRead() async throws {
        let fileManager = FileManager.default
        let fixtureURL = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: false)
        let tracked = makeCatalogFlightRepositorySUT(cacheDirectoryURL: fixtureURL)
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        let passengerID = PassengerID("PAX-001")

        try Data("occupied".utf8).write(to: fixtureURL, options: .atomic)
        defer {
            try? fileManager.removeItem(at: fixtureURL)
        }

        let result = try await context.sut.fetchPage(
            passengerID: passengerID,
            page: 1,
            pageSize: 10
        )

        #expect(result.source == .remote)
        #expect(result.isStale == false)
        #expect(result.flights.count == 10)
    }
}
