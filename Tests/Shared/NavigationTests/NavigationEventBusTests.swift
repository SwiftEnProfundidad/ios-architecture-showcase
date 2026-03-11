import SharedKernel
import SharedNavigation
import Testing

@Suite("NavigationEventBus")
struct NavigationEventBusTests {

    @Test("Published event is received by the subscriber")
    func publishedEventIsReceivedBySubscriber() async {
        let (token, bus) = makeSUT()
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
        _ = token
    }

    @Test("Multiple events are received in order")
    func multipleEventsReceivedInOrder() async {
        let (token, bus) = makeSUT()
        let events: [NavigationEvent] = [
            .requestProtectedPath([.primaryDetail(contextID: "IB3456")]),
            .requestProtectedPath([.primaryDetail(contextID: "IB3456"), .secondaryAttachment(contextID: "IB3456")]),
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
        _ = token
    }

    private func makeSUT(
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> (MemoryLeakToken, DefaultNavigationEventBus) {
        let token = MemoryLeakToken()
        let bus = DefaultNavigationEventBus()
        trackForMemoryLeaks(bus, token: token, sourceLocation: sourceLocation)
        return (token, bus)
    }
}
