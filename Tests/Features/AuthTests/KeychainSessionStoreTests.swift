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
        let tracked = makeSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        let session = makeSession()

        try await context.sut.save(session: session)
        let restoredSession = await context.sut.currentSession()

        #expect(restoredSession == session)
        await context.sut.clear()
    }

    @Test("Keychain session store clears the stored session")
    func clearsSession() async throws {
        guard keychainWriteIsAvailable() else { return }
        let tracked = makeSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        try await context.sut.save(session: makeSession())
        await context.sut.clear()

        let restoredSession = await context.sut.currentSession()
        #expect(restoredSession == nil)
    }

    @Test("Keychain session store discards corrupted payloads")
    func clearsCorruptedPayload() async {
        guard keychainWriteIsAvailable() else { return }
        let credentials = uniqueCredentials()
        let tracked = makeSUT(credentials: credentials)
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        injectCorruptedPayload(service: credentials.service, account: credentials.account)

        let restoredSession = await context.sut.currentSession()

        #expect(restoredSession == nil)
        await context.sut.clear()
    }

    private func makeSUT(
        credentials: (service: String, account: String)? = nil,
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> TrackedTestContext<KeychainSessionStoreTestContext> {
        let credentials = credentials ?? uniqueCredentials()
        let sut = KeychainSessionStore(service: credentials.service, account: credentials.account)
        return makeLeakTrackedTestContext(
            KeychainSessionStoreTestContext(sut: sut),
            trackedInstances: sut,
            sourceLocation: sourceLocation
        )
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

private struct KeychainSessionStoreTestContext {
    let sut: KeychainSessionStore
}
