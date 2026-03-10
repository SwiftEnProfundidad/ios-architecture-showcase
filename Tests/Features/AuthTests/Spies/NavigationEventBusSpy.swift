@testable import iOSArchitectureShowcase

actor NavigationEventBusSpy: NavigationEventPublishing {
    private(set) var lastPublishedEvent: NavigationEvent?
    private(set) var publishedEvents: [NavigationEvent] = []

    func publish(_ event: NavigationEvent) {
        lastPublishedEvent = event
        publishedEvents.append(event)
    }
}
