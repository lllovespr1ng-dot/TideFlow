import SwiftUI

/// Shown once on first launch — lets the user pick their language.
struct LanguageOnboardingView: View {
    @EnvironmentObject var lang: LanguageManager
    let onDone: () -> Void

    var body: some View {
        ZStack {
            Color.tideBg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // App mark
                VStack(spacing: 10) {
                    Image(systemName: "water.waves")
                        .font(.system(size: 52))
                        .foregroundColor(.tideTeal)
                    Text("TideFlow")
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                        .foregroundColor(.tideDeep)
                }
                .padding(.bottom, 40)

                // Language list
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(AppLanguage.allCases) { option in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                lang.language = option
                            }
                        }) {
                            HStack(spacing: 12) {
                                // Bullet
                                Circle()
                                    .fill(lang.language == option ? Color.tideTeal : Color.tideSeafoam.opacity(0.4))
                                    .frame(width: 8, height: 8)

                                Text(option.displayName)
                                    .font(.system(size: 18, design: .rounded))
                                    .foregroundColor(lang.language == option ? .tideDeep : .tideDeep.opacity(0.6))

                                Spacer()

                                if lang.language == option {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.tideTeal)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(
                                lang.language == option
                                    ? Color.tideTeal.opacity(0.08)
                                    : Color.tideSand
                            )
                            .cornerRadius(14)
                        }
                    }
                }
                .padding(.horizontal, 28)

                // "We'll remember" note
                Text(lang.t(.remember_choice))
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.tideSeafoam)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 16)

                Spacer()

                // Continue button
                Button(action: onDone) {
                    Text("Get started")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.tideTeal)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 48)
            }
        }
    }
}
