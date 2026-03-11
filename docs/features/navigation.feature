Feature: Event-driven application navigation
  As the navigation system
  I want to transform events into a single observable state
  So that the app flow remains predictable, auditable, and decoupled from the UI

  Background:
    Given the navigation system is initialized
    And an observable state store exists

  Rule: The visible route must derive from a single source of truth

  Scenario: A valid session start transitions from login to the authenticated home
    Given the current state is the login route
    And the passenger is not authenticated
    When the system receives a valid session start event
    Then the new state contains a valid authenticated session
    And the visible root route becomes the authenticated home
    And the previous state is not mutated

  Scenario: Replacing the protected stack with a primary detail destination
    Given the current state is the authenticated home
    And the passenger is authenticated
    When the system receives a protected path request for context "IB3456"
    Then the new state contains the primary detail destination for "IB3456"
    And protected navigation remains associated with the current session

  Scenario: Appending a secondary destination after the primary detail
    Given the current state contains the primary detail destination for "IB3456"
    And the passenger is authenticated
    When the system receives a protected path request for a primary and secondary destination
    Then the route stack first contains the primary detail destination
    And it then appends the secondary destination for the same context

  Scenario: Synchronizing the visible path normalizes invalid stacks
    Given the current state is the authenticated home
    And the passenger is authenticated
    When the system synchronizes a stack containing only a secondary destination for "IB3456"
    Then the resulting stack keeps the primary detail destination for "IB3456"
    And it then appends the secondary destination for the same context

  Scenario: Synchronizing back navigation preserves only the primary detail
    Given the current stack contains the primary and secondary destinations for "IB3456"
    When the system synchronizes the visible path to keep only the primary destination
    Then the resulting stack keeps only the primary detail for "IB3456"
    And the authenticated session remains intact

  Rule: Protected routes must not activate without a valid session

  Scenario Outline: A protected event does not modify state without authentication
    Given there is no valid authenticated session
    And the current state is login
    When the system receives the protected navigation input "<event>"
    Then the state remains unchanged
    And no protected route becomes active

    Examples:
      | event               |
      | protectedPath       |
      | synchronizedPath    |

  Scenario: An expired session requesting a protected path is invalidated once
    Given the passenger has an expired authenticated session
    When the system receives a protected path request for context "IB3456"
    Then the state returns to login
    And the protected route stack becomes empty
    And persisted authentication is invalidated exactly once

  Scenario: Logout clears all protected navigation
    Given the passenger is authenticated
    And the stack contains active protected routes
    When the system processes logout
    Then the session disappears from state
    And the protected route stack becomes empty
    And the visible route returns to login

  Scenario: Session expiry clears all protected navigation
    Given the passenger is authenticated
    And the stack contains active protected routes
    When the system detects session expiry
    Then the authenticated state is invalidated
    And the protected route stack becomes empty
    And the visible route returns to login

  Rule: The navigation pipeline must be deterministic and observable

  Scenario: The reducer is pure for identical input
    Given any valid navigation state
    When the reducer processes the same event twice over the same state
    Then it produces exactly the same output state both times

  Scenario: The event bus distributes an event exactly once to each active subscriber
    Given an active subscriber is registered in the navigation bus
    When a protected path request for context "IB3456" is published
    Then the subscriber receives exactly one event
    And the event contains the correct protected context identifier

  Scenario: Coordinator and store reflect the full transition
    Given the coordinator is listening to the bus
    And the current visible state is the authenticated home
    When a protected path request for context "IB3456" is published
    Then the coordinator applies the transition to the store
    And the application view model reflects the new state
    And the UI can navigate to detail without additional logic outside state

  Rule: State projection and visible-path synchronization must stay explicit

  Scenario: Visible back navigation is synchronized through a dedicated command channel
    Given the application state projects the primary and secondary destinations for "IB3456"
    When the user keeps only the primary destination visible
    Then the UI publishes the visible protected path through the synchronization channel
    And the application view model remains responsible only for reflecting store updates
