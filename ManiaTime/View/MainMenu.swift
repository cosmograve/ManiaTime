import SwiftUI

struct MainMenu: View {
    @EnvironmentObject private var ps: ProgressStore
    @EnvironmentObject private var ss: SettingStore
    
    @State private var showHub = false
    @State private var showSet = false
    @State private var showAch = false

    var body: some View {
        ManiaScreen(
            sideEdgePadding: 12, centerWidthRatio: 0.45,
            background: {
                Image(.menuback).resizable().scaledToFill()
            },
            center: {
                VStack {
                    Image(.maniaLogo)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 260)
                    
                    Spacer(minLength: 16)
                    
                    VStack(spacing: 2) {
                        Button {
                            showHub.toggle()
                        } label: {
                            Image(.startBtn).resizable().scaledToFit().frame(maxWidth: 360)
                        }
                        Button { showSet.toggle()
                        } label: {
                            Image(.settingsBtn).resizable().scaledToFit().frame(maxWidth: 360)
                        }
                        Button { showAch.toggle()
                        } label: {
                            Image(.achBtn).resizable().scaledToFit().frame(maxWidth: 360)
                        }
                        
                    }
                    Spacer()
                }
                .padding(.bottom, 24)
            }
                
        )
        .fullScreenCover(isPresented: $showHub) {
            DailyHubView()
                .environmentObject(ps)
        }
        .fullScreenCover(isPresented: $showSet) {
            SettingsView()
                .environmentObject(ss)
        }
        .fullScreenCover(isPresented: $showAch) {
            AchievementsView()
                .environmentObject(ps)
        }
        .onAppear {
            MusicManager.shared.play(scene: .menu)
            ps.onAppLaunch()
        }
    }
}
#Preview {
    MainMenu()
        .ignoresSafeArea()
        .environmentObject(ProgressStore())
}
