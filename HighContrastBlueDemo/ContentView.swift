import SwiftUI

// Minimal reproduction: In Dark Mode + "Increase Contrast",
// `Color.accentColor` on a filled background becomes a lighter
// blue that's harder to read. Attempting to resolve
// `UIColor.systemBlue` with light-mode traits via
// `resolvedColor(with:)` does not match what the system
// actually renders in Light Mode + Increase Contrast.

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast

    /// Resolve systemBlue against current traits but force
    /// light mode — inherits real gamut, level, etc.
    @MainActor private var manuallyResolved: Color {
        let base = UITraitCollection.current
        let light = base.modifyingTraits { mutable in
            mutable.userInterfaceStyle = .light
        }
        return Color(
            UIColor.systemBlue.resolvedColor(with: light)
        )
    }

    /// Hardcoded traits (no inherited gamut/level).
    @MainActor private var hardcodedResolved: Color {
        Color(
            UIColor.systemBlue.resolvedColor(
                with: UITraitCollection { traits in
                    traits.userInterfaceStyle = .light
                    traits.accessibilityContrast = .high
                }
            )
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                info

                Group {
                    swatch(
                        "Color.accentColor",
                        color: .accentColor
                    )
                    swatch(
                        "Color(.systemBlue)",
                        color: Color(.systemBlue)
                    )
                    swatch(
                        "resolved (inherit traits,\nforce .light)",
                        color: manuallyResolved
                    )
                    swatch(
                        "resolved (hardcoded\n.light + .high)",
                        color: hardcodedResolved
                    )
                    swatch(
                        "Color.blue",
                        color: .blue
                    )
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Accent Blue Issue")
        }
    }

    private var info: some View {
        VStack(spacing: 4) {
            Text("Scheme: \(String(describing: colorScheme))")
            Text("Contrast: \(String(describing: contrast))")
        }
        .font(.caption.monospaced())
        .foregroundStyle(.secondary)
    }

    private func swatch(
        _ label: String,
        color: Color
    ) -> some View {
        HStack {
            Text(label)
                .font(.caption.monospaced())
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
            Text("Selected")
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    color, in: .rect(cornerRadius: 8)
                )
        }
    }
}

#Preview {
    ContentView()
}
