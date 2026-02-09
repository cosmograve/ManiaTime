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

    var body: some View {
        NavigationStack {
            MainMenu()
                .ignoresSafeArea()
                .environmentObject(ps)
                .environmentObject(settings)
                
        }
        .onAppear {
            MusicManager.shared.play(scene: .menu)
            ps.onAppLaunch()
        }
    }
    
    
}

#Preview {
    ContentView()
}
