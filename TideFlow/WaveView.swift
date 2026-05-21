import SwiftUI

/// Animated ocean wave that fills up as focus time progresses.
struct WaveView: View {
    /// 0.0 = empty, 1.0 = full
    var progress: Double

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                drawWave(context: context, size: size, time: t, phase: 0,   opacity: 1.0)
                drawWave(context: context, size: size, time: t, phase: 0.4, opacity: 0.5)
            }
        }
        .background(Color.tideSeafoam.opacity(0.2))
    }

    private func drawWave(context: GraphicsContext, size: CGSize,
                          time: Double, phase: Double, opacity: Double) {
        let w = size.width
        let h = size.height
        // fillY moves from 80% of height (nearly empty) to 15% (nearly full)
        let fillY = h * (0.8 - progress * 0.65)
        let waveH: CGFloat = 10
        let period: CGFloat = w * 0.7

        var path = Path()
        path.move(to: CGPoint(x: 0, y: fillY))

        var x: CGFloat = 0
        while x <= w {
            let angle = (x / period + time * 0.25 + phase) * 2 * .pi
            let y = fillY + sin(angle) * waveH
            path.addLine(to: CGPoint(x: x, y: y))
            x += 2
        }

        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: 0,  y: h))
        path.closeSubpath()

        context.fill(path, with: .color(Color.tideTeal.opacity(opacity)))
    }
}
