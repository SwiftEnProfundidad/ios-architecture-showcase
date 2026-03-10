@testable import SharedNavigation

actor NavigationEventBusSpy: NavigationEventPublishing {
    private(set) var lastPublishedEvent: NavigationEvent?

    func publish(_ event: NavigationEvent) {
        lastPublishedEvent = event
    }
}
