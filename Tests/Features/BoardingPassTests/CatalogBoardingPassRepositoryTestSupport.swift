import BoardingPassFeature
import Testing

struct CatalogBoardingPassRepositoryTestContext {
    let sut: CatalogBoardingPassRepository
}

func makeCatalogBoardingPassRepositorySUT() -> TrackedTestContext<CatalogBoardingPassRepositoryTestContext> {
    let sut = CatalogBoardingPassRepository()
    return makeTestContext(
        CatalogBoardingPassRepositoryTestContext(sut: sut)
    )
}
