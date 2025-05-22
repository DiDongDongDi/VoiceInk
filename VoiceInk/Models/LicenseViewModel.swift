import Foundation
import AppKit

enum LicenseState {
    case unlicensed
    case licensed
}

@MainActor
class LicenseViewModel: ObservableObject {
    @Published var licenseKey: String = ""
    @Published var licenseState: LicenseState = .unlicensed
    @Published var isValidating: Bool = false
    @Published var validationMessage: String? = nil
    
    init() {
        // 初始化时不需要任何操作
    }
    
    var canUseApp: Bool {
        return true  // 始终返回 true
    }
    
    func validateLicense() async {
        isValidating = true
        defer { isValidating = false }
        
        // 这里添加许可证验证逻辑
        if licenseKey.isEmpty {
            validationMessage = "请输入许可证密钥"
            licenseState = .unlicensed
        } else {
            licenseState = .licensed
            validationMessage = "验证成功"
        }
    }
    
    func removeLicense() {
        licenseKey = ""
        licenseState = .unlicensed
        validationMessage = nil
    }
}

extension Notification.Name {
    static let licenseStatusChanged = Notification.Name("licenseStatusChanged")
}
