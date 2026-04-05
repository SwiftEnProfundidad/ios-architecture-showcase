import SharedKernel
import SharedNavigation
import Testing

@Suite("NavigationEventBus")
struct NavigationEventBusTests {

    @Test("Given a subscriber, when an event is published, then the subscriber receives it")
    func publishedEventIsReceivedBySubscriber() async {
        let tracked = makeNavigationEventBusSUT()
        defer { tracked.assertNoLeaks() }
        let bus = tracked.context.bus
        let expected = NavigationEvent.sessionStarted(
            AppSession(
                passengerID: PassengerID("PAX-001"),
                token: "tok-abc",
                expiresAt: fixedDate(hour: 12, minute: 0)
            )
        )

        let stream = await bus.events()
        var iterator = stream.makeAsyncIterator()
        await bus.publish(expected)
        let received = await iterator.next()

        #expect(received == expected)
    }

    @Test("Given a subscriber, when multiple events are published in sequence, then they are received in the same order")
    func multipleEventsReceivedInOrder() async {
        let tracked = makeNavigationEventBusSUT()
        defer { tracked.assertNoLeaks() }
        let bus = tracked.context.bus
        let events: [NavigationEvent] = [
            .requestProtectedPath([.primaryDetail(contextID: FlightID("IB3456"))]),
            .requestProtectedPath([.primaryDetail(contextID: FlightID("IB3456")), .secondaryAttachment(contextID: FlightID("IB3456"))]),
            .syncProtectedPath([])
        ]

        let stream = await bus.events()
        var iterator = stream.makeAsyncIterator()
        for event in events {
            await bus.publish(event)
        }

        let received = await [
            iterator.next(),
            iterator.next(),
            iterator.next()
        ].compactMap { $0 }

        #expect(received == events)
    }
}
