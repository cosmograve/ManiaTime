import Foundation

enum ApplyActionResult: Hashable {
    case success
    case failure(String)
}

final class GameEngine {

    private(set) var level: LevelDefinition
    private(set) var rules: RuleSet
    private(set) var state: GameState

    init(level: LevelDefinition, rules: RuleSet) {
        self.level = level
        self.rules = rules
        self.state = GameState.makeInitial(from: level)
        _ = level.validate()
    }

    var isWin: Bool {
        state.isWin(goalOnRight: level.goalOnRight)
    }

    func resetLevel() {
        state = GameState.makeInitial(from: level)
    }

    func loadLevel(_ level: LevelDefinition, rules: RuleSet) {
        self.level = level
        self.rules = rules
        self.state = GameState.makeInitial(from: level)
        _ = level.validate()
    }

    @discardableResult
    func apply(_ action: PlayerAction) -> ApplyActionResult {
        let newState = simulate(action, from: state)

        if let violation = rules.firstViolation(level: level, from: state, action: action, to: newState) {
            return .failure(violation.message)
        }

        state = newState
        return .success
    }

    func simulate(_ action: PlayerAction, from current: GameState) -> GameState {
        var next = current

        switch action {
        case .loadToBoat(let id):
            let side = current.boatSide
            if side == .left {
                next.left.remove(id)
            } else {
                next.right.remove(id)
            }
            next.boatCargo.insert(id)

        case .unloadFromBoat(let id):
            next.boatCargo.remove(id)
            let side = current.boatSide
            if side == .left {
                next.left.insert(id)
            } else {
                next.right.insert(id)
            }

        case .sail:
            next.boatSide = current.boatSide.opposite
            next.crossings += 1
        }

        return next
    }
}
