import SharedKernel

struct FlightListScreenState: Sendable {
    var flights: [Flight] = []
    var isLoading = false
    var isLoadingNextPage = false
    var canLoadMorePages = false
    var errorMessage: String?
    var staleMessage: String?
    private(set) var nextPage = 1

    var isShowingInitialSkeleton: Bool {
        isLoading && flights.isEmpty && errorMessage == nil
    }

    mutating func beginInitialLoad() -> Bool {
        guard !isLoading else { return false }
        isLoading = true
        errorMessage = nil
        staleMessage = nil
        return true
    }

    mutating func beginNextPageLoad() -> Bool {
        guard !isLoading else { return false }
        guard !isLoadingNextPage else { return false }
        guard canLoadMorePages else { return false }
        isLoadingNextPage = true
        errorMessage = nil
        return true
    }

    mutating func finishLoad(reset: Bool) {
        if reset {
            isLoading = false
        } else {
            isLoadingNextPage = false
        }
    }

    mutating func beginRefresh() -> String? {
        let previousStaleMessage = staleMessage
        isLoading = true
        errorMessage = nil
        staleMessage = nil
        return previousStaleMessage
    }

    mutating func finishRefresh() {
        isLoading = false
    }

    mutating func applyPage(_ result: FlightListResult, reset: Bool) {
        flights = reset ? result.flights : mergedFlights(incoming: result.flights)
        nextPage = result.page + 1
        canLoadMorePages = result.hasMorePages
        if result.isStale {
            staleMessage = AppStrings.localized("flights.list.staleWarning")
        } else if reset {
            staleMessage = nil
        }
    }

    mutating func applyRefresh(_ refreshedFlights: [Flight]) {
        flights = refreshedFlights
        staleMessage = nil
    }

    mutating func restoreStaleMessage(_ previousStaleMessage: String?) {
        staleMessage = previousStaleMessage
    }

    mutating func applyLoadFailure() {
        errorMessage = AppStrings.localized("flights.error.load")
    }

    private mutating func mergedFlights(incoming: [Flight]) -> [Flight] {
        var merged = flights
        for flight in incoming {
            if let index = merged.firstIndex(where: { $0.id == flight.id }) {
                merged[index] = flight
            } else {
                merged.append(flight)
            }
        }
        return merged
    }
}
