import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: SettingStore
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ManiaScreen(
            sideEdgePadding: 0,
            centerWidthRatio: 0.62,
            background: {
                Image(.levelsBack)
                    .resizable()
                    .scaledToFill()
            },
            center: {
                GeometryReader { geo in
                    VStack(spacing: 0) {
                        Image(.contentRect)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .overlay(alignment: .top) {
                                Image(.settingsTop)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 50)
                                    .offset(y: -25)
                            }
                            .overlay {
                                
                                HStack {
                                    Image(.musicImg)
                                    Text("Music")
                                        .foregroundStyle(.white)
                                        .font(AppFont.regular(size: 40, weight: .regular))
                                    Spacer()
                                    
                                    Button {
                                        settings.toggleMusic()
                                    } label: {
                                        Image(settings.musicEnabled ? "onBtn" : "offBtn")
                                    }
                                }
                                .padding(.horizontal, 48)
                              
                            }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            },
            leftTop: {
                Button {
                    dismiss()
                } label: {
                    Image(.homeBtn)
                }
                .buttonStyle(.plain)
                .padding(.leading, 12)
            },
            rightTop: {
                
            }
        )
        .ignoresSafeArea()
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingStore())
}
