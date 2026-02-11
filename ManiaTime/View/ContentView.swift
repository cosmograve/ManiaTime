//
//  ContentView.swift
//  ManiaTime
//
//  Created by Алексей Авер on 28.01.2026.
//

import SwiftUI
struct ContentView: View {
    @StateObject private var ps = ProgressStore()
    @StateObject private var settings = SettingStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            MainMenu()
                .preferredColorScheme(.light)
                .ignoresSafeArea()
                .environmentObject(ps)
                .environmentObject(settings)
                .onAppear {
                    OrientationManager.shared.forceLandscape()
                    MusicManager.shared.play(scene: .menu)
                    ps.onAppLaunch()
                }
            
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                MusicManager.shared.resumeForAppLifecycleIfNeeded()
            case .inactive, .background:
                MusicManager.shared.pauseForAppLifecycle()
            @unknown default:
                break
            }
        }
        
    }
}

#Preview {
    ContentView()
}
