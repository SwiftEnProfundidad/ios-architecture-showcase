import Foundation
import FlightsFeature
import Testing

struct CatalogFlightRepositoryTestContext {
    let sut: CatalogFlightRepository
}

func makeCatalogFlightRepositorySUT(
    cacheDirectoryURL: URL,
    sourceLocation: SourceLocation = #_sourceLocation
) -> TrackedTestContext<CatalogFlightRepositoryTestContext> {
    let sut = CatalogFlightRepository(cacheDirectoryURL: cacheDirectoryURL)
    return makeLeakTrackedTestContext(
        CatalogFlightRepositoryTestContext(sut: sut),
        trackedInstances: sut,
        sourceLocation: sourceLocation
    )
}
