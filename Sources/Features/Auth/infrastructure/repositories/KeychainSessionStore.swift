import Foundation
import OSLog
import Security
import SharedKernel

public actor KeychainSessionStore: SessionStoreProtocol {
    private let logger = Logger(subsystem: "com.swiftenprofundidad.iOSArchitectureShowcase", category: "auth.session-store")
    private let service: String
    private let account: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(
        service: String = "com.swiftenprofundidad.iOSArchitectureShowcase.session",
        account: String = "authenticated-passenger"
    ) {
        self.service = service
        self.account = account
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    public func save(session: AuthSession) async throws {
        let payload = StoredSession(
            passengerID: session.passengerID.value,
            token: session.token,
            expiresAt: session.expiresAt
        )
        guard let data = try? encoder.encode(payload) else {
            logger.error("Failed to encode session payload")
            throw AuthError.storage
        }

        let query = baseQuery()
        let deleteStatus = SecItemDelete(query as CFDictionary)
        guard deleteStatus == errSecSuccess || deleteStatus == errSecItemNotFound else {
            logger.error("Failed to replace session in keychain. Status: \(deleteStatus, privacy: .public)")
            throw AuthError.storage
        }

        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            logger.error("Failed to save session to keychain. Status: \(status, privacy: .public)")
            throw AuthError.storage
        }
    }

    public func currentSession() async -> AuthSession? {
        var query = baseQuery()
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = true

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            logger.error("Failed to read session from keychain. Status: \(status, privacy: .public)")
            return nil
        }
        guard let data = item as? Data else {
            logger.error("Keychain session payload is not a Data value")
            return nil
        }
        guard let storedSession = try? decoder.decode(StoredSession.self, from: data) else {
            logger.error("Failed to decode session payload from keychain")
            await clear()
            return nil
        }
        return AuthSession(
            passengerID: PassengerID(storedSession.passengerID),
            token: storedSession.token,
            expiresAt: storedSession.expiresAt
        )
    }

    public func clear() async {
        let status = SecItemDelete(baseQuery() as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            logger.error("Failed to clear keychain session. Status: \(status, privacy: .public)")
            return
        }
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

private struct StoredSession: Codable {
    let passengerID: String
    let token: String
    let expiresAt: Date
}
