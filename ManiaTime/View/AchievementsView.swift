import SwiftUI

struct AchievementsView: View {

    @EnvironmentObject private var ps: ProgressStore
    @Environment(\.dismiss) private var dismiss

    private var canClaim: Bool { ps.canClaimSelectedAchievement() }

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
                                Image(.achTop)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 50)
                                    .offset(y: -25)
                            }
                            .overlay {
                                AchievementsContent(size: geo.size)
                                    .environmentObject(ps)
                            }
                            .overlay(alignment: .bottom) {
                                Button {
                                    ps.claimSelectedAchievement()
                                } label: {
                                    Image(.getBtn)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 50)
                                        .offset(y: 25)
                                        .opacity(canClaim ? 1.0 : 0.0)
                                }
                                .buttonStyle(.plain)
                                .disabled(!canClaim)
                            }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            },
            leftTop: {
                Button { dismiss() } label: { Image(.homeBtn) }
                    .buttonStyle(.plain)
                    .padding(.leading, 12)
            },
            rightTop: {
                BankCountBadge(
                    value: ps.coins,
                    gradient: LinearGradient(
                        colors: [Color(hex: "ED6BEE"), Color(hex: "D94A7A")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .padding(12)
            }
        )
        .ignoresSafeArea()
        .onAppear {
            ps.ensureSelectedAchievementIfNeeded()
        }
    }
}

private struct AchievementsContent: View {

    @EnvironmentObject private var ps: ProgressStore

    let size: CGSize

    private let columns: Int = 4   // ⬅️ БЫЛО 3

    var body: some View {
        let w = size.width
        let h = size.height

        let contentWidth = w * 0.90
        let contentHeight = h * 0.52

        let spacing = clamp(min(w, h) * 0.045, min: 10, max: 18)

        let cellW = floor((contentWidth - spacing * CGFloat(columns - 1)) / CGFloat(columns))
        let cellH = contentHeight

        let circleSize = clamp(min(cellW, cellH) * 0.95, min: 70, max: 120)

        LazyVGrid(
            columns: Array(
                repeating: GridItem(.fixed(cellW), spacing: spacing, alignment: .center),
                count: columns
            ),
            alignment: .center,
            spacing: spacing
        ) {
            ForEach(AchievementID.allCases, id: \.self) { id in
                AchievementCircleCell(
                    id: id,
                    state: ps.achievementCellState(for: id),
                    isSelected: ps.selectedAchievement == id,
                    size: circleSize
                ) {
                    ps.selectedAchievement = id
                }
            }
        }
        .frame(width: contentWidth, height: contentHeight, alignment: .center)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func clamp(_ value: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        Swift.min(max, Swift.max(min, value))
    }
}

private enum AchievementStyle {

    static let claimedGradient = LinearGradient(
        colors: [Color(hex: "D94A7A"), Color(hex: "ED6BEE")],
        startPoint: .top,
        endPoint: .bottom
    )

    static let earnedGradient = LinearGradient(
        colors: [Color(hex: "5D75FD"), Color(hex: "6CD9F6")],
        startPoint: .top,
        endPoint: .bottom
    )

    static let lockedGradient = LinearGradient(
        colors: [Color(hex: "9B6CFF"), Color(hex: "5E3BFF")],
        startPoint: .top,
        endPoint: .bottom
    )
}

private struct AchievementCircleCell: View {

    let id: AchievementID
    let state: ProgressStore.AchievementCellState
    let isSelected: Bool
    let size: CGFloat
    let onTap: () -> Void

    private var gradient: LinearGradient {
        switch state {
        case .claimed:
            return AchievementStyle.claimedGradient
        case .earnedNotClaimed:
            return AchievementStyle.earnedGradient
        case .locked:
            return AchievementStyle.lockedGradient
        }
    }

    private var ringWidth: CGFloat { 3 }

    private var capsuleHeight: CGFloat {
        clamp(size * 0.24, min: 15, max: 22)
    }

    private var capsuleWidth: CGFloat {
        size
    }

    var body: some View {
        Button { onTap() } label: {
            ZStack {
                Circle()
                    .fill(gradient)
                    .frame(width: size, height: size)

                Circle()
                    .stroke(Color.white.opacity(0.95), lineWidth: ringWidth)
                    .frame(width: size, height: size)

                innerIcon
                    .frame(width: size * 0.56, height: size * 0.56)

                rewardCapsule
                    .frame(width: capsuleWidth, height: capsuleHeight)
                    .offset(y: size*0.6 - capsuleHeight * 0.5)

                if isSelected {
                    Circle()
                        .stroke(Color.white.opacity(0.85), lineWidth: 2)
                        .frame(width: size + 12, height: size + 12)
                        .opacity(0.55)
                }
            }
            .frame(width: size + 16, height: size + 16)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var innerIcon: some View {
        
        switch state {
        case .claimed:
            Image(systemName: "checkmark")
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.white)

        case .earnedNotClaimed:
            Image(id.title)
                .resizable()
                .scaledToFit()

        case .locked:
            Image(.achClosed)
                .resizable()
                .scaledToFit()
        }
    }

    private var rewardCapsule: some View {
        ZStack {
            Capsule()
                .fill(AchievementStyle.earnedGradient)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.9), lineWidth: 1)
                )

            if state != .claimed {
                HStack(spacing: 6) {
                    Text("\(id.coinReward)")
                        .font(AppFont.regular(size: clamp(capsuleHeight * 0.85, min: 14, max: 22), weight: .regular))
                        .foregroundStyle(.white)

                    Image(.coinImg)
                        .resizable()
                        .scaledToFit()
                        .frame(width: capsuleHeight * 0.75, height: capsuleHeight * 0.75)
                }
                .offset(y: 1)
            }
        }
    }

    private func clamp(_ value: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        Swift.min(max, Swift.max(min, value))
    }
}

#Preview {
    AchievementsView()
        .environmentObject(ProgressStore())
}
