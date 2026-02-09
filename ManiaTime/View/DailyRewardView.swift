import SwiftUI

struct DailyRewardView: View {

    @EnvironmentObject private var ps: ProgressStore

    let coins: Int
    let day: Int
    let maxDays: Int

    let onClaim: () -> Void

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
                    let w = geo.size.width
                    let h = geo.size.height

                    VStack(spacing: 0) {
                        Image(.contentRect)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .overlay(alignment: .top) {
                                Image(.dailyReward)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 50)
                                    .offset(y: -25)
                            }
                            .overlay {
                                VStack(spacing: 0) {
                                    DailyRewardAssets.top
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: h * 0.18)
                                        .padding(.top, h * 0.06)

                                    DailyRewardGrid(day: day)
                                        .frame(maxWidth: w * 0.62, maxHeight: h * 0.70)

                                    Spacer(minLength: 10)
                                }
                                .padding(.vertical, 10)
                            }
                            .overlay(alignment: .bottom) {
                                Button {
                                    onClaim()
                                } label: {
                                    Image(.getBtn)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 50)
                                        .offset(y: 25)
                                }
                                .buttonStyle(.plain)
                            }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            },
            leftTop: {
                Button {
                    ps.closeDailyHub()
                } label: {
                    Image(.homeBtn)
                }
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
    }
}

enum DailyRewardAssets {
    static let top = Image(.dailyTop)
    static let coin = Image(.dailyCoin)
    static let empty = Image(.dailyEmpty)
    static let get = Image(.getBtn)
}

struct DailyRewardGrid: View {
    
    let day: Int
    
    private let columns = 3
    private let rows = 2
    private let total = 6
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            let maxGridHeight = h * 0.5
            let spacing = max(10, min(22, min(w, h) * 0.06))
            
            let cellByW = floor((w - spacing * CGFloat(columns - 1)) / CGFloat(columns))
            let cellByH = floor((maxGridHeight - spacing * CGFloat(rows - 1)) / CGFloat(rows))
            let cellSize = max(44, min(cellByW, cellByH))
            
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.fixed(cellSize), spacing: spacing, alignment: .center),
                    count: columns
                ),
                alignment: .center,
                spacing: spacing
            ) {
                ForEach(1...total, id: \.self) { i in
                    Image(i <= day ? .dailyCoin : .dailyEmpty)
                        .resizable()
                        .scaledToFit()
                        .frame(width: cellSize, height: cellSize)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}

#Preview {
    DailyRewardView(coins: 10, day: 1, maxDays: 7, onClaim: {})
    .ignoresSafeArea()
    .environmentObject(ProgressStore())
}
