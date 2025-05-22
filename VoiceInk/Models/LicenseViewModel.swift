import Foundation
import AppKit

@MainActor
class LicenseViewModel: ObservableObject {
    @Published var licenseKey: String = ""
    
    init() {
        // 初始化时不需要任何操作
    }
    
    var canUseApp: Bool {
        return true  // 始终返回 true
    }
}

extension Notification.Name {
    static let licenseStatusChanged = Notification.Name("licenseStatusChanged")
}
