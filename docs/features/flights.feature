Feature: Passenger flight list and detail
  As an authenticated passenger
  I want to browse reliable flight information
  So that I can understand operational status, timing, and travel context before departure

  Background:
    Given the passenger is authenticated
    And the session is valid

  Rule: The list must only expose the authenticated passenger portfolio

  Scenario: Initial load with remote flight data
    Given the passenger has booked flights
    When the app loads the flight list
    Then the app shows only the authenticated passenger flights
    And each row displays number, origin, destination, departure time, and status
    And the list order is deterministic

  Scenario: Passenger without booked flights
    Given the passenger has no active or upcoming flights
    When the app loads the flight list
    Then the app shows a meaningful empty state
    And the screen does not expose a technical failure
    And navigation remains on the flight list

  Rule: The first load must communicate progress without layout jumps

  Scenario: Initial loading uses a skeleton list
    Given the passenger is opening the flight list for the first time
    And no flights have been loaded yet
    When the first page is still loading
    Then the app shows a skeleton version of the list layout
    And the skeleton remains visible long enough to be perceived as a loading state
    And the skeleton preserves the expected row rhythm and spacing
    And the app does not replace the screen with a blocking spinner

  Rule: The list must page incrementally without losing cache coherence

  Scenario: First page of a long list
    Given the passenger has a long flight history
    When the app loads the first page
    Then the app shows only the first block of ten flights
    And the UI still implies that more content can be loaded
    And the order remains deterministic

  Scenario: Loading the next page at the pagination footer
    Given the passenger is already looking at the first page of a long list
    When the passenger reaches the pagination footer at the end of the visible block
    Then the app loads the next block of ten flights
    And the new flights are appended to the existing list
    And previously loaded flights are not duplicated

  Scenario: Showing an inline loading indicator while the next page is loading
    Given the passenger has already loaded the first ten flights
    And the app started loading the next block
    When the next page request is still in progress
    Then the current flights remain visible
    And the app shows an inline loading spinner at the bottom of the list
    And the passenger can keep scrolling without a blocked screen

  Scenario: The next page is not requested before the footer is reached
    Given the passenger is still browsing inside the current visible block
    When the passenger has not reached the pagination footer yet
    Then the app does not request the next page
    And the current block remains stable on screen

  Scenario: Additional page served from cache when the network fails
    Given the passenger has already loaded several flight pages
    And a valid local copy of the complete snapshot exists
    And the network is currently unavailable
    When the app loads another page
    Then that page is served from local cache
    And the app preserves pagination and ordering
    And the app warns that the information may be stale

  Rule: The app must degrade gracefully when connectivity fails

  Scenario: Flights served from local cache while offline
    Given the passenger has already loaded flights before
    And a valid local copy of the latest snapshot exists
    And the network is currently unavailable
    When the app tries to load the list
    Then the flights are served from local cache
    And the list still shows the latest known snapshot
    And the app warns that the information may be stale

  Scenario: Cache persistence failure does not invalidate a successful remote read
    Given the remote flight catalog can be read successfully
    And the local cache location is temporarily unavailable for writes
    When the app loads the list
    Then the remote flights are still shown
    And the app does not report a remote connectivity failure

  Scenario: No network and no cache available
    Given the network is unavailable
    And no local flight cache exists
    When the app tries to load the list
    Then the list does not show invented or partial data
    And the app presents a recoverable loading failure
    And the passenger can retry when connectivity returns

  Rule: The flight detail must provide maximum context without blocking on secondary dependencies

  Scenario: Flight detail with destination weather available
    Given the passenger selects a specific flight
    And destination weather information is available
    When the app loads the flight detail
    Then the flight operational data is shown
    And destination weather is also shown
    And the detail belongs to the selected flight

  Scenario: Flight detail is resolved independently from list pagination
    Given the passenger opens a specific flight detail from a protected entry point
    And the requested flight is not part of the currently visible paged block
    When the app loads the flight detail
    Then the app resolves that flight directly
    And the current paged list state does not block the detail access

  Scenario: Operational departure time is shown in the airport timezone
    Given the passenger selects a specific flight
    And the device is configured in a timezone different from the departure airport
    When the app renders the flight list or the flight detail
    Then the departure clock time matches the departure airport operational timezone
    And the value does not drift with the viewer device timezone

  Scenario: Flight detail when weather lookup fails
    Given the passenger selects a specific flight
    And destination weather cannot be retrieved
    When the app loads the flight detail
    Then the main flight detail is still shown
    And the missing weather does not block the screen
    And the app treats weather as optional information

  Scenario: Nonexistent or inaccessible flight
    Given the passenger attempts to open a nonexistent flight or one that does not belong to them
    When the app loads the flight detail
    Then the system rejects access to that resource
    And the app shows a controlled failure
    And no other passenger data is exposed

  Rule: Refresh must stay concurrent without breaking visual coherence or ordering

  Scenario: Refreshing multiple visible flights with a visible update
    Given the passenger has several visible flights on screen
    When the passenger refreshes the list
    Then the flights are refreshed concurrently
    And the list updates once the refresh is consolidated
    And the visual ordering remains stable
    And changed statuses are reflected in the UI

  Scenario: Partial refresh when one flight update fails
    Given the passenger refreshes a list containing several flights
    And one individual flight update fails
    When the refresh cycle ends
    Then the app preserves the last coherent list snapshot
    And the UI does not end in a mixed or inconsistent state
    And the passenger is informed that the full refresh could not complete

  Scenario: Pull to refresh on an already paged list
    Given the passenger has already loaded several flight pages
    When the passenger pulls to refresh
    Then the app refreshes the visible flights concurrently
    And the loaded list length is preserved
    And the paged visual order remains stable
    And the cache is updated with the consolidated snapshot

  Scenario: Session expiry while loading or refreshing flights
    Given the passenger session expires while the list is loading or refreshing
    When the app detects the expiration
    Then access to protected routes is cancelled
    And the stored session is removed
    And navigation returns to the login route

  Scenario: Logging out from the flight list ends the protected session
    Given the passenger is viewing the flight list
    When the passenger logs out from that screen
    Then the stored session is removed
    And navigation returns to the login route
    And the list does not keep loading protected content

  Scenario: Cancelling a load by leaving the screen
    Given a flight load or refresh is in progress
    When the passenger leaves the screen before it finishes
    Then the operation is cancelled safely
    And the app does not show a fake cancellation error
    And the visible state remains coherent
