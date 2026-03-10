import Testing
@testable import SharedNavigation
@testable import SharedKernel

@Suite("NavigationEventBus")
struct NavigationEventBusTests {

    @Test("Evento publicado es recibido por el suscriptor")
    func publishedEventIsReceivedBySubscriber() async {
        let bus = DefaultNavigationEventBus()
        let passengerID = PassengerID("PAX-001")
        let expected = NavigationEvent.loginSuccess(passengerID: passengerID, token: "tok-abc")

        let received = await withCheckedContinuation { (continuation: CheckedContinuation<NavigationEvent, Never>) in
            Task {
                let stream = await bus.events()
                for await event in stream {
                    continuation.resume(returning: event)
                    break
                }
            }
            Task {
                try? await Task.sleep(nanoseconds: 10_000_000)
                await bus.publish(expected)
            }
        }

        #expect(received == expected)
    }

    @Test("Múltiples eventos se reciben en orden")
    func multipleEventsReceivedInOrder() async {
        let bus = DefaultNavigationEventBus()
        let flightID = FlightID("IB3456")
        let events: [NavigationEvent] = [
            .showFlightDetail(flightID: flightID),
            .showBoardingPass(flightID: flightID),
            .backToFlightList
        ]

        let received = await withCheckedContinuation { (continuation: CheckedContinuation<[NavigationEvent], Never>) in
            Task {
                try? await Task.sleep(nanoseconds: 10_000_000)
                for event in events {
                    await bus.publish(event)
                }
            }
            Task {
                let stream = await bus.events()
                var collected: [NavigationEvent] = []
                for await event in stream {
                    collected.append(event)
                    if collected.count == events.count {
                        continuation.resume(returning: collected)
                        break
                    }
                }
            }
        }

        #expect(received == events)
    }
}
