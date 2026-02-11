import SwiftUI

enum LevelEndState {
    case win
    case gameOver
}

private enum LevelCellStyle {

    static let playableGradient = LinearGradient(
        colors: [Color(hex: "D94A7A"), Color(hex: "ED6BEE")],
        startPoint: .top,
        endPoint: .bottom
    )

    static let lockedGradient = LinearGradient(
        colors: [Color(hex: "5D75FD"), Color(hex: "6CD9F6")],
        startPoint: .top,
        endPoint: .bottom
    )

    static let ringColor = Color.white.opacity(0.95)
    static let ringLineWidth: CGFloat = 3

    static let numberColor = Color.white
    static let numberFont = Font.system(size: 26, weight: .medium, design: .rounded)
}

private struct LevelCircleButton: View {

    let index: Int
    let state: LevelCellState
    let size: CGFloat
    let onTap: () -> Void

    private var ringLineWidth: CGFloat {
        max(2, size * 0.06)
    }

    var body: some View {
        Button {
            if state != .locked { onTap() }
        } label: {
            ZStack {
                fill
                    .frame(width: size, height: size)
                    .clipShape(Circle())

                Circle()
                    .stroke(Color.white.opacity(0.95), lineWidth: ringLineWidth)
                    .frame(width: size, height: size)

                Text("\(index)")
                    .font(AppFont.regular(size: 25, weight: .regular))
                    .foregroundStyle(Color.white)
                    .offset(y: -size * 0.02)
            }
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(state == .locked)
        .opacity(state == .locked ? 0.95 : 1.0)
        .accessibilityLabel("Level \(index)")
    }

    @ViewBuilder
    private var fill: some View {
        switch state {
        case .completed:
            Color.white.opacity(0.12)
        case .playable:
            LevelCellStyle.playableGradient
        case .locked:
            LevelCellStyle.lockedGradient
        }
    }
}


private struct LevelsGrid: View {

    @EnvironmentObject private var ps: ProgressStore

    private let totalLevels: Int = 12
    private let columns: Int = 4

    let maxGridHeightRatio: CGFloat
    let scale: ScreenScale

    var body: some View {
        GeometryReader { geo in
            let rows = Int(ceil(Double(totalLevels) / Double(columns)))

            let w = geo.size.width
            let h = geo.size.height

            let gridMaxHeight = floor(h * maxGridHeightRatio)

            let spacing = scale.v(18).clamped(to: 10...28)

            let minCircle = scale.v(44).clamped(to: 38...54)

            let maxCircleByWidth = floor((w - spacing * CGFloat(columns - 1)) / CGFloat(columns))
            let maxCircleByHeight = floor((gridMaxHeight - spacing * CGFloat(max(0, rows - 1))) / CGFloat(rows))


            let circleByWidth = maxCircleByWidth
            let circleByHeight = maxCircleByHeight

            let circleSize = max(minCircle, min(circleByWidth, circleByHeight))

            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.fixed(circleSize), spacing: spacing, alignment: .center),
                    count: columns
                ),
                alignment: .center,
                spacing: spacing
            ) {
                ForEach(1...totalLevels, id: \.self) { level in
                    LevelCircleButton(
                        index: level,
                        state: cellState(for: level),
                        size: circleSize
                    ) {
                        ps.selectedLevel = level
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: gridMaxHeight, alignment: .center)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private func cellState(for level: Int) -> LevelCellState {
        let maxUnlocked = ps.maxUnlockedLevel(maxLevel: totalLevels)
        let completed = ps.completedLevels.contains(level)

        if completed { return .completed }
        if level <= maxUnlocked { return .playable }
        return .locked
    }
}


struct LevelsView: View {
    @EnvironmentObject private var ps: ProgressStore
    @Environment(\.dismiss) private var dismiss

    @State private var showLevelInfoOverlay: Bool = false

    private let packs: [LevelPack] = LevelFactory.makeAllLevelPacks()

    private var startGameBinding: Binding<Bool> {
        Binding(
            get: { ps.shouldStartGame },
            set: { newValue in
                if newValue == false {
                    ps.resetStartFlag()
                }
            }
        )
    }

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
                    let scale = ScreenScale(size: geo.size)

                    VStack(spacing: 0) {
                        Image(.contentRect)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .overlay(alignment: .top) {
                                Image(.levelsTop)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 50)
                                    .offset(y: -25)
                            }
                            .overlay {
                                LevelsGrid(
                                    maxGridHeightRatio: 0.6,
                                    scale: scale
                                )
                                .padding(.horizontal, scale.v(18).clamped(to: 10...26))
                                .padding(.vertical, scale.v(16).clamped(to: 10...24))
                            }
                            .overlay(alignment: .bottom) {
                                Button {
                                    showLevelInfoOverlay = true
                                } label: {
                                    Image(.playBtn)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 50)
                                        .offset(y: 25)
                                        .opacity(ps.canPlaySelectedLevel() ? 1.0 : 0.4)
                                }
                                .buttonStyle(.plain)
                                .disabled(!ps.canPlaySelectedLevel())
                            }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    
                }
            },
            leftTop: {
                Button { dismiss() } label: { Image(.homeBtn) }
                    .padding(.leading, 12)
            },
            rightTop: {
                ZStack {
                    Image(.balance)
                        .padding(.trailing, 12)

                    HStack(spacing: 6) {
                        Text("\(ps.coins)")
                            .font(AppFont.regular(size: 30, weight: .regular))
                            .foregroundStyle(.white)

                        Image(.coinImg)
                    }
                }
            }
        )
        
        .fullScreenCover(isPresented: startGameBinding) {
            GameScreen(levelIndex: ps.selectedLevel)
                .environmentObject(ps)
                .onDisappear {
                    ps.resetStartFlag()
                }
        }
        .overlay {
            if showLevelInfoOverlay {
                LevelInfoOverlay(
                    pack: packForSelectedLevel(),
                    onClose: { showLevelInfoOverlay = false },
                    onPlay: {
                        showLevelInfoOverlay = false
                        ps.startSelectedLevel()
                    }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: showLevelInfoOverlay)
    }

    private func packForSelectedLevel() -> LevelPack {
        let idx = max(1, min(ps.selectedLevel, packs.count)) - 1
        return packs[idx]
    }
}

#Preview("Levels") {
    NavigationStack {
        LevelsView()
            .ignoresSafeArea()
            .environmentObject(ProgressStore())
    }
}



struct LevelInfoOverlay: View {

    let pack: LevelPack
    let onClose: () -> Void
    let onPlay: () -> Void

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width

            let cardW = w * 0.3

            let playW = cardW * 0.82
            let playH = playW * 0.28
            ZStack {
                Color.black.opacity(0.55)
                    .ignoresSafeArea()
                    .onTapGesture { onClose() }

                ZStack {
                    Image(.textImg)
                        .resizable()
                        .scaledToFit()
                        .frame(width: cardW)

                    VStack(spacing: 0) {
                        Text("\(pack.level.index)")
                            .font(AppFont.regular(size: max(22, cardW * 0.20), weight: .regular))
                            .foregroundStyle(.white)
                            .padding(.top)

                        Spacer(minLength: 0)

                        
                        VStack(spacing: 8) {
                            Text(pack.level.intro.uiLines.first ?? "")
                                .font(AppFont.regular(size: max(12, cardW * 0.08), weight: .regular))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                                .minimumScaleFactor(0.7)

                            Text(pack.level.intro.uiLines.dropFirst().first ?? "")
                                .font(AppFont.regular(size: max(12, cardW * 0.08), weight: .regular))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                                .minimumScaleFactor(0.7)
                        }
                        .padding(.horizontal, cardW * 0.12)
                        .padding(.bottom, cardW * 0.18)
                    }
                    .frame(width: cardW, height: cardW)
                }
                .overlay(alignment: .bottom) {
                    Button {
                        onPlay()
                    } label: {
                        Image(.playBtn)
                            .resizable()
                            .scaledToFit()
                            .frame(width: playW * 0.8)
                            .offset(y: playH * 0.5)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}


private extension RuleSet {

    var uiTextForPopup: String {
        
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if let lines = child.value as? [String], !lines.isEmpty {
                return lines.joined(separator: "\n")
            }
        }

       
        for child in mirror.children {
            let inner = Mirror(reflecting: child.value)
            for innerChild in inner.children {
                if let lines = innerChild.value as? [String], !lines.isEmpty {
                    return lines.joined(separator: "\n")
                }
            }
        }

        return String(describing: self)
    }
}


private extension LevelIntro {

    var uiLines: [String] {
        let mirror = Mirror(reflecting: self)
        let strings = mirror.children.compactMap { $0.value as? String }
        if strings.count >= 2 {
            return Array(strings.prefix(2))
        }
        if strings.count == 1 {
            return [strings[0], ""]
        }
        return ["", ""]
    }
}


struct LevelEndOverlay: View {

    let levelIndex: Int
    let state: LevelEndState

    let onRetry: () -> Void
    let onMenu: () -> Void

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let cardW = w * 0.28

            ZStack {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()

                ZStack {
                    Image(backgroundImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: cardW)

                    VStack(spacing: 12) {
                        Text("\(levelIndex)")
                            .font(AppFont.regular(size: cardW * 0.22, weight: .regular))
                            .foregroundStyle(.white)

                        Text(titleText)
                            .font(AppFont.regular(size: cardW * 0.14, weight: .regular))
                            .foregroundStyle(.white)
                    }
                }
                .overlay(alignment: .bottom) {
                    VStack(spacing: 14) {
                        Button { onRetry() } label: {
                            Image(retryImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: cardW * 0.78)
                        }

                        Button { onMenu() } label: {
                            Image(.menuBtn)
                                .resizable()
                                .scaledToFit()
                                .frame(width: cardW * 0.78)
                        }
                    }
                    .offset(y: cardW * 0.55)
                }
            }
        }
    }

    private var backgroundImage: ImageResource {
        state == .win ? .winImg : .textImg
    }

    private var titleText: String {
        state == .win ? "VICTORY" : "GAME OVER"
    }

    private var retryImage: ImageResource {
         .retryBtn
    }
}
