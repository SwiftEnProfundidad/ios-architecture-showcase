Feature: Enterprise testing strategy and coverage governance
  As a technical reviewer
  I want the repository to expose measurable testing evidence
  So that quality claims are defendable and enforced instead of aspirational

  Rule: Coverage must be measurable from the local validation toolchain

  Scenario: Generating a filtered production coverage report
    Given the repository runs the Swift package test suite with code coverage enabled
    When the coverage gate evaluates the exported report
    Then the gate measures only production source files
    And generated files are excluded from the metric
    And test source files are excluded from the metric
    And the resulting percentage is printed in a human-readable summary

  Scenario: Failing when the configured coverage threshold is not met
    Given the production coverage percentage is below the configured threshold
    When the coverage gate runs
    Then the command fails
    And the output explains the measured percentage
    And the output explains the expected threshold

  Scenario: Succeeding when the configured coverage threshold is met
    Given the production coverage percentage is equal to or above the configured threshold
    When the coverage gate runs
    Then the command succeeds
    And the output confirms the repository is above the required threshold

  Scenario: Local validation defaults to the enterprise coverage threshold
    Given the repository runs local validation without overriding the coverage threshold
    When the validation script evaluates the production coverage gate
    Then the required threshold defaults to 85 percent

  Scenario: The repository declares the active Apple toolchain contract
    Given the repository defines its package and Xcode project manifests
    When the reviewer inspects the declared toolchain versions
    Then Swift 6.2 is declared as the active language mode
    And the current Xcode 26.3 toolchain is declared for local project generation

  Rule: Testing evidence must cover more than unit logic

  Scenario: Publishing the enterprise testing evidence matrix for this technical test
    Given the repository maintains architectural and testing governance documents
    When the technical reviewer inspects the remediation tracker
    Then the tracker describes unit, integration, regression, acceptance, and render smoke evidence
    And the tracker explains what exists today
    And the tracker explains what is intentionally out of scope for this delivery

  Rule: Critical screens and runtime wiring must have executable smoke evidence

  Scenario: Rendering the critical SwiftUI screens in their primary states
    Given the repository exposes critical screens for login, flight list, flight detail, and boarding pass
    When the test suite renders those screens in representative states
    Then each screen produces a non-empty render output
    And the output can be used as smoke evidence that the view hierarchy is structurally valid

  Scenario: Assembling the application runtime from composition
    Given the repository builds the runtime through CompositionRoot and feature assemblies
    When the test suite creates the composition entry points
    Then the login, list, detail, and boarding pass flows are assembled without crashing
    And the assembled screens can render in smoke tests

  Rule: Test construction must stay consistent with enterprise testing conventions

  Scenario: Building reference-type SUTs through factory helpers
    Given the repository contains tests for view models, coordinators, channels, and other reference types
    When a suite creates its subject under test
    Then the suite uses a dedicated makeSUT helper
    And the helper assembles the SUT together with the required collaborators
    And the helper tracks reference-type instances for memory leaks

  Scenario: Avoiding test-only visibility hacks for AppComposition
    Given the AppComposition module exposes public runtime contracts required by the test target
    When the tests import AppComposition
    Then the suites do not rely on @testable imports
    And the exercised public types remain reviewable through explicit module contracts
