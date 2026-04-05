Feature: Passenger authentication and session management
  As an airline passenger
  I want to authenticate and keep a valid session
  So that I can access only my flights and my boarding pass

  Background:
    Given the app starts on the login route
    And there is no active authenticated session

  Rule: Only valid credentials can create a usable session

  Scenario: Login with valid credentials
    Given a registered passenger with email "carlos@iberia.com" and a valid password
    When the passenger submits their credentials
    Then the system authenticates the passenger successfully
    And an authenticated session is created with passengerID, token, and expiration date
    And the session token is stored securely
    And navigation transitions to the flight list route
    And the login screen is no longer visible

  Scenario: Evaluation quick access using local bootstrap auth
    Given the app is configured with local bootstrap authentication
    And an evaluation quick access action is available on the login screen
    When the evaluator requests quick access
    Then the system authenticates the passenger without requiring typed credentials
    And it executes the same remote authentication flow used by the form
    And navigation transitions to the flight list route
    And the authenticated session is persisted securely

  Scenario: Login with incorrect credentials
    Given a registered passenger with email "carlos@iberia.com"
    And the submitted password does not match the registered one
    When the passenger submits credentials
    Then the system rejects the authentication
    And no authenticated session is created
    And the token is not stored
    And navigation remains on the login route
    And the app shows an invalid credentials error

  Scenario: Network failure during authentication
    Given the authentication gateway is unavailable
    When the passenger submits valid credentials
    Then the system reports a connectivity problem
    And no authenticated session is created
    And navigation remains on the login route
    And the passenger can retry the operation

  Rule: Successful HTTP status alone is not enough; the login payload must be decodable

  Scenario: Server returns HTTP success with a malformed login payload
    Given the authentication transport completes successfully
    And the gateway receives HTTP 200 with a body that cannot be decoded as a login session
    When the passenger submits valid credentials
    Then the system rejects the authentication
    And no authenticated session is created
    And navigation remains on the login route
    And the app shows the same connectivity error string used for network failures

  Rule: Input validation must stop invalid requests before leaving the device

  Scenario Outline: Malformed credentials are rejected before remote authentication is invoked
    Given the passenger enters email "<email>" and password "<password>"
    When the passenger attempts to submit credentials
    Then the system rejects the submission because of "<reason>"
    And the authentication gateway is not invoked
    And no authenticated session is created
    And navigation remains on the login route

    Examples:
      | email             | password    | reason                |
      | not-an-email      | Secure123!  | invalid email format  |
      |                   | Secure123!  | email is required     |
      | carlos@iberia.com |             | password is required  |

  Scenario: Manual sign-in normalizes the typed email before authentication
    Given the passenger enters the email "  Carlos@Iberia.com "
    When the passenger submits valid credentials
    Then the authentication flow receives "carlos@iberia.com"
    And the visible email field keeps the normalized address

  Scenario: The email field behaves like an email entry control
    Given the passenger is on the login screen
    When the app renders the email input
    Then the field disables autocorrection
    And the field neutralizes automatic capitalization through visible normalization
    And the field keeps typed email input normalized for sign-in

  Scenario: Secure storage fails after authentication succeeds
    Given the gateway authenticates the passenger successfully
    And secure session storage fails while persisting the token
    When the passenger submits credentials
    Then the session is treated as incomplete
    And the passenger remains unauthenticated
    And navigation remains on the login route
    And the app reports a recoverable failure

  Rule: The session must remain coherent during its whole lifecycle

  Rule: Launch behavior must be an explicit runtime policy

  Scenario: Restoring a valid session after relaunch with a configured backend
    Given a secure persisted session already exists
    And the session has not expired
    And the app is configured against a real authentication backend
    When the passenger opens the app again
    Then the app restores the authenticated session
    And navigation enters the flight list directly
    And the login form is not shown again

  Scenario: Local bootstrap mode always starts from the login route
    Given a secure persisted session already exists
    And the session has not expired
    And the app is configured with local bootstrap authentication
    When the passenger opens the app again
    Then the app clears the previously persisted session
    And navigation remains on the login route
    And the login form is shown again
    And the startup behavior is determined by the configured runtime mode

  Scenario: Expired session while entering a protected area
    Given a persisted session exists with an expired date
    When the passenger tries to access their flights
    Then the system detects expiration before showing protected information
    And the stored session is invalidated and removed
    And navigation returns to the login route
    And the app shows a message explaining that the session expired

  Scenario: Logging out from a protected area
    Given the passenger is authenticated and currently inside a protected route
    When the passenger requests logout
    Then the stored session is removed securely
    And the authenticated app state becomes empty again
    And navigation returns to the login route
    And no protected screen remains in the stack

  Scenario: Repeated taps while a login request is in flight
    Given the passenger already started a valid login attempt
    And the system response is still pending
    When the passenger taps the access button again
    Then the app does not launch a second concurrent authentication
    And the loading state remains coherent
    And the final outcome depends on a single authentication attempt
