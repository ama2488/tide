import SwiftUI

/// Each phase is a hand-drawn moon sitting in a soft colored halo:
/// menstrual — full clay disk · follicular — waxing crescent
/// ovulatory — full sun-moon with rays · luteal — waning crescent
struct PhaseGlyph: View {
    let phase: Phase
    init(_ phase: Phase) { self.phase = phase }

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                WobblyCircle(seed: phase.seed &+ 100, wobble: 0.07, closed: true)
                    .fill(phase.color.opacity(0.16))
                    .frame(width: s, height: s)
                moon(diameter: s * 0.74)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel("\(phase.name) phase")
    }

    private func moon(diameter d: CGFloat) -> some View {
        ZStack {
            lit(diameter: d)
            WobblyCircle(seed: phase.seed, wobble: 0.03)
                .stroke(Palette.ink, lineWidth: 1.3)
            WobblyCircle(seed: phase.seed &+ 7, wobble: 0.045)
                .stroke(Palette.ink.opacity(0.3), lineWidth: 0.8)
                .rotationEffect(.degrees(9))
            if phase == .ovulatory {
                Rays(seed: phase.seed)
                    .stroke(Palette.ink, style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
                    .frame(width: d * 1.3, height: d * 1.3)
            }
        }
        .frame(width: d, height: d)
    }

    @ViewBuilder
    private func lit(diameter d: CGFloat) -> some View {
        let fill = WobblyCircle(seed: phase.seed &+ 3, wobble: 0.03, closed: true).fill(phase.color)
        switch phase {
        case .menstrual, .ovulatory:
            fill
        case .follicular:
            fill.mask { crescentMask(diameter: d, offset: -d * 0.4) }
        case .luteal:
            fill.mask { crescentMask(diameter: d, offset: d * 0.4) }
        }
    }

    private func crescentMask(diameter d: CGFloat, offset: CGFloat) -> some View {
        ZStack {
            Rectangle()
            Circle()
                .frame(width: d, height: d)
                .offset(x: offset)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
    }
}

// MARK: - Cycle wheel

/// The whole cycle as a hand-drawn ring of four colored arcs.
struct CycleWheel: View {
    let calendar: CycleCalendar
    let today: Int

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let length = Double(calendar.cycleLength)
            let radius = Double(s) / 2 - 16
            let angle = (Double(today) - 0.5) / length * 2 * .pi - .pi / 2

            ZStack {
                WobblyCircle(seed: 77, wobble: 0.01)
                    .stroke(Palette.faint, lineWidth: 1)
                    .padding(32)

                ForEach(Phase.allCases) { phase in
                    let b = calendar.bounds(of: phase)
                    if b.end >= b.start {
                        WobblyArc(
                            start: Double(b.start - 1) / length + 0.018,
                            end: Double(b.end) / length - 0.018,
                            seed: phase.seed
                        )
                        .stroke(phase.color, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .padding(16)
                    }
                }

                WobblyCircle(seed: 5, wobble: 0.08, closed: true)
                    .fill(Palette.ink)
                    .frame(width: 18, height: 18)
                    .overlay(WobblyCircle(seed: 6, wobble: 0.08).stroke(Palette.paper, lineWidth: 2.5))
                    .offset(x: cos(angle) * radius, y: sin(angle) * radius)

                VStack(spacing: 2) {
                    Eyebrow("day")
                    Text("\(today)")
                        .font(TideFont.display(64))
                        .monospacedDigit()
                    Eyebrow("of \(calendar.cycleLength)")
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel("day \(today) of \(calendar.cycleLength)")
    }
}

// MARK: - Hormone curve

/// A loose, hand-sketched picture of estrogen and progesterone across the cycle.
/// Illustrative, not a measurement.
struct HormoneChart: View {
    let calendar: CycleCalendar
    let today: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow("your hormones, roughly")
            Canvas { context, size in
                let w = Double(size.width), h = Double(size.height) - 12
                let length = Double(calendar.cycleLength)
                let ovX = (Double(calendar.ovulationDay) - 0.5) / length
                let lutMid = ovX + (1 - ovX) * 0.5
                let lutW = (1 - ovX) * 0.26

                func g(_ x: Double, _ m: Double, _ s: Double) -> Double { exp(-((x - m) * (x - m)) / (2 * s * s)) }
                func estrogen(_ x: Double) -> Double { 0.1 + 0.8 * g(x, ovX - 0.03, 0.075) + 0.3 * g(x, lutMid, lutW) }
                func progesterone(_ x: Double) -> Double { 0.05 + 0.8 * g(x, lutMid, lutW) }

                func curve(_ f: (Double) -> Double, seed: UInt64) -> Path {
                    var rng = SeededRandom(seed: seed)
                    var path = Path()
                    let steps = 80
                    for i in 0...steps {
                        let x = Double(i) / Double(steps)
                        let v = f(x) + (rng.unit() - 0.5) * 0.012
                        let p = CGPoint(x: x * w, y: 6 + (1 - v) * (h - 12))
                        if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
                    }
                    return path
                }

                // phase band along the bottom
                for day in 1...calendar.cycleLength {
                    let x0 = Double(day - 1) / length * w
                    let rect = CGRect(x: x0, y: h + 6, width: w / length + 0.5, height: 4)
                    context.fill(Path(rect), with: .color(calendar.phase(forDay: day).color.opacity(0.7)))
                }

                // today
                if let today {
                    let x = (Double(today) - 0.5) / length * w
                    var line = Path()
                    line.move(to: CGPoint(x: x, y: 0))
                    line.addLine(to: CGPoint(x: x, y: h + 2))
                    context.stroke(line, with: .color(Palette.soft), style: StrokeStyle(lineWidth: 1, dash: [2, 4]))
                    context.fill(Path(ellipseIn: CGRect(x: x - 3, y: h + 5, width: 6, height: 6)), with: .color(Palette.ink))
                }

                context.stroke(curve(estrogen, seed: 1), with: .color(Palette.ink),
                               style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                context.stroke(curve(progesterone, seed: 2), with: .color(Palette.ink),
                               style: StrokeStyle(lineWidth: 1.3, lineCap: .round, lineJoin: .round, dash: [5, 4]))
            }
            .frame(height: 150)

            HStack(spacing: 20) {
                legend("estrogen", dashed: false)
                legend("progesterone", dashed: true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Estrogen rises through the first half of the cycle and peaks near ovulation. Progesterone rises after ovulation, then both fall before your period.")
    }

    private func legend(_ name: String, dashed: Bool) -> some View {
        HStack(spacing: 6) {
            Path { p in
                p.move(to: CGPoint(x: 0, y: 4))
                p.addLine(to: CGPoint(x: 18, y: 4))
            }
            .stroke(Palette.ink, style: StrokeStyle(lineWidth: 1.4, dash: dashed ? [4, 3] : []))
            .frame(width: 18, height: 8)
            Eyebrow(name)
        }
    }
}
