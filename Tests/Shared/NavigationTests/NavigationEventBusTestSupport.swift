import SharedNavigation
import Testing

struct NavigationEventBusTestContext {
    let bus: DefaultNavigationEventBus
}

func makeNavigationEventBusSUT(
    sourceLocation: SourceLocation = #_sourceLocation
) -> TrackedTestContext<NavigationEventBusTestContext> {
    let bus = DefaultNavigationEventBus()
    return makeLeakTrackedTestContext(
        NavigationEventBusTestContext(bus: bus),
        trackedInstances: bus,
        sourceLocation: sourceLocation
    )
}
