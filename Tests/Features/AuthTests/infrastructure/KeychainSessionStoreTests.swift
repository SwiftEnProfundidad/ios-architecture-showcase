import AuthFeature
import Testing

@Suite("KeychainSessionStore", .serialized)
struct KeychainSessionStoreTests {
    @Test("Given an authenticated session, when it is saved and then read back, then the restored session matches")
    func savesAndRestoresSession() async throws {
        try #require(keychainWriteIsAvailable(), "Keychain not available in this environment")
        let tracked = makeKeychainSessionStoreSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        let session = makeKeychainSession()

        try await context.sut.save(session: session)
        let restoredSession = await context.sut.currentSession()

        #expect(restoredSession == session)
        await context.sut.clear()
    }

    @Test("Given a stored session, when the store is cleared, then reading the session yields no payload")
    func clearsSession() async throws {
        try #require(keychainWriteIsAvailable(), "Keychain not available in this environment")
        let tracked = makeKeychainSessionStoreSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        try await context.sut.save(session: makeKeychainSession())
        await context.sut.clear()

        let restoredSession = await context.sut.currentSession()
        #expect(restoredSession == nil)
    }

    @Test("Given corrupted data in the keychain, when the session is read, then the store discards it and exposes no session")
    func clearsCorruptedPayload() async throws {
        try #require(keychainWriteIsAvailable(), "Keychain not available in this environment")
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
