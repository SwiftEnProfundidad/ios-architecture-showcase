Feature: Tarjeta de embarque
  Como pasajero autenticado
  Quiero acceder a mi tarjeta de embarque
  Para embarcar en mi vuelo sin necesidad de papel

  Background:
    Given el pasajero está autenticado
    And el pasajero tiene al menos un vuelo

  Scenario: Acceso a tarjeta de embarque desde detalle de vuelo
    Given el pasajero está en el detalle de un vuelo
    When el pasajero solicita su tarjeta de embarque
    Then la app emite el evento ShowBoardingPass con el ID del vuelo
    And la navegación lleva al pasajero a la pantalla de tarjeta de embarque

  Scenario: Visualización del código QR de embarque
    Given el pasajero está en la pantalla de tarjeta de embarque
    When la tarjeta se carga correctamente
    Then se muestra el código QR generado por el componente UIKit nativo
    And el código QR es legible y representa los datos del vuelo

  Scenario: Datos de la tarjeta de embarque
    Given el pasajero tiene una tarjeta de embarque para un vuelo
    When se muestra la tarjeta de embarque
    Then se muestran el número de vuelo, asiento, puerta de embarque y hora límite
    And el nombre del pasajero aparece en la tarjeta

  Scenario: Regreso a la lista de vuelos desde tarjeta de embarque
    Given el pasajero está en la pantalla de tarjeta de embarque
    When el pasajero navega hacia atrás
    Then la navegación emite el evento BackToFlightDetail
    And la app vuelve al detalle del vuelo
