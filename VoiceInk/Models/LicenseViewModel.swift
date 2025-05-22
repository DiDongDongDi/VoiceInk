import Foundation
import AppKit

@MainActor
class LicenseViewModel: ObservableObject {
    enum LicenseState: Equatable {
        case trial(daysRemaining: Int)
        case trialExpired
        case licensed
    }
    
    @Published private(set) var licenseState: LicenseState = .trial(daysRemaining: 7)  // Default to trial
    @Published var licenseKey: String = ""
    @Published var isValidating = false
    @Published var validationMessage: String?
    @Published private(set) var activationsLimit: Int = 0
    
    private let trialPeriodDays = 7
    private let polarService = PolarService()
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadLicenseState()
    }
    
    func startTrial() {
        // Only set trial start date if it hasn't been set before
        if userDefaults.trialStartDate == nil {
            userDefaults.trialStartDate = Date()
            licenseState = .trial(daysRemaining: trialPeriodDays)
            NotificationCenter.default.post(name: .licenseStatusChanged, object: nil)
        }
    }
    
    func validateLicense() async {
        guard !licenseKey.isEmpty else {
            validationMessage = "Please enter a license key"
            return
        }
        
        isValidating = true
        validationMessage = nil
        
        do {
            let licenseCheck = try await polarService.checkLicenseRequiresActivation(licenseKey)
            
            if !licenseCheck.isValid {
                validationMessage = "Invalid license key"
                isValidating = false
                return
            }
            
            // 保存许可证密钥
            userDefaults.licenseKey = licenseKey
            
            // 设置无限设备限制
            self.activationsLimit = 0
            userDefaults.set(false, forKey: "VoiceInkLicenseRequiresActivation")
            
            // 更新许可证状态
            licenseState = .licensed
            validationMessage = "License activated successfully!"
            NotificationCenter.default.post(name: .licenseStatusChanged, object: nil)
            
        } catch {
            validationMessage = "Error validating license: \(error.localizedDescription)"
        }
        
        isValidating = false
    }
    
    private func loadLicenseState() {
        if let licenseKey = userDefaults.licenseKey {
            self.licenseKey = licenseKey
            licenseState = .licensed
            self.activationsLimit = 0  // 设置为无限设备限制
        } else if let trialStartDate = userDefaults.trialStartDate {
            let daysRemaining = calculateTrialDaysRemaining(from: trialStartDate)
            if daysRemaining > 0 {
                licenseState = .trial(daysRemaining: daysRemaining)
            } else {
                licenseState = .trialExpired
            }
        }
    }
    
    private func calculateTrialDaysRemaining(from startDate: Date) -> Int {
        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: .day, value: trialPeriodDays, to: startDate)!
        let remaining = calendar.dateComponents([.day], from: Date(), to: endDate)
        return max(0, remaining.day ?? 0)
    }
    
    var canUseApp: Bool {
        switch licenseState {
        case .licensed, .trial:
            return true
        case .trialExpired:
            return false
        }
    }
    
    func openPurchaseLink() {
        if let url = URL(string: "https://tryvoiceink.com/buy") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func removeLicense() {
        // Remove both license key and trial data
        userDefaults.licenseKey = nil
        userDefaults.activationId = nil
        userDefaults.set(false, forKey: "VoiceInkLicenseRequiresActivation")
        userDefaults.trialStartDate = nil
        userDefaults.set(false, forKey: "VoiceInkHasLaunchedBefore")  // Allow trial to restart
        
        licenseState = .trial(daysRemaining: trialPeriodDays)  // Reset to trial state
        licenseKey = ""
        validationMessage = nil
        NotificationCenter.default.post(name: .licenseStatusChanged, object: nil)
        loadLicenseState()
    }
}

extension Notification.Name {
    static let licenseStatusChanged = Notification.Name("licenseStatusChanged")
}

// Add UserDefaults extensions for storing activation ID
extension UserDefaults {
    var activationId: String? {
        get { string(forKey: "VoiceInkActivationId") }
        set { set(newValue, forKey: "VoiceInkActivationId") }
    }
}
