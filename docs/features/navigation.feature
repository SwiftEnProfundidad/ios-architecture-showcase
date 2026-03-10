Feature: Navegación event-driven (TCA-inspired)
  Como sistema de navegación
  Quiero procesar eventos de dominio y actualizar el estado de la app
  Para que la navegación sea predecible, testable y desacoplada

  Background:
    Given el sistema de navegación está inicializado

  Scenario: El reducer transforma un evento en un nuevo estado
    Given el estado actual es AppRoute.login
    When el sistema recibe el evento LoginSuccess con un pasajero válido
    Then el reducer produce un nuevo estado con AppRoute.flightList
    And el estado marca al pasajero como autenticado
    And el nuevo estado es inmutable e independiente del anterior

  Scenario: El event bus distribuye eventos a sus suscriptores
    Given hay un suscriptor registrado en el event bus
    When se publica el evento ShowFlightDetail con ID "IB3456"
    Then el suscriptor recibe el evento exactamente una vez
    And el evento contiene el ID de vuelo correcto

  Scenario: El coordinator aplica el reducer y actualiza el store
    Given el coordinator está escuchando el event bus
    And el estado actual es AppRoute.flightList
    When se publica el evento ShowFlightDetail con ID "IB3456"
    Then el coordinator aplica el reducer
    And el AppStateStore actualiza la ruta a AppRoute.flightDetail("IB3456")
    And el AppViewModel refleja el nuevo estado

  Scenario: El reducer no produce side effects
    Given cualquier estado de la app
    When el reducer procesa el mismo evento dos veces con el mismo estado
    Then produce exactamente el mismo estado de salida ambas veces

  Scenario: Evento no manejado no modifica el estado
    Given el estado actual es AppRoute.flightList
    When el sistema recibe un evento sin handler registrado
    Then el estado permanece sin cambios
    And no se lanza ningún error
