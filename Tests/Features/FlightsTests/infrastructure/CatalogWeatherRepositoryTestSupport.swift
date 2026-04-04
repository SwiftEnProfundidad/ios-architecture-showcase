import FlightsFeature
import Testing

struct CatalogWeatherRepositoryTestContext {
    let sut: CatalogWeatherRepository
}

func makeCatalogWeatherRepositorySUT() -> TrackedTestContext<CatalogWeatherRepositoryTestContext> {
    let sut = CatalogWeatherRepository()
    return makeTestContext(
        CatalogWeatherRepositoryTestContext(sut: sut)
    )
}
