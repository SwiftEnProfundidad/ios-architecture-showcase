import AuthFeature
import Foundation
import Security
import SharedKernel
import Testing

@Suite("KeychainSessionStore", .serialized)
struct KeychainSessionStoreTests {
    @Test("Keychain session store saves and restores the authenticated session")
    func savesAndRestoresSession() async throws {
        guard keychainWriteIsAvailable() else { return }
        let store = makeStore()
        let session = makeSession()

        try await store.save(session: session)
        let restoredSession = await store.currentSession()

        #expect(restoredSession == session)
        await store.clear()
    }

    @Test("Keychain session store clears the stored session")
    func clearsSession() async throws {
        guard keychainWriteIsAvailable() else { return }
        let store = makeStore()

        try await store.save(session: makeSession())
        await store.clear()

        let restoredSession = await store.currentSession()
        #expect(restoredSession == nil)
    }

    @Test("Keychain session store discards corrupted payloads")
    func clearsCorruptedPayload() async {
        guard keychainWriteIsAvailable() else { return }
        let credentials = uniqueCredentials()
        let store = KeychainSessionStore(
            service: credentials.service,
            account: credentials.account
        )

        injectCorruptedPayload(service: credentials.service, account: credentials.account)

        let restoredSession = await store.currentSession()

        #expect(restoredSession == nil)
        await store.clear()
    }

    private func makeStore() -> KeychainSessionStore {
        let credentials = uniqueCredentials()
        return KeychainSessionStore(service: credentials.service, account: credentials.account)
    }

    private func makeSession() -> AuthSession {
        AuthSession(
            passengerID: PassengerID("PAX-001"),
            token: "tok-keychain",
            expiresAt: fixedDate(hour: 12, minute: 0)
        )
    }

    private func uniqueCredentials() -> (service: String, account: String) {
        let suffix = UUID().uuidString
        return (
            service: "com.swiftenprofundidad.iOSArchitectureShowcase.tests.\(suffix)",
            account: "authenticated-passenger-\(suffix)"
        )
    }

    private func injectCorruptedPayload(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData as String] = Data("not-json".utf8)
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(attributes as CFDictionary, nil)
        #expect(status == errSecSuccess)
    }

    private func keychainWriteIsAvailable() -> Bool {
        let credentials = uniqueCredentials()
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: credentials.service,
            kSecAttrAccount as String: credentials.account
        ]

        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData as String] = Data("probe".utf8)
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(attributes as CFDictionary, nil)
        if status == errSecMissingEntitlement {
            return false
        }

        #expect(status == errSecSuccess)
        SecItemDelete(query as CFDictionary)
        return true
    }
}
