#if canImport(SwiftUI)
import SwiftUI

public struct RootView: View {
    @State private var appViewModel: AppViewModel
    private let factory: DefaultViewFactory

    public init(appViewModel: AppViewModel, factory: DefaultViewFactory) {
        self._appViewModel = State(initialValue: appViewModel)
        self.factory = factory
    }

    public var body: some View {
        Group {
            switch appViewModel.activeRoute {
            case .login:
                factory.makeLoginView()
            case .flightList:
                factory.makeFlightListView()
            case .flightDetail(let flightID):
                factory.makeFlightDetailView(flightID: flightID)
            case .boardingPass(let flightID):
                factory.makeBoardingPassView(flightID: flightID)
            }
        }
        .task {
            await appViewModel.startObservingState()
        }
    }
}
#endif
