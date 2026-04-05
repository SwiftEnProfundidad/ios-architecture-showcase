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
            .padding(.horizontal, ShowcaseLayout.Inset.screenXWide)
        } else {
            flightList
        }
    }

    private var flightList: some View {
        ScrollView {
            LazyVStack(spacing: ShowcaseLayout.Space.lg) {
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
                .padding(.horizontal, ShowcaseLayout.Inset.row)
                .accessibilityLabel(flightAccessibilityLabel(flight))
            }

            if viewModel.canLoadMorePages || viewModel.isLoadingNextPage {
                paginationFooter
                    .padding(.horizontal, ShowcaseLayout.Inset.row)
                    .padding(.vertical, ShowcaseLayout.Inset.bannerVertical)
                    .onAppear {
                        Task { await viewModel.loadNextPage() }
                    }
            }
        }
            .padding(.vertical, ShowcaseLayout.Inset.listVertical)
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
            LazyVStack(spacing: ShowcaseLayout.Space.lg) {
                ForEach(0..<8, id: \.self) { _ in
                    FlightSkeletonRow()
                        .padding(.horizontal, ShowcaseLayout.Inset.row)
                        .accessibilityHidden(true)
                }
            }
            .padding(.vertical, ShowcaseLayout.Inset.listVertical)
        }
        .scrollIndicators(.hidden)
        .overlay(alignment: .topLeading) {
            Text(AppStrings.localized("flights.list.loading"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, ShowcaseLayout.Inset.loadingLabelX)
                .padding(.top, ShowcaseLayout.Inset.loadingLabelTop)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private func bannerRow(message: String, icon: String, tint: Color) -> some View {
        Label(message, systemImage: icon)
            .font(.footnote)
            .foregroundStyle(tint)
            .padding(ShowcaseLayout.Inset.bannerContent)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: .rect(cornerRadius: ShowcaseLayout.Radius.banner))
            .overlay {
                RoundedRectangle(cornerRadius: ShowcaseLayout.Radius.banner)
                    .strokeBorder(tint.opacity(colorScheme == .dark ? 0.35 : 0.18), lineWidth: ShowcaseLayout.Line.stroke)
            }
            .padding(.horizontal, ShowcaseLayout.Inset.row)
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
                    .frame(width: ShowcaseLayout.Skeleton.List.paginationSpacer, height: ShowcaseLayout.Skeleton.List.paginationSpacer)
                    .accessibilityHidden(true)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

}
