import Foundation
import IOKit

class PolarService {
    private let organizationId = "Org"
    private let apiToken = "Token"
    private let baseURL = "https://api.polar.sh"
    
    struct LicenseValidationResponse: Codable {
        let status: String
        let id: String?
        let activation: ActivationResponse?
    }
    
    struct ActivationResponse: Codable {
        let id: String
    }
    
    struct ActivationRequest: Codable {
        let key: String
        let organization_id: String
        let label: String
        let meta: [String: String]
    }
    
    struct ActivationResult: Codable {
        let id: String
        let license_key: LicenseKeyInfo
    }
    
    struct LicenseKeyInfo: Codable {
        let status: String
    }
    
    // Generate a unique device identifier
    private func getDeviceIdentifier() -> String {
        // Use the macOS serial number or a generated UUID that persists
        if let serialNumber = getMacSerialNumber() {
            return serialNumber
        }
        
        // Fallback to a stored UUID if we can't get the serial number
        let defaults = UserDefaults.standard
        if let storedId = defaults.string(forKey: "VoiceInkDeviceIdentifier") {
            return storedId
        }
        
        // Create and store a new UUID if none exists
        let newId = UUID().uuidString
        defaults.set(newId, forKey: "VoiceInkDeviceIdentifier")
        return newId
    }
    
    // Try to get the Mac serial number
    private func getMacSerialNumber() -> String? {
        let platformExpert = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        if platformExpert == 0 { return nil }
        
        defer { IOObjectRelease(platformExpert) }
        
        if let serialNumber = IORegistryEntryCreateCFProperty(platformExpert, "IOPlatformSerialNumber" as CFString, kCFAllocatorDefault, 0) {
            return (serialNumber.takeRetainedValue() as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return nil
    }
    
    // Check if a license key requires activation
    func checkLicenseRequiresActivation(_ key: String) async throws -> (isValid: Bool, requiresActivation: Bool, activationsLimit: Int?) {
        // 始终返回有效的许可证，不需要激活
        return (isValid: true, requiresActivation: false, activationsLimit: nil)
    }
    
    // Activate a license key on this device
    func activateLicenseKey(_ key: String) async throws -> (activationId: String, activationsLimit: Int) {
        // 生成一个随机的激活ID
        let activationId = UUID().uuidString
        // 返回激活ID和无限设备限制
        return (activationId: activationId, activationsLimit: 0)
    }
    
    // Validate a license key with an activation ID
    func validateLicenseKeyWithActivation(_ key: String, activationId: String) async throws -> Bool {
        // 始终返回验证成功
        return true
    }
}

enum LicenseError: Error, LocalizedError {
    case activationFailed
    case validationFailed
    case activationNotRequired
    
    var errorDescription: String? {
        switch self {
        case .activationFailed:
            return "Failed to activate license on this device."
        case .validationFailed:
            return "License validation failed."
        case .activationNotRequired:
            return "This license does not require activation."
        }
    }
} 
