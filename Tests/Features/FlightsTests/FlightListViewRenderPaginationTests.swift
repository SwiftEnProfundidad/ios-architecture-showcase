import FlightsFeature
import SharedKernel
import SharedNavigation
import Testing

@MainActor
@Suite("FlightListViewRender.Pagination")
struct FlightListViewRenderPaginationTests {
    @Test("Flight list renders the inline pagination spinner")
    func rendersPaginationSpinner() async throws {
        let context = makeFlightListRenderSUT(
            mode: .paginating(
                firstPage: FlightListResult(
                    flights: makeRenderFlights(range: 1...10),
                    source: .remote,
                    isStale: false,
                    page: 1,
                    hasMorePages: true
                ),
                secondPage: FlightListResult(
                    flights: makeRenderFlights(range: 11...20),
                    source: .remote,
                    isStale: false,
                    page: 2,
                    hasMorePages: true
                )
            )
        )

        await context.sut.load()
        let task = Task {
            await context.sut.loadNextPage()
        }
        await Task.yield()

        let data = try renderedPNG(from: FlightListView(viewModel: context.sut))

        #expect(context.sut.isLoadingNextPage)
        #expect(data.count > 1_000)

        await context.executor.resume()
        await task.value
    }
}
