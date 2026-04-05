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
                    .padding(.horizontal, ShowcaseLayout.Inset.screenXWide)
                }
            }
        }
        .screenBackground()
        .navigationTitle(AppStrings.localized("flights.detail.navigationTitle"))
        .task {
            await viewModel.load()
        }
    }

    private func detailContent(_ detail: FlightDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ShowcaseLayout.Space.section) {
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
            .frame(maxWidth: ShowcaseLayout.ContentWidth.detail)
            .padding(.horizontal, ShowcaseLayout.Inset.screenX)
            .padding(.vertical, ShowcaseLayout.Space.screen)
        }
    }

    private func flightSummarySection(_ flight: Flight) -> some View {
        VStack(alignment: .leading, spacing: ShowcaseLayout.Space.sm) {
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
                value: OperationalTimeFormatter.hourMinute(
                    from: flight.scheduledDeparture,
                    timeZoneIdentifier: flight.departureTimeZoneIdentifier
                ),
                icon: "clock"
            )
        }
        .padding(ShowcaseLayout.Inset.card)
        .background(.thinMaterial, in: .rect(cornerRadius: ShowcaseLayout.Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: ShowcaseLayout.Radius.card)
                .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.45), lineWidth: ShowcaseLayout.Line.stroke)
        }
    }

    private func weatherSection(_ weather: WeatherInfo) -> some View {
        VStack(alignment: .leading, spacing: ShowcaseLayout.Space.sm) {
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
        .padding(ShowcaseLayout.Inset.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: .rect(cornerRadius: ShowcaseLayout.Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: ShowcaseLayout.Radius.card)
                .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.45), lineWidth: ShowcaseLayout.Line.stroke)
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
            VStack(alignment: .leading, spacing: ShowcaseLayout.Space.section) {
                VStack(alignment: .leading, spacing: ShowcaseLayout.Space.lg) {
                    RoundedRectangle(cornerRadius: ShowcaseLayout.Radius.line)
                        .fill(.primary.opacity(0.16))
                        .frame(width: 110, height: 28)
                    RoundedRectangle(cornerRadius: ShowcaseLayout.Radius.line)
                        .fill(.primary.opacity(0.10))
                        .frame(width: 180, height: 18)
                    ForEach(0..<2, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: ShowcaseLayout.Radius.line)
                            .fill(.primary.opacity(0.10))
                            .frame(height: 20)
                    }
                }
                .padding(ShowcaseLayout.Inset.card)
                .background(.thinMaterial, in: .rect(cornerRadius: ShowcaseLayout.Radius.card))

                RoundedRectangle(cornerRadius: ShowcaseLayout.Radius.card)
                    .fill(.thinMaterial)
                    .frame(height: 92)
                    .overlay {
                        VStack(alignment: .leading, spacing: ShowcaseLayout.Space.md) {
                            RoundedRectangle(cornerRadius: ShowcaseLayout.Radius.line)
                                .fill(.primary.opacity(0.16))
                                .frame(width: 140, height: 18)
                            RoundedRectangle(cornerRadius: ShowcaseLayout.Radius.line)
                                .fill(.primary.opacity(0.10))
                                .frame(width: 180, height: 16)
                        }
                        .padding(ShowcaseLayout.Inset.card)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                RoundedRectangle(cornerRadius: ShowcaseLayout.Radius.block)
                    .fill(.primary.opacity(0.10))
                    .frame(height: 52)
            }
            .redacted(reason: .placeholder)
            .frame(maxWidth: ShowcaseLayout.ContentWidth.detail)
            .padding(.horizontal, ShowcaseLayout.Inset.screenX)
            .padding(.vertical, ShowcaseLayout.Space.screen)
            .accessibilityHidden(true)
        }
    }

}
