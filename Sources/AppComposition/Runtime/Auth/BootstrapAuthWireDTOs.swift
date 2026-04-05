import Foundation

struct BootstrapAuthLoginBody: Codable {
    let email: String
    let password: String
}

struct BootstrapAuthSessionBody: Codable {
    let passengerID: String
    let token: String
    let expiresAt: Date
}
