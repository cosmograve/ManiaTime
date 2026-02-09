import SwiftUI

struct DailyHubView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var ps: ProgressStore

    var body: some View {
        ZStack {
            Color.black.opacity(0.001).ignoresSafeArea()

            if let popup = ps.activePopup {
                popupView(popup)
                    .transition(.opacity)
            } else {
                LevelsView()
                    .ignoresSafeArea()
                    .environmentObject(ps)
                    .navigationBarBackButtonHidden()
            }
        }
        .onAppear {
            ps.dropNonHubPopups()
        }
        
    }

    @ViewBuilder
    private func popupView(_ popup: ProgressPopup) -> some View {
        switch popup {
        case .dailyLogin(let coins, let day, let maxDays):
            DailyRewardView(
                coins: coins,
                day: day,
                maxDays: maxDays,
                onClaim: { ps.claimActivePopup() }
            )
            .environmentObject(ps)

        case .dailyTask(let coins, let title, let subtitle):
            DailyTaskView(
                coins: coins,
                title: title,
                subtitle: subtitle,
                onClaim: { ps.claimActivePopup() }
            )

        default:
            GenericPopupView(
                title: "Reward",
                subtitle: "Nice!",
                coins: popup.coins,
                buttonTitle: "OK",
                onTap: { ps.claimActivePopup() }
            )
        }
    }
}

#Preview {
    DailyHubView()
        .environmentObject(ProgressStore())
}
