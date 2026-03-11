Feature: Passenger boarding pass
  As an authenticated passenger
  I want to open a reliable and scannable boarding pass
  So that I can board my flight without friction and with all relevant information

  Background:
    Given the passenger is authenticated
    And the passenger has access to a valid flight

  Rule: The boarding pass must only be shown for a flight accessible to the current passenger

  Scenario: Opening the boarding pass from flight detail
    Given the passenger is on the detail of a flight
    When they request the boarding pass
    Then navigation transitions to the boarding pass screen for the same flight
    And the selected flight remains preserved as navigation context

  Scenario: Flight without an issued boarding pass
    Given the passenger opens a flight that does not yet have an issued boarding pass
    When the app tries to load the boarding pass
    Then the app reports that the boarding pass is unavailable
    And navigation does not show invented data
    And the passenger can return to the flight detail

  Scenario: Boarding pass clears stale content when a reload fails
    Given the passenger already loaded a valid boarding pass
    And a subsequent reload for that same flight fails
    When the app finishes the failed reload
    Then the previously shown boarding pass is cleared
    And the app shows the controlled boarding pass error state

  Scenario: Attempt to access another passenger boarding pass
    Given a boarding pass exists for a different passenger
    When the passenger attempts to open it
    Then the system denies access
    And no external personal data is shown
    And the app keeps navigation in a safe state

  Rule: The boarding pass must show complete operational data and a genuinely usable QR code

  Scenario: Correct boarding pass rendering
    Given the boarding pass exists and can be retrieved
    When the screen loads successfully
    Then the passenger name, flight number, seat, gate, and boarding deadline are shown
    And the information belongs to the same flight from which the boarding pass was opened
    And the UI presents the pass as a coherent unit

  Scenario: Boarding deadline is shown in the departure airport timezone
    Given the boarding pass exists and can be retrieved
    And the device is configured in a timezone different from the departure airport
    When the screen loads successfully
    Then the boarding deadline matches the departure airport operational timezone
    And the value does not drift with the viewer device timezone

  Scenario: Rendering a scannable QR code
    Given the boarding pass has been loaded successfully
    When the passenger views the QR code
    Then a legible QR code is displayed
    And the QR code represents the boarding payload for the current flight
    And the QR is not replaced by a non-scannable placeholder

  Scenario: Boarding pass accessibility
    Given the boarding pass is visible
    When the passenger explores the screen with assistive technologies
    Then every relevant block exposes understandable labels
    And the passenger and flight summary can be understood without visual context
    And the QR code has an appropriate accessibility description

  Rule: Back navigation must rebuild the journey without losing context

  Scenario: Returning to flight detail from the boarding pass
    Given the passenger is on the boarding pass screen
    When they navigate back
    Then navigation returns to the detail of the same flight
    And the previous screen preserves the open flight context

  Scenario: Cancelling a load by leaving the screen
    Given the boarding pass is loading
    When the passenger leaves the screen before loading finishes
    Then the operation is cancelled safely
    And the app does not show a fake cancellation failure

  Scenario: Expired session when opening the boarding pass
    Given the passenger session has expired
    When the passenger tries to open their boarding pass
    Then the system blocks access to the protected screen
    And navigation returns to login
    And the expired session is invalidated
