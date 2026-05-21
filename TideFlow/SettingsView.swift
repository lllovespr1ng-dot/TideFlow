import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var lang: LanguageManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.tideBg.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 12) {

                    // ── Language section label ─────────────────────────────
                    Text(lang.t(.language_label))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.tideSeafoam)
                        .tracking(1.5)
                        .padding(.top, 8)

                    // ── Language rows ──────────────────────────────────────
                    ForEach(AppLanguage.allCases) { option in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                lang.language = option
                            }
                        }) {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(lang.language == option
                                          ? Color.tideTeal
                                          : Color.tideSeafoam.opacity(0.4))
                                    .frame(width: 7, height: 7)

                                Text(option.displayName)
                                    .font(.system(size: 17, design: .rounded))
                                    .foregroundColor(.tideDeep)

                                Spacer()

                                if lang.language == option {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.tideTeal)
                                }
                            }
                            .padding(16)
                            .background(lang.language == option
                                        ? Color.tideTeal.opacity(0.08)
                                        : Color.tideSand)
                            .cornerRadius(14)
                        }
                    }

                    Spacer()

                    // ── Social footer ──────────────────────────────────────
                    Divider()
                        .background(Color.tideSeafoam.opacity(0.25))

                    HStack(alignment: .center, spacing: 0) {
                        Text(lang.t(.creator_label))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.tideSeafoam)

                        Spacer()

                        HStack(spacing: 10) {
                            // Instagram
                            Link(destination: URL(string: "https://www.instagram.com/llovespr1ng/")!) {
                                ZStack {
                                    Circle()
                                        .fill(Color.tideTeal)
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                .frame(width: 36, height: 36)
                            }

                            // Telegram
                            Link(destination: URL(string: "https://t.me/lovespr1ng")!) {
                                ZStack {
                                    Circle()
                                        .fill(Color.tideTeal)
                                    Image(systemName: "paperplane.fill")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                .frame(width: 36, height: 36)
                            }
                        }
                    }
                    .padding(.vertical, 10)
                }
                .padding(.horizontal)
            }
            .navigationTitle(lang.t(.settings_title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(lang.t(.save_label)) { dismiss() }
                        .foregroundColor(.tideTeal)
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
