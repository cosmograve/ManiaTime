import SwiftUI
import SpriteKit

struct GameScreen: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var ps: ProgressStore

    @StateObject private var vm: GameViewModel
    @State private var scene: GameScene? = nil

    private var hasNextLevel: Bool {
        vm.level.index < ps.totalLevels
    }

    init(levelIndex: Int) {
        let packs = LevelFactory.makeAllLevelPacks()
        let safe = max(1, min(levelIndex, packs.count))
        let initialIndex = safe - 1

        _vm = StateObject(
            wrappedValue: GameViewModel(
                levelPacks: packs,
                initialIndex: initialIndex,
                solver: OptimalCrossingsBFSSolver()
            )
        )
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let scene {
                    SpriteView(scene: scene, options: [.ignoresSiblingOrder])
                        .ignoresSafeArea()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Color.black.ignoresSafeArea()
                }

                hudTop
                hudBottom

                if vm.isLose {
                    gameOverOverlay
                } else if vm.isWin, vm.levelResult != nil {
                    victoryOverlay
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .onAppear {
                let insets = UIEdgeInsets(
                    top: geo.safeAreaInsets.top,
                    left: geo.safeAreaInsets.leading,
                    bottom: geo.safeAreaInsets.bottom,
                    right: geo.safeAreaInsets.trailing
                )

                let hudTopReserved: CGFloat = 90
                let hudBottomReserved: CGFloat = 110

                if scene == nil {
                    DispatchQueue.main.async {
                        let newScene = GameScene(size: geo.size, viewModel: vm)
                        newScene.scaleMode = .resizeFill
                        newScene.debugShowZones = false
                        newScene.updateSafeArea(insets)
                        newScene.updateHUDInsets(top: hudTopReserved, bottom: hudBottomReserved)
                        scene = newScene
                        newScene.sync()
                    }
                } else {
                    scene?.updateSafeArea(insets)
                    scene?.updateHUDInsets(top: hudTopReserved, bottom: hudBottomReserved)
                    scene?.size = geo.size
                    scene?.scaleMode = .resizeFill
                    scene?.sync()
                }

                vm.startLevel()
                MusicManager.shared.play(scene: .game, forceRestart: true)
            }
            .onChange(of: geo.size) { newSize in
                let insets = UIEdgeInsets(
                    top: geo.safeAreaInsets.top,
                    left: geo.safeAreaInsets.leading,
                    bottom: geo.safeAreaInsets.bottom,
                    right: geo.safeAreaInsets.trailing
                )

                let hudTopReserved: CGFloat = 90
                let hudBottomReserved: CGFloat = 110

                scene?.updateSafeArea(insets)
                scene?.updateHUDInsets(top: hudTopReserved, bottom: hudBottomReserved)
                scene?.size = newSize
                scene?.scaleMode = .resizeFill
                scene?.sync()
            }
            .onDisappear {
                MusicManager.shared.play(scene: .menu, forceRestart: true)
            }

            .onChange(of: vm.state) { _ in
                scene?.sync()
            }
            .onChange(of: vm.sceneResetToken) { _ in
                scene?.resetForNewLevel()
                scene?.sync()
            }
            .onChange(of: vm.levelResult) { result in
                guard let result, vm.isWin else { return }
                ps.onWinIfPossible(levelIndex: vm.level.index, levelResult: result)
            }
        }
        .statusBarHidden(true)
        .ignoresSafeArea()
    }

    private var hudTop: some View {
        VStack {
            HStack(alignment: .top) {
                Button {
                    vm.restartLevel()
                    dismiss()
                } label: {
                    Image(.homeBtn)
                }
                .buttonStyle(.plain)
                .padding(.leading, 24)
                .padding(.top, 24)

                Spacer(minLength: 0)

                Text("Number of crossings: \(vm.state.crossings)")
                    .font(AppFont.regular(size: 30, weight: .regular))
                    .foregroundStyle(Color(hex: "BC7FDE"))
                    .padding(.top, 24)
                    .padding(.trailing, 24)
            }

            Spacer(minLength: 0)
        }
        .ignoresSafeArea()
    }

    private var hudBottom: some View {
        VStack {
            Spacer(minLength: 0)

            HStack {
                BankCountBadge(
                    value: vm.state.left.count,
                    gradient: LinearGradient(
                        colors: [Color(hex: "7E7CFC"), Color(hex: "C881FE")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .padding(.leading, 24)
                .padding(.bottom, 24)

                Spacer(minLength: 0)

                BankCountBadge(
                    value: vm.state.right.count,
                    gradient: LinearGradient(
                        colors: [Color(hex: "ED6BEE"), Color(hex: "D94A7A")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
        }
        .ignoresSafeArea()
    }

    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 0) {
                Image("textImg")
                    .resizable()
                    .scaledToFit()
                    .frame(width: UIScreen.main.bounds.width * 0.25)
                    .overlay {
                        VStack(spacing: 5) {
                            Text("\(vm.level.index)")
                                .font(AppFont.regular(size: 40, weight: .regular))
                                .foregroundStyle(.white)

                            Text("GAME OVER")
                                .font(AppFont.regular(size: 30, weight: .regular))
                                .foregroundStyle(.white)
                        }
                        .padding(.top, 10)
                    }

                VStack(spacing: 4) {
                    Button { vm.restartLevel() } label: { Image("retryBtn") }
                        .buttonStyle(.plain)

                    Button { dismiss() } label: { Image("menuBtn") }
                        .buttonStyle(.plain)
                }
                .offset(y: -24)
            }
        }
    }

    private var victoryOverlay: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()

            VStack(spacing: 0) {
                Image("winImg")
                    .resizable()
                    .scaledToFit()
                    .frame(width: UIScreen.main.bounds.width * 0.25)
                    .overlay {
                        VStack(spacing: 5) {
                            Text("\(vm.level.index)")
                                .font(AppFont.regular(size: 40, weight: .regular))
                                .foregroundStyle(.white)

                            Text("VICTORY")
                                .font(AppFont.regular(size: 30, weight: .regular))
                                .foregroundStyle(.white)
                        }
                        .padding(.top, 10)
                    }

                VStack(spacing: 4) {
                    Button { vm.restartLevel() } label: { Image("retryBtn") }
                        .buttonStyle(.plain)

                    Button {
                        if hasNextLevel {
                            vm.nextLevel()
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image("nextBtn")
                    }
                    .buttonStyle(.plain)
                }
                .offset(y: -24)
            }
        }
    }
}

struct BankCountBadge: View {

    let value: Int
    let gradient: LinearGradient

    private let size: CGFloat = 58
    private let ringWidth: CGFloat = 3

    var body: some View {
        ZStack {
            Circle()
                .fill(gradient)
                .frame(width: size, height: size)

            Circle()
                .stroke(Color.white.opacity(0.95), lineWidth: ringWidth)
                .frame(width: size, height: size)

            Text("\(value)")
                .font(AppFont.regular(size: 30, weight: .regular))
                .foregroundStyle(Color.white)
                .offset(y: -1)
        }
    }
}
