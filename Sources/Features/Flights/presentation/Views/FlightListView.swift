import SharedKernel
import SwiftUI

public struct FlightListView<ListExecutor: ListFlightsExecuting, SessionController: FlightListSessionControlling, FeedbackClock: Clock<Duration>>: View {
    @Bindable var viewModel: FlightListViewModel<ListExecutor, SessionController, FeedbackClock>
    @Environment(\.colorScheme) private var colorScheme

    public init(viewModel: FlightListViewModel<ListExecutor, SessionController, FeedbackClock>) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            content
        }
        .screenBackground()
        .navigationTitle(AppStrings.localized("flights.list.navigationTitle"))
        .toolbar {
            ToolbarItem {
                Button(AppStrings.localized("flights.list.logout")) {
                    Task { await viewModel.logout() }
                }
                .accessibilityLabel(AppStrings.localized("flights.list.logout.accessibility"))
            }
        }
        .task {
            if viewModel.flights.isEmpty {
                await viewModel.load()
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isShowingInitialSkeleton {
            skeletonList
        } else if viewModel.flights.isEmpty, let error = viewModel.errorMessage {
            ContentUnavailableView(
                AppStrings.localized("flights.list.error.title"),
                systemImage: "wifi.slash",
                description: Text(error)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 24)
        } else {
            flightList
        }
    }

    private var flightList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
            if let staleMessage = viewModel.staleMessage {
                bannerRow(
                    message: staleMessage,
                    icon: "exclamationmark.triangle.fill",
                    tint: .orange
                )
            }

            if let errorMessage = viewModel.errorMessage, viewModel.flights.isEmpty == false {
                bannerRow(
                    message: errorMessage,
                    icon: "wifi.slash",
                    tint: .red
                )
            }

            ForEach(viewModel.flights, id: \.id.value) { flight in
                Button {
                    Task { await viewModel.selectFlight(flight) }
                } label: {
                    FlightRowView(flight: flight)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .accessibilityLabel(flightAccessibilityLabel(flight))
            }

            if viewModel.canLoadMorePages || viewModel.isLoadingNextPage {
                paginationFooter
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .onAppear {
                        Task { await viewModel.loadNextPage() }
                    }
            }
        }
            .padding(.vertical, 12)
        }
        .scrollIndicators(.hidden)
    }

    private func flightAccessibilityLabel(_ flight: Flight) -> String {
        AppStrings.localized(
            "flights.row.accessibility",
            flight.number,
            flight.origin,
            flight.destination,
            FlightStatusPresentation(status: flight.status).title
        )
    }

    private var skeletonList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(0..<8, id: \.self) { _ in
                    FlightSkeletonRow()
                        .padding(.horizontal, 16)
                        .accessibilityHidden(true)
                }
            }
            .padding(.vertical, 12)
        }
        .scrollIndicators(.hidden)
        .overlay(alignment: .topLeading) {
            Text(AppStrings.localized("flights.list.loading"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private func bannerRow(message: String, icon: String, tint: Color) -> some View {
        Label(message, systemImage: icon)
            .font(.footnote)
            .foregroundStyle(tint)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: .rect(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(tint.opacity(colorScheme == .dark ? 0.35 : 0.18), lineWidth: 1)
            }
            .padding(.horizontal, 16)
            .accessibilityLabel(message)
    }

    @ViewBuilder
    private var paginationFooter: some View {
        HStack {
            Spacer()
            if viewModel.isLoadingNextPage {
                ProgressView()
                    .accessibilityLabel(AppStrings.localized("flights.list.loadingMore"))
            } else {
                Color.clear
                    .frame(width: 1, height: 1)
                    .accessibilityHidden(true)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

}
