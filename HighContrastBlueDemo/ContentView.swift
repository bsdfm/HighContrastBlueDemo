import SwiftUI

// MARK: - Reproduction

//
// Minimum repro of the "Increase Contrast applied more than once
// to Color.accentColor" issue observed in a SwiftUI app with this
// shape: TabView → Tab → NavigationStack → content.
//
// Render the SAME `Color.accentColor` (and `Color(uiColor: .systemBlue)`
// and a literal sRGB reference) three times, in three contexts:
//
//   • Group 1 — OVERLAY on the TabView (outside any NavigationStack)
//   • Group 2 — inside a NavigationStack's content, plus its toolbar
//   • Group 3 — inside a presented sheet (no NavigationStack wrap)
//
// Expected behavior: with Increase Contrast OFF, every swatch in
// every group is exactly the same color. With Increase Contrast ON,
// the accent still ought to render the same in all three groups.
//
// Observed behavior: with Increase Contrast ON,
//   • Group 1 is shifted once (the normal, expected HC adjustment)
//   • Group 2 is shifted MORE — darker in light mode, lighter in
//     dark mode — as if the adjustment is applied twice
//   • Group 3 sits between Group 1 and Group 2
//
// The literal sRGB swatch is the control: it doesn't participate in
// the accent pipeline at all, so it should be identical in all three
// contexts (no HC adjustment) and serve as a reference line.

struct RootView: View {
    @State private var showSheet = false

    var body: some View {
        TabView {
            Tab("Nav Stack", systemImage: "list.bullet") {
                NavigationStack {
                    InNavStackView(showSheet: $showSheet)
                }
            }
            Tab("Other", systemImage: "circle") {
                Text("Other tab — unused")
            }
        }
        // Group 1 — OUTSIDE any NavigationStack, sibling of TabView
        .overlay(alignment: .top) {
            ProbeRow(label: "GROUP 1 · OVERLAY")
                .padding(.top, 60)
                .padding(.horizontal, 12)
                .allowsHitTesting(false)
        }
        .sheet(isPresented: $showSheet) {
            InSheetView()
        }
    }
}

// MARK: - Group 2 — inside NavigationStack

private struct InNavStackView: View {
    @Binding var showSheet: Bool
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Scheme: \(String(describing: colorScheme))")
                .font(.caption.monospaced())
            Text("Contrast: \(String(describing: contrast))")
                .font(.caption.monospaced())

            ProbeRow(label: "GROUP 2 · IN NAV STACK")

            Button("Present sheet → Group 3") {
                showSheet = true
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
        .navigationTitle("Accent Repro")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                // Toolbar item — also Group 2; should pick up the
                // same shift as in-NavStack content
                Image(systemName: "star.fill")
                    .accessibilityLabel("Toolbar star")
            }
        }
    }
}

// MARK: - Group 3 — inside a sheet

private struct InSheetView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            ProbeRow(label: "GROUP 3 · IN SHEET")

            Button("Dismiss") { dismiss() }
                .buttonStyle(.bordered)
        }
        .padding()
    }
}

// MARK: - Probe row

/// Three swatches rendered via different accent-resolution paths.
/// Same row is used in each group so the three groups are directly
/// comparable.
private struct ProbeRow: View {
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption2.bold().monospaced())

            HStack(spacing: 0) {
                swatch(
                    "ACCENT",
                    fill: AnyShapeStyle(Color.accentColor)
                )
                swatch(
                    "UIKIT",
                    fill: AnyShapeStyle(Color(uiColor: .systemBlue))
                )
                swatch(
                    "sRGB",
                    fill: AnyShapeStyle(
                        Color(
                            .sRGB,
                            red: 0 / 255,
                            green: 136 / 255,
                            blue: 255 / 255,
                            opacity: 1
                        )
                    )
                )
            }
            .frame(height: 70)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func swatch(
        _ label: String,
        fill: AnyShapeStyle
    ) -> some View {
        ZStack {
            Rectangle().fill(fill)
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    RootView()
}
