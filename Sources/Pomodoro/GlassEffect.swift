import SwiftUI

extension View {
    /// Rounded rect glass — macOS 26: `.glassEffect`, older: `.ultraThinMaterial`.
    @ViewBuilder
    func liquidGlass() -> some View {
        if #available(macOS 26, *) {
            self.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        } else {
            self.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    /// Capsule-shaped glass — for pills / dot rows.
    @ViewBuilder
    func liquidGlassCapsule() -> some View {
        if #available(macOS 26, *) {
            self.glassEffect(.regular, in: Capsule())
        } else {
            self.background(.ultraThinMaterial, in: Capsule())
        }
    }

    /// Tinted glass — macOS 26: `.glassEffect(.regular.tint(...))`, older: material only.
    @ViewBuilder
    func liquidGlassTinted(_ color: Color) -> some View {
        if #available(macOS 26, *) {
            self.glassEffect(.regular.tint(color), in: RoundedRectangle(cornerRadius: 16))
        } else {
            self.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    /// Padded glass card for content sections.
    @ViewBuilder
    func glassCard(padding: CGFloat = 16) -> some View {
        self.padding(padding).liquidGlass()
    }
}
