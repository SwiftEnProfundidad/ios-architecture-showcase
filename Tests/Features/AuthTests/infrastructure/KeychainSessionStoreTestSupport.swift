import AuthFeature
import Foundation
import Security
import SharedKernel
import Testing

func makeKeychainSessionStoreSUT(
    credentials: (service: String, account: String)? = nil,
    sourceLocation: SourceLocation = #_sourceLocation
) -> TrackedTestContext<KeychainSessionStoreTestContext> {
    let resolvedCredentials = credentials ?? uniqueKeychainCredentials()
    let sut = KeychainSessionStore(
        service: resolvedCredentials.service,
        account: resolvedCredentials.account
    )
    return makeLeakTrackedTestContext(
        KeychainSessionStoreTestContext(sut: sut),
        trackedInstances: sut,
        sourceLocation: sourceLocation
    )
}

func makeKeychainSession() -> AuthSession {
    AuthSession(
        passengerID: PassengerID("PAX-001"),
        token: "tok-keychain",
        expiresAt: fixedDate(hour: 12, minute: 0)
    )
}

func uniqueKeychainCredentials() -> (service: String, account: String) {
    let suffix = UUID().uuidString
    return (
        service: "com.swiftenprofundidad.iOSArchitectureShowcase.tests.\(suffix)",
        account: "authenticated-passenger-\(suffix)"
    )
}

func injectCorruptedKeychainPayload(service: String, account: String) {
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

func keychainWriteIsAvailable() -> Bool {
    let credentials = uniqueKeychainCredentials()
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

struct KeychainSessionStoreTestContext {
    let sut: KeychainSessionStore
}
