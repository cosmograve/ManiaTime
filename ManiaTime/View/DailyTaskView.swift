import SwiftUI

struct DailyTaskView: View {

    @EnvironmentObject private var ps: ProgressStore

    let coins: Int
    let title: String
    let subtitle: String
    let onClaim: () -> Void

    private var completedToday: Int { ps.dailyCompletedLevelsCount }
    private var isTask1Done: Bool { completedToday >= 1 }
    private var isTask2Done: Bool { completedToday >= 5 }
    private var canClaim: Bool { isTask2Done }

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
                                Image(.dailyTastk)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 50)
                                    .offset(y: -25)
                            }
                            .overlay {
                                DailyTaskContent(
                                    title: title,
                                    subtitle: subtitle,
                                    availableSize: geo.size,
                                    isTask1Done: isTask1Done,
                                    isTask2Done: isTask2Done
                                )
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                            .overlay(alignment: .bottom) {
                                HStack(spacing: 20) {

                                    Button {
                                        ps.closeDailyHub()
                                    } label: {
                                        Image(.playBtn)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxHeight: 50)
                                    }
                                    .buttonStyle(.plain)

                                    if canClaim {
                                        Button {
                                            onClaim()
                                        } label: {
                                            Image(.getBtn)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(maxHeight: 50)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .offset(y: 25)
                            }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            },
            leftTop: {
                EmptyView()
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
    }
}
#Preview {
    DailyTaskView(
        coins: 10,
        title: "Complete one level",
        subtitle: "Complete five levels"
    ) { }
    .environmentObject(ProgressStore())
}


private struct DailyTaskContent: View {

    let title: String
    let subtitle: String

    let availableSize: CGSize

    let isTask1Done: Bool
    let isTask2Done: Bool

    var body: some View {
        let w = availableSize.width
        let h = availableSize.height

        let contentWidth = w * 0.82

        let circleSize = clamp(h * 0.13, min: 52, max: 92)

        let rowSpacing = clamp(h * 0.065, min: 14, max: 32)

        VStack(spacing: rowSpacing) {

            taskRow(
                text: title,
                isDone: isTask1Done,
                circleSize: circleSize
            )

            taskRow(
                text: subtitle,
                isDone: isTask2Done,
                circleSize: circleSize
            )
        }
        .frame(width: contentWidth)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    // MARK: - Row

    private func taskRow(
        text: String,
        isDone: Bool,
        circleSize: CGFloat
    ) -> some View {

        HStack(spacing: 12) {

            Text(text)
                .font(AppFont.regular(size: 40, weight: .regular))            .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer(minLength: 8)

            Image(isDone ? .dailyCoin : .dailyEmpty)
                .resizable()
                .scaledToFit()
                .frame(width: circleSize, height: circleSize)
        }
        .frame(height: circleSize)
    }

    // MARK: - Clamp

    private func clamp(_ value: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        Swift.min(max, Swift.max(min, value))
    }
}
