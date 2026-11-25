import SwiftUI
import UIKit

// MARK: - Palette
// Warm paper + soft ink by day (a nod to Nobody Wants This' 70s warmth),
// near-black night mode with cream ink (a nod to Co–Star).

enum Palette {
    static let paper = Color.dynamic(light: 0xF3ECE0, dark: 0x141210)
    static let ink = Color.dynamic(light: 0x1F1B17, dark: 0xEEE6D8)
    static var soft: Color { ink.opacity(0.58) }
    static var faint: Color { ink.opacity(0.16) }
}

extension Color {
    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

// MARK: - Type
// Serif (New York) for voice, small monospaced lowercase labels for structure.

enum TideFont {
    static func display(_ size: CGFloat) -> Font { .system(size: size, weight: .regular, design: .serif) }
    static func body(_ size: CGFloat = 17) -> Font { .system(size: size, weight: .regular, design: .serif) }
    static func label(_ size: CGFloat = 11) -> Font { .system(size: size, weight: .medium, design: .monospaced) }
}

/// Small lowercase, letter‑spaced label. Used everywhere as quiet structure.
struct Eyebrow: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.lowercased())
            .font(TideFont.label())
            .tracking(1.6)
            .foregroundStyle(Palette.soft)
    }
}

/// A paragraph with an eyebrow above it.
struct Prose: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(title)
            Text(text)
                .font(TideFont.body(17))
                .lineSpacing(5)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct Disclaimer: View {
    var body: some View {
        Text("tide offers gentle, general wellness ideas — not medical advice. herbs can interact with medications, hormonal birth control and pregnancy, so check with a clinician before starting any new herb or supplement.")
            .font(TideFont.label(10))
            .lineSpacing(3)
            .foregroundStyle(Palette.soft)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Controls

struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// A hand-drawn pill button.
struct InkButton: View {
    let title: String
    var filled: Bool = false
    var seed: UInt64 = 7
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(TideFont.body(18))
                .foregroundStyle(filled ? Palette.paper : Palette.ink)
                .padding(.vertical, 17)
                .frame(maxWidth: .infinity)
                .background {
                    ZStack {
                        WobblyCapsule(seed: seed).fill(filled ? Palette.ink : Color.clear)
                        WobblyCapsule(seed: seed).stroke(Palette.ink, lineWidth: 1.2)
                        WobblyCapsule(seed: seed &+ 11, amount: 2.2).stroke(Palette.ink.opacity(0.25), lineWidth: 0.8)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(PressStyle())
    }
}

/// Italic serif text link with a hand-drawn underline.
struct InkLink: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(TideFont.body(17))
                .italic()
                .foregroundStyle(Palette.ink)
                .padding(.bottom, 6)
                .overlay(alignment: .bottom) {
                    WobblyLine(seed: UInt64(title.count), amplitude: 1)
                        .stroke(Palette.ink.opacity(0.55), lineWidth: 1)
                        .frame(height: 4)
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(PressStyle())
    }
}

/// Eyebrow title with a quiet "close" on the right, for sheets.
struct SheetHeader: View {
    let title: String
    let close: () -> Void

    var body: some View {
        HStack {
            Eyebrow(title)
            Spacer()
            Button(action: close) {
                Text("close")
                    .font(TideFont.label(12))
                    .tracking(1.2)
                    .foregroundStyle(Palette.ink)
                    .padding(8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}

/// Big number between two hand-drawn circle buttons.
struct InkStepper: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String

    var body: some View {
        HStack(spacing: 28) {
            circle("–", seed: 21) { if value > range.lowerBound { value -= 1 } }
                .opacity(value > range.lowerBound ? 1 : 0.3)
            VStack(spacing: 2) {
                Text("\(value)")
                    .font(TideFont.display(58))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Eyebrow(unit)
            }
            .frame(minWidth: 96)
            circle("+", seed: 34) { if value < range.upperBound { value += 1 } }
                .opacity(value < range.upperBound ? 1 : 0.3)
        }
        .frame(maxWidth: .infinity)
        .sensoryFeedback(.selection, trigger: value)
        .animation(.snappy, value: value)
    }

    private func circle(_ symbol: String, seed: UInt64, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(symbol)
                .font(TideFont.body(24))
                .foregroundStyle(Palette.ink)
                .frame(width: 52, height: 52)
                .background(WobblyCircle(seed: seed, wobble: 0.06).stroke(Palette.ink, lineWidth: 1.2))
                .contentShape(Circle())
        }
        .buttonStyle(PressStyle())
    }
}
