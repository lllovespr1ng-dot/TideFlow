//
//  TideFlowApp.swift
//  TideFlow
//
//  Created by Данил Ротко on 21.05.2026.
//

import SwiftUI

@main
struct TideFlowApp: App {
    @StateObject private var calendarManager     = CalendarManager()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var brainDumpManager    = BrainDumpManager()
    @StateObject private var languageManager     = LanguageManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(calendarManager)
                .environmentObject(notificationManager)
                .environmentObject(brainDumpManager)
                .environmentObject(languageManager)
        }
    }
}
