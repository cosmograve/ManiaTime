import Combine
import Foundation

@MainActor
final class GameViewModel: ObservableObject {

    @Published private(set) var level: LevelDefinition
    @Published private(set) var state: GameState
    @Published private(set) var rules: RuleSet

    @Published private(set) var intro: LevelIntro
    @Published var isIntroVisible: Bool

    @Published private(set) var isWin: Bool
    @Published private(set) var levelResult: LevelResult?

    @Published private(set) var isLose: Bool

    @Published private(set) var sceneResetToken: Int = 0

    private let engine: GameEngine
    private let packs: [LevelPack]
    private var currentIndex: Int
    private let solver: OptimalCrossingsSolver?

    init(levelPacks: [LevelPack], initialIndex: Int = 0, solver: OptimalCrossingsSolver? = nil) {
        self.solver = solver
        self.packs = levelPacks

        let safeIndex = max(0, min(initialIndex, levelPacks.count - 1))
        self.currentIndex = safeIndex

        let pack = levelPacks[safeIndex]
        self.engine = GameEngine(level: pack.level, rules: pack.rules)

        self.level = pack.level
        self.rules = pack.rules
        self.state = engine.state

        self.intro = pack.level.intro
        self.isIntroVisible = true

        self.isWin = false
        self.levelResult = nil
        self.isLose = false
    }

    func startLevel() {
        isIntroVisible = false
    }

    func restartLevel() {
        engine.resetLevel()
        syncFromEngine()

        isIntroVisible = false
        levelResult = nil
        isWin = false
        isLose = false

        sceneResetToken &+= 1
    }

    func nextLevel() {
        guard currentIndex + 1 < packs.count else { return }
        currentIndex += 1
        loadCurrentPack()
    }

    func previousLevel() {
        guard currentIndex - 1 >= 0 else { return }
        currentIndex -= 1
        loadCurrentPack()
    }

    private func loadCurrentPack() {
        let pack = packs[currentIndex]

        engine.loadLevel(pack.level, rules: pack.rules)

        level = pack.level
        rules = pack.rules
        intro = pack.level.intro

        syncFromEngine()

        isIntroVisible = false
        levelResult = nil
        isWin = false
        isLose = false

        sceneResetToken &+= 1
    }

    func loadToBoat(objectId: UUID) { apply(.loadToBoat(objectId: objectId)) }
    func unloadFromBoat(objectId: UUID) { apply(.unloadFromBoat(objectId: objectId)) }
    func sail() { apply(.sail) }

    private func apply(_ action: PlayerAction) {
        guard !isIntroVisible else { return }
        guard !isWin else { return }
        guard !isLose else { return }

        let result = engine.apply(action)

        switch result {
        case .success:
            syncFromEngine()

            if isWin {
                isLose = false
                computeLevelResultIfNeeded()
            }

        case .failure:
            isLose = true
            levelResult = nil
        }
    }
    
    private func syncFromEngine() {
        state = engine.state
        isWin = engine.isWin
    }

    private func computeLevelResultIfNeeded() {
        guard isWin else { return }

        let playerCrossings = state.crossings
        let optimalCrossings = solver?.minimalCrossings(for: level, rules: rules)

        levelResult = LevelResult(
            didWin: true,
            playerCrossings: playerCrossings,
            optimalCrossings: optimalCrossings
        )
    }
}
