import BoardingPassFeature
import Testing

typealias GetBoardingPassUseCaseSUT = GetBoardingPassUseCase<BoardingPassRepositorySpy>

func makeGetBoardingPassUseCaseSUT(
    sourceLocation: SourceLocation = #_sourceLocation
) -> TrackedTestContext<GetBoardingPassUseCaseTestContext> {
    let repository = BoardingPassRepositorySpy()
    let sut = GetBoardingPassUseCaseSUT(repository: repository)
    return makeLeakTrackedTestContext(
        GetBoardingPassUseCaseTestContext(sut: sut, repository: repository),
        trackedInstances: repository,
        sourceLocation: sourceLocation
    )
}

struct GetBoardingPassUseCaseTestContext {
    let sut: GetBoardingPassUseCaseSUT
    let repository: BoardingPassRepositorySpy
}
