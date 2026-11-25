import SwiftUI

// Everything here is drawn with a little deterministic wobble so the app
// feels made by hand, but never jitters between renders.

// MARK: - Seeded randomness

struct SeededRandom: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed &+ 0x9E37_79B9_7F4A_7C15 }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// A Double in [0, 1).
    mutating func unit() -> Double { Double(next() >> 11) / Double(UInt64(1) << 53) }
}

// MARK: - Circle

/// A circle drawn the way a pen draws one: slightly lumpy, with the end
/// overshooting the start a touch.
struct WobblyCircle: Shape {
    var seed: UInt64 = 1
    /// Fraction of the radius the edge may drift.
    var wobble: Double = 0.035
    /// Extra radians drawn past the start point.
    var overshoot: Double = 0.12
    /// Closed circles have no overshoot or drift, so they fill cleanly.
    var closed: Bool = false

    func path(in rect: CGRect) -> Path {
        var rng = SeededRandom(seed: seed)
        let cx = Double(rect.midX), cy = Double(rect.midY)
        let r = Double(min(rect.width, rect.height)) / 2 * (1 - wobble)
        let a1 = wobble * (0.5 + rng.unit() * 0.5), p1 = rng.unit() * 2 * .pi
        let a2 = wobble * 0.5 * rng.unit(), p2 = rng.unit() * 2 * .pi
        let a3 = wobble * 0.25 * rng.unit(), p3 = rng.unit() * 2 * .pi
        let start = rng.unit() * 2 * .pi
        let total = 2 * Double.pi + (closed ? 0 : overshoot)
        let steps = 96

        var path = Path()
        for i in 0...steps {
            let t = Double(i) / Double(steps)
            let theta = start + t * total
            // a slow drift so the overshoot doesn't sit exactly on the start
            let drift = closed ? 0 : (t - 0.5) * wobble * 0.6
            let k = 1 + a1 * sin(2 * theta + p1) + a2 * sin(3 * theta + p2) + a3 * sin(5 * theta + p3) + drift
            let point = CGPoint(x: cx + cos(theta) * r * k, y: cy + sin(theta) * r * k)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        if closed { path.closeSubpath() }
        return path
    }
}

// MARK: - Arc

/// A section of a hand-drawn ring. `start`/`end` are fractions of a turn,
/// beginning at 12 o'clock and running clockwise.
struct WobblyArc: Shape {
    var start: Double
    var end: Double
    var seed: UInt64 = 1
    var wobble: Double = 0.012

    func path(in rect: CGRect) -> Path {
        var rng = SeededRandom(seed: seed)
        let p1 = rng.unit() * 2 * .pi, p2 = rng.unit() * 2 * .pi
        let cx = Double(rect.midX), cy = Double(rect.midY)
        let r = Double(min(rect.width, rect.height)) / 2 * (1 - wobble)
        let a0 = start * 2 * .pi - .pi / 2
        let a1 = end * 2 * .pi - .pi / 2
        let steps = max(8, Int((end - start) * 180))

        var path = Path()
        for i in 0...steps {
            let t = Double(i) / Double(steps)
            let a = a0 + (a1 - a0) * t
            let k = 1 + wobble * (sin(3 * a + p1) + 0.5 * sin(7 * a + p2))
            let point = CGPoint(x: cx + cos(a) * r * k, y: cy + sin(a) * r * k)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        return path
    }
}

// MARK: - Line

/// A horizontal line with a gentle, hand-drawn waver.
struct WobblyLine: Shape {
    var seed: UInt64 = 5
    var amplitude: Double = 1.5

    func path(in rect: CGRect) -> Path {
        var rng = SeededRandom(seed: seed)
        let p1 = rng.unit() * 2 * .pi, p2 = rng.unit() * 2 * .pi
        let f1 = 0.6 + rng.unit() * 1.2, f2 = 2.5 + rng.unit() * 3
        let x0 = Double(rect.minX), w = Double(rect.width), mid = Double(rect.midY)
        let steps = 60

        var path = Path()
        for i in 0...steps {
            let t = Double(i) / Double(steps)
            let y = mid + amplitude * (0.7 * sin(2 * .pi * f1 * t + p1) + 0.3 * sin(2 * .pi * f2 * t + p2))
            let point = CGPoint(x: x0 + t * w, y: y)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        return path
    }
}

// MARK: - Capsule / card

/// A pill (or, with `cornerRadius`, a rounded card) traced by hand.
struct WobblyCapsule: Shape {
    var seed: UInt64 = 7
    /// Maximum drift in points.
    var amount: Double = 1.6
    /// nil = fully rounded ends.
    var cornerRadius: Double? = nil

    func path(in rect: CGRect) -> Path {
        let inset = rect.insetBy(dx: amount * 1.5, dy: amount * 1.5)
        let minX = Double(inset.minX), maxX = Double(inset.maxX)
        let minY = Double(inset.minY), maxY = Double(inset.maxY)
        let w = Double(inset.width), h = Double(inset.height)
        let r = min(cornerRadius ?? .infinity, min(w, h) / 2)
        let sw = max(0, w - 2 * r)          // horizontal straight
        let sh = max(0, h - 2 * r)          // vertical straight
        let quarter = Double.pi * r / 2
        let total = 2 * sw + 2 * sh + 4 * quarter

        var rng = SeededRandom(seed: seed)
        let p1 = rng.unit() * 2 * .pi, p2 = rng.unit() * 2 * .pi
        let startOffset = rng.unit() * total

        // point + outward normal at distance s along the perimeter, clockwise from top-left
        func corner(_ cx: Double, _ cy: Double, _ a0: Double, _ s: Double) -> (x: Double, y: Double, nx: Double, ny: Double) {
            let a = a0 + s / max(r, 0.0001)
            return (cx + cos(a) * r, cy + sin(a) * r, cos(a), sin(a))
        }
        func base(_ raw: Double) -> (x: Double, y: Double, nx: Double, ny: Double) {
            var s = raw.truncatingRemainder(dividingBy: total)
            if s < 0 { s += total }
            if s < sw { return (minX + r + s, minY, 0, -1) }
            s -= sw
            if s < quarter { return corner(maxX - r, minY + r, -.pi / 2, s) }
            s -= quarter
            if s < sh { return (maxX, minY + r + s, 1, 0) }
            s -= sh
            if s < quarter { return corner(maxX - r, maxY - r, 0, s) }
            s -= quarter
            if s < sw { return (maxX - r - s, maxY, 0, 1) }
            s -= sw
            if s < quarter { return corner(minX + r, maxY - r, .pi / 2, s) }
            s -= quarter
            if s < sh { return (minX, maxY - r - s, -1, 0) }
            s -= sh
            return corner(minX + r, minY + r, .pi, s)
        }

        let steps = 160
        let overshoot = total * 0.04
        var path = Path()
        for i in 0...steps {
            let t = Double(i) / Double(steps)
            let s = startOffset + t * (total + overshoot)
            let b = base(s)
            let phase = 2 * Double.pi * s / total
            let d = amount * (0.6 * sin(2 * phase + p1) + 0.4 * sin(5 * phase + p2)) + (t - 0.5) * amount
            let point = CGPoint(x: b.x + b.nx * d, y: b.y + b.ny * d)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        return path
    }
}

// MARK: - Check mark

struct CheckMark: Shape {
    var seed: UInt64 = 3

    func path(in rect: CGRect) -> Path {
        var rng = SeededRandom(seed: seed)
        func j() -> Double { (rng.unit() - 0.5) * 0.06 }
        let w = Double(rect.width), h = Double(rect.height)
        let x0 = Double(rect.minX), y0 = Double(rect.minY)
        func p(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x0 + (x + j()) * w, y: y0 + (y + j()) * h) }

        var path = Path()
        path.move(to: p(0.08, 0.55))
        path.addQuadCurve(to: p(0.40, 0.86), control: p(0.24, 0.66))
        path.addQuadCurve(to: p(0.94, 0.14), control: p(0.58, 0.42))
        return path
    }
}

// MARK: - Rays

/// Short strokes radiating outward, for the ovulatory sun-moon.
struct Rays: Shape {
    var seed: UInt64 = 1
    var count: Int = 12

    func path(in rect: CGRect) -> Path {
        var rng = SeededRandom(seed: seed)
        let cx = Double(rect.midX), cy = Double(rect.midY)
        let r = Double(min(rect.width, rect.height)) / 2
        var path = Path()
        for i in 0..<count {
            let a = Double(i) / Double(count) * 2 * .pi + (rng.unit() - 0.5) * 0.14
            let r0 = r * (0.84 + rng.unit() * 0.03)
            let r1 = r * (0.94 + rng.unit() * 0.06)
            let a1 = a + (rng.unit() - 0.5) * 0.04
            path.move(to: CGPoint(x: cx + cos(a) * r0, y: cy + sin(a) * r0))
            path.addLine(to: CGPoint(x: cx + cos(a1) * r1, y: cy + sin(a1) * r1))
        }
        return path
    }
}

// MARK: - Paper

/// Warm paper with a faint grain.
struct PaperBackground: View {
    var body: some View {
        ZStack {
            Palette.paper
            Canvas { context, size in
                var rng = SeededRandom(seed: 42)
                let w = Double(size.width), h = Double(size.height)
                let count = Int(w * h / 110)
                for _ in 0..<count {
                    let x = rng.unit() * w
                    let y = rng.unit() * h
                    let s = 0.6 + rng.unit() * 0.9
                    let o = 0.025 + rng.unit() * 0.05
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: s, height: s)),
                        with: .color(Palette.ink.opacity(o))
                    )
                }
            }
            .drawingGroup()
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Check circle

struct HandCheck: View {
    var isOn: Bool
    var color: Color
    var seed: UInt64

    var body: some View {
        ZStack {
            WobblyCircle(seed: seed, wobble: 0.08, closed: true)
                .fill(isOn ? color : Color.clear)
            WobblyCircle(seed: seed, wobble: 0.08)
                .stroke(Palette.ink, lineWidth: 1.2)
            CheckMark(seed: seed)
                .trim(from: 0, to: isOn ? 1 : 0)
                .stroke(Palette.ink, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                .padding(8)
        }
        .frame(width: 30, height: 30)
        .scaleEffect(isOn ? 1.06 : 1)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isOn)
    }
}
