import SwiftUI

struct TimeRingView: View {
    let minutesRemaining: Int
    let totalMinutes: Int
    @EnvironmentObject var lang: LanguageManager

    private var progress: Double {
        guard totalMinutes > 0 else { return 1.0 }
        return min(1.0, Double(minutesRemaining) / Double(totalMinutes))
    }

    private var timeLabel: String {
        if minutesRemaining <= 0 {
            // Re-use the tab label which is already short and correct in every language:
            // "Now" / "Сейчас" / "Ahora" / "Maintenant"
            return lang.t(.tab_now)
        }
        let hStr = lang.t(.hour_abbr)   // "h" / "ч" / "h" / "h"
        let mStr = lang.t(.min_abbr)    // "m" / "мин" / "min" / "min"
        if minutesRemaining < 60 { return "\(minutesRemaining)\(mStr)" }
        let h = minutesRemaining / 60, m = minutesRemaining % 60
        return m > 0 ? "\(h)\(hStr) \(m)\(mStr)" : "\(h)\(hStr)"
    }

    private var statusLabel: String {
        if minutesRemaining <= 0  { return lang.t(.happening_now) }
        if minutesRemaining <= 5  { return lang.t(.very_soon) }
        if minutesRemaining <= 15 { return lang.t(.coming_up) }
        return lang.t(.until_start)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.tideMist, lineWidth: 14)
                .frame(width: 190, height: 190)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [Color.tideSeafoam, Color.tideTeal],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle:   .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .frame(width: 190, height: 190)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.9), value: progress)

            VStack(spacing: 3) {
                Text(timeLabel)
                    .font(.system(size: 38, weight: .light, design: .rounded)).foregroundColor(.tideDeep)
                Text(statusLabel)
                    .font(.system(size: 13, design: .rounded)).foregroundColor(.tideSeafoam)
            }
        }
    }
}
