import AppComposition
import SwiftUI

@main
struct iOSArchitectureShowcaseApp: App {
    @State private var compositionRoot: CompositionRoot

    init() {
        _compositionRoot = State(initialValue: CompositionRoot())
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                appViewModel: compositionRoot.appViewModel,
                syncProtectedPath: compositionRoot.syncProtectedPath(_:),
                makeLoginView: compositionRoot.makeLoginView,
                makeFlightListView: compositionRoot.makeFlightListView(session:),
                makeFlightDetailView: compositionRoot.makeFlightDetailView(flightID:),
                makeBoardingPassView: compositionRoot.makeBoardingPassView(flightID:)
            )
            .task {
                await compositionRoot.start()
            }
        }
    }
}
