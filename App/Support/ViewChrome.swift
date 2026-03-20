import SwiftUI

extension View {
    func appChrome<S: InsettableShape>(
        in shape: S,
        fill: Color = AppTheme.searchFieldSurface,
        stroke: Color = AppTheme.searchFieldStroke,
        lineWidth: CGFloat = 1
    ) -> some View {
        background(fill, in: shape)
            .overlay {
                shape.stroke(stroke, lineWidth: lineWidth)
            }
    }
}
