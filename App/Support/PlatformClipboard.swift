import Foundation

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

enum PlatformClipboard {
    static var string: String? {
        get {
            #if canImport(AppKit)
            NSPasteboard.general.string(forType: .string)
            #elseif canImport(UIKit)
            UIPasteboard.general.string
            #else
            nil
            #endif
        }
        set {
            #if canImport(AppKit)
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()

            if let newValue {
                pasteboard.setString(newValue, forType: .string)
            }
            #elseif canImport(UIKit)
            UIPasteboard.general.string = newValue
            #endif
        }
    }
}
