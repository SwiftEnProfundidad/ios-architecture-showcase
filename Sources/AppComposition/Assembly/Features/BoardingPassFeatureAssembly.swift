import BoardingPassFeature
import SharedKernel
import SwiftUI

@MainActor
struct BoardingPassFeatureAssembly {
    private let runtime: BoardingPassRuntime

    init(runtime: BoardingPassRuntime) {
        self.runtime = runtime
    }

    func makeView(flightID: FlightID) -> some View {
        BoardingPassScene(
            viewModel: BoardingPassViewModel(
                useCase: GetBoardingPassUseCase(repository: runtime.repository),
                flightID: flightID
            )
        )
    }
}

private struct BoardingPassScene<UseCase: BoardingPassGetting>: View {
    @State private var viewModel: BoardingPassViewModel<UseCase>

    init(viewModel: BoardingPassViewModel<UseCase>) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        BoardingPassView(viewModel: viewModel)
    }
}
