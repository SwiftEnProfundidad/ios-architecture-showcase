#if canImport(SwiftUI)
import SwiftUI
import Flights

public struct FlightDetailView: View {
    @Bindable var viewModel: FlightDetailViewModel

    public init(viewModel: FlightDetailViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .accessibilityLabel(String(localized: "flights.detail.loading"))
            } else if let detail = viewModel.detail {
                detailContent(detail)
            } else if let error = viewModel.errorMessage {
                ContentUnavailableView(
                    String(localized: "flights.detail.error.title"),
                    systemImage: "airplane.slash",
                    description: Text(error)
                )
            }
        }
        .navigationTitle(String(localized: "flights.detail.navigationTitle"))
        .task {
            await viewModel.load()
        }
    }

    private func detailContent(_ detail: FlightDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                flightSummarySection(detail.flight)

                if let weather = detail.weather {
                    weatherSection(weather)
                }

                Button {
                    Task { await viewModel.requestBoardingPass() }
                } label: {
                    Text(String(localized: "flights.detail.boardingPassCTA"))
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel(String(localized: "flights.detail.boardingPassCTA.accessibility"))
            }
            .padding()
        }
    }

    private func flightSummarySection(_ flight: Flight) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(flight.number)
                .font(.title.bold())
            Text("\(flight.origin) → \(flight.destination)")
                .font(.title3)
                .foregroundStyle(.secondary)
            Label(String(localized: "flights.detail.gate \(flight.gate)"), systemImage: "door.right.hand.open")
            Label(String(localized: "flights.detail.departure \(flight.scheduledDeparture)"), systemImage: "clock")
        }
    }

    private func weatherSection(_ weather: WeatherInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "flights.detail.weather.title"))
                .font(.headline)
            Label("\(weather.description) · \(weather.temperatureCelsius)°C", systemImage: "sun.max")
        }
    }
}
#endif
