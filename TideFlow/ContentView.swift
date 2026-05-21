import SwiftUI

struct ContentView: View {
    @EnvironmentObject var lang: LanguageManager

    @State private var selectedTab      = 1   // Today is the default landing tab
    @State private var showingQuickAdd  = false
    @State private var showingSettings  = false
    @State private var showingOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenLanguagePicker")

    var body: some View {
        ZStack(alignment: .bottomTrailing) {

            TabView(selection: $selectedTab) {
                NowView()
                    .tabItem { Label(lang.t(.tab_now),   systemImage: "water.waves") }
                    .tag(0)
                TodayView()
                    .tabItem { Label(lang.t(.tab_today), systemImage: "sun.horizon") }
                    .tag(1)
                PlanView()
                    .tabItem { Label(lang.t(.tab_plan),  systemImage: "calendar") }
                    .tag(2)
                BrainDumpView()
                    .tabItem { Label(lang.t(.tab_focus), systemImage: "brain.head.profile") }
                    .tag(3)
            }
            .tint(.tideTeal)

            // Floating + button (hidden on Brain Dump tab)
            if selectedTab != 3 {
                Button(action: { showingQuickAdd = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.tideTeal)
                        .clipShape(Circle())
                        .shadow(color: Color.tideTeal.opacity(0.45), radius: 10, x: 0, y: 4)
                }
                .padding(.trailing, 22)
                .padding(.bottom, 90)
            }
        }
        .sheet(isPresented: $showingQuickAdd) { QuickAddView() }
        .sheet(isPresented: $showingSettings)  { SettingsView() }
        // First-launch language picker
        .fullScreenCover(isPresented: $showingOnboarding) {
            LanguageOnboardingView {
                UserDefaults.standard.set(true, forKey: "hasSeenLanguagePicker")
                showingOnboarding = false
            }
        }
    }
}
