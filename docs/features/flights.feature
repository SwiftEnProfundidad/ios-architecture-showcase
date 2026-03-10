Feature: Consulta de vuelos del pasajero
  Como pasajero autenticado
  Quiero consultar mis vuelos
  Para conocer el estado, puerta y horario de cada vuelo

  Background:
    Given el pasajero está autenticado

  Scenario: Carga inicial de vuelos
    Given el pasajero tiene vuelos reservados
    When la app carga la lista de vuelos
    Then se muestran todos los vuelos del pasajero
    And cada vuelo muestra número de vuelo, origen, destino y estado

  Scenario: Carga paralela de vuelo y estado meteorológico
    Given el pasajero selecciona un vuelo concreto
    When la app carga el detalle del vuelo
    Then se cargan simultáneamente el detalle del vuelo y la información meteorológica
    And ambos datos se muestran cuando los dos están disponibles
    And si la carga meteorológica falla, el detalle del vuelo se muestra igualmente

  Scenario: Vuelos cargados desde caché cuando no hay red
    Given el pasajero ha consultado sus vuelos previamente
    And actualmente no hay conexión de red
    When la app intenta cargar los vuelos
    Then se sirven los vuelos desde la caché local
    And se indica al pasajero que los datos pueden no estar actualizados

  Scenario: Refresco concurrente de múltiples vuelos
    Given el pasajero tiene tres vuelos activos
    When el pasajero refresca la lista
    Then los tres vuelos se actualizan de forma concurrente con TaskGroup
    And la lista se actualiza cuando todos los vuelos han sido refrescados

  Scenario: Vuelo con estado modificado
    Given un vuelo con estado "En hora"
    When el estado cambia a "Retrasado"
    Then la lista refleja el nuevo estado del vuelo
    And se indica visualmente el cambio de estado
