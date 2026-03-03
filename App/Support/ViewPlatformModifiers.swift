import SwiftUI

extension View {
    @ViewBuilder
    func inlineNavigationTitleDisplayMode() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}
