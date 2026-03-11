import SharedKernel
import SwiftUI

public struct FlightDetailView<DetailUseCase: FlightDetailGetting>: View {
    @Bindable var viewModel: FlightDetailViewModel<DetailUseCase>
    @Environment(\.colorScheme) private var colorScheme

    public init(viewModel: FlightDetailViewModel<DetailUseCase>) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            screenBackground
                .ignoresSafeArea()

            Group {
                if viewModel.isLoading {
                    detailSkeleton
                        .accessibilityLabel(AppStrings.localized("flights.detail.loading"))
                } else if let detail = viewModel.detail {
                    detailContent(detail)
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView(
                        AppStrings.localized("flights.detail.error.title"),
                        systemImage: "airplane.slash",
                        description: Text(error)
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 24)
                }
            }
        }
        .navigationTitle(AppStrings.localized("flights.detail.navigationTitle"))
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
                    Text(AppStrings.localized("flights.detail.boardingPassCTA"))
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel(AppStrings.localized("flights.detail.boardingPassCTA.accessibility"))
            }
            .frame(maxWidth: 640)
            .padding(.horizontal, 20)
            .padding(.vertical, 28)
        }
    }

    private func flightSummarySection(_ flight: Flight) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(flight.number)
                .font(.title.bold())
            Text(AppStrings.localized("flights.route", flight.origin, flight.destination))
                .font(.title3)
                .foregroundStyle(.secondary)
            detailRow(
                title: AppStrings.localized("flights.detail.gateTitle"),
                value: flight.gate,
                icon: "door.right.hand.open"
            )
            detailRow(
                title: AppStrings.localized("flights.detail.departureTitle"),
                value: flight.formattedScheduledDeparture(),
                icon: "clock"
            )
        }
        .padding(20)
        .background(.thinMaterial, in: .rect(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.45), lineWidth: 1)
        }
    }

    private func weatherSection(_ weather: WeatherInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppStrings.localized("flights.detail.weather.title"))
                .font(.headline)
            Label(
                AppStrings.localized(
                    "flights.detail.weather.summary",
                    weather.description,
                    String(weather.temperatureCelsius)
                ),
                systemImage: "sun.max"
            )
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: .rect(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.45), lineWidth: 1)
        }
    }

    private func detailRow(title: String, value: String, icon: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.headline)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            AppStrings.localized("shared.accessibility.labelValue", title, value)
        )
    }

    private var detailSkeleton: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.primary.opacity(0.16))
                        .frame(width: 110, height: 28)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.primary.opacity(0.10))
                        .frame(width: 180, height: 18)
                    ForEach(0..<2, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.primary.opacity(0.10))
                            .frame(height: 20)
                    }
                }
                .padding(20)
                .background(.thinMaterial, in: .rect(cornerRadius: 24))

                RoundedRectangle(cornerRadius: 24)
                    .fill(.thinMaterial)
                    .frame(height: 92)
                    .overlay {
                        VStack(alignment: .leading, spacing: 10) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.primary.opacity(0.16))
                                .frame(width: 140, height: 18)
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.primary.opacity(0.10))
                                .frame(width: 180, height: 16)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                RoundedRectangle(cornerRadius: 16)
                    .fill(.primary.opacity(0.10))
                    .frame(height: 52)
            }
            .redacted(reason: .placeholder)
            .frame(maxWidth: 640)
            .padding(.horizontal, 20)
            .padding(.vertical, 28)
            .accessibilityHidden(true)
        }
    }

    private var screenBackground: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [
                    Color(red: 0.07, green: 0.10, blue: 0.18),
                    Color(red: 0.03, green: 0.04, blue: 0.08),
                    .black
                ]
                : [
                    Color(red: 0.93, green: 0.96, blue: 1.0),
                    Color(red: 0.98, green: 0.98, blue: 1.0),
                    .white
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
