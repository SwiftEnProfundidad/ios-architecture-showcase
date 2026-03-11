import AppComposition
import Testing

@MainActor
func makeCompositionRootSmokeSUT(
    sourceLocation: SourceLocation = #_sourceLocation
) -> TrackedTestContext<CompositionRootSmokeContext> {
    let sut = CompositionRoot(evaluationCredentials: .default)
    return makeLeakTrackedTestContext(
        CompositionRootSmokeContext(root: sut),
        trackedInstances: sut,
        sourceLocation: sourceLocation
    )
}

struct CompositionRootSmokeContext {
    let root: CompositionRoot
}
