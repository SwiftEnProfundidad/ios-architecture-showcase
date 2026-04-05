import SharedKernel
import SharedNavigation
import SwiftUI

public struct RootView<
    LoginContent: View,
    FlightListContent: View,
    FlightDetailContent: View,
    BoardingPassContent: View
>: View {
    @State private var appViewModel: AppViewModel
    @State private var visiblePath: [AppRoute]
    private let protectedPathCommandChannel: ProtectedPathCommandChannel
    private let makeLoginView: () -> LoginContent
    private let makeFlightListView: (AppSession) -> FlightListContent
    private let makeFlightDetailView: (FlightID) -> FlightDetailContent
    private let makeBoardingPassView: (FlightID) -> BoardingPassContent

    public init(
        appViewModel: AppViewModel,
        syncProtectedPath: @escaping @Sendable ([AppRoute]) async -> Void,
        makeLoginView: @escaping () -> LoginContent,
        makeFlightListView: @escaping (AppSession) -> FlightListContent,
        makeFlightDetailView: @escaping (FlightID) -> FlightDetailContent,
        makeBoardingPassView: @escaping (FlightID) -> BoardingPassContent
    ) {
        self._appViewModel = State(initialValue: appViewModel)
        self._visiblePath = State(initialValue: appViewModel.path)
        self.protectedPathCommandChannel = ProtectedPathCommandChannel(
            publish: syncProtectedPath
        )
        self.makeLoginView = makeLoginView
        self.makeFlightListView = makeFlightListView
        self.makeFlightDetailView = makeFlightDetailView
        self.makeBoardingPassView = makeBoardingPassView
    }

    public var body: some View {
        NavigationStack(path: $visiblePath) {
            rootContent
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .primaryDetail(let contextID):
                    makeFlightDetailView(contextID)
                case .secondaryAttachment(let contextID):
                    makeBoardingPassView(contextID)
                }
            }
        }
        .task {
            appViewModel.startObservingState()
        }
        .task(id: visiblePath) {
            await protectedPathCommandChannel.synchronize(
                visiblePath: visiblePath,
                projectedPath: appViewModel.path
            )
        }
        .onChange(of: appViewModel.path) { _, newPath in
            guard visiblePath != newPath else {
                return
            }
            visiblePath = newPath
        }
        .onDisappear {
            appViewModel.stopObservingState()
        }
    }

    @ViewBuilder
    private var rootContent: some View {
        switch appViewModel.rootRoute {
        case .login:
            makeLoginView()
        case .authenticatedHome:
            if let session = appViewModel.session {
                makeFlightListView(session)
            } else {
                makeLoginView()
            }
        }
    }
}
