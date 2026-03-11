import AuthFeature
import Testing

@Suite("KeychainSessionStore", .serialized)
struct KeychainSessionStoreTests {
    @Test("Keychain session store saves and restores the authenticated session")
    func savesAndRestoresSession() async throws {
        guard keychainWriteIsAvailable() else { return }
        let tracked = makeKeychainSessionStoreSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        let session = makeKeychainSession()

        try await context.sut.save(session: session)
        let restoredSession = await context.sut.currentSession()

        #expect(restoredSession == session)
        await context.sut.clear()
    }

    @Test("Keychain session store clears the stored session")
    func clearsSession() async throws {
        guard keychainWriteIsAvailable() else { return }
        let tracked = makeKeychainSessionStoreSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        try await context.sut.save(session: makeKeychainSession())
        await context.sut.clear()

        let restoredSession = await context.sut.currentSession()
        #expect(restoredSession == nil)
    }

    @Test("Keychain session store discards corrupted payloads")
    func clearsCorruptedPayload() async {
        guard keychainWriteIsAvailable() else { return }
        let credentials = uniqueKeychainCredentials()
        let tracked = makeKeychainSessionStoreSUT(credentials: credentials)
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        injectCorruptedKeychainPayload(service: credentials.service, account: credentials.account)

        let restoredSession = await context.sut.currentSession()

        #expect(restoredSession == nil)
        await context.sut.clear()
    }
}
