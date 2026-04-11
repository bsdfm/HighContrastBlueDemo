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

    private var blues: [(String, Color)] {
        [
            ("accentColor", .accentColor),
            (".systemBlue", Color(.systemBlue)),
            ("resolved\n(inherit)", manuallyResolved),
            ("resolved\n(hardcoded)", hardcodedResolved),
            ("Color.blue", .blue),
        ]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                info

                ForEach(blues, id: \.0) { label, color in
                    swatch(label, color: color)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Accent Blue Issue")
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    glassToolbar
                }
            }
        }
    }

    private var glassToolbar: some View {
        HStack(spacing: 12) {
            ForEach(blues, id: \.0) { _, color in
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.body)
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(color, in: .capsule)
            }
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
