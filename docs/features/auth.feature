Feature: Autenticación de pasajero
  Como pasajero de una aerolínea
  Quiero autenticarme con mis credenciales
  Para acceder a mis vuelos y tarjeta de embarque

  Background:
    Given la app está en el estado inicial

  Scenario: Login con credenciales válidas
    Given un pasajero con email "carlos@iberia.com" y contraseña válida
    When el pasajero envía sus credenciales
    Then el sistema autentica al pasajero correctamente
    And el token de sesión queda almacenado de forma segura
    And la navegación emite el evento LoginSuccess
    And la app muestra la lista de vuelos

  Scenario: Login con credenciales inválidas
    Given un pasajero con email "carlos@iberia.com" y contraseña incorrecta
    When el pasajero envía sus credenciales
    Then el sistema rechaza la autenticación
    And se emite el evento LoginFailure
    And la app muestra un mensaje de error al pasajero
    And el token de sesión no se almacena

  Scenario: Login con email con formato inválido
    Given un pasajero con email "no-es-un-email" y cualquier contraseña
    When el pasajero intenta enviar sus credenciales
    Then el sistema rechaza el envío antes de llamar al gateway
    And se muestra un error de validación de formato de email

  Scenario: Cierre de sesión
    Given un pasajero autenticado
    When el pasajero cierra sesión
    Then el token de sesión se elimina del almacenamiento seguro
    And la navegación emite el evento Logout
    And la app muestra la pantalla de login

  Scenario: Sesión expirada
    Given un pasajero autenticado con token expirado
    When el pasajero intenta acceder a sus vuelos
    Then el sistema detecta la expiración del token
    And la navegación emite el evento SessionExpired
    And la app redirige al pasajero a la pantalla de login
