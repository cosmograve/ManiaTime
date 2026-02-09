import Foundation

enum LevelSolvabilityChecker {

    struct Result {
        let levelIndex: Int
        let title: String
        let isSolvable: Bool
        let exploredStates: Int
        let solution: [PlayerAction]
    }

    static func checkAll(packs: [LevelPack]) -> [Result] {
        return packs.map { pack in
            checkOne(level: pack.level, rules: pack.rules)
        }
    }

    static func checkOne(level: LevelDefinition, rules: RuleSet) -> Result {
        let start = GameState.makeInitial(from: level)

        if start.isWin(goalOnRight: level.goalOnRight) {
            return Result(
                levelIndex: level.index,
                title: level.title,
                isSolvable: true,
                exploredStates: 1,
                solution: []
            )
        }

        var queue: [GameState] = [start]
        var head = 0

       
        var visited = Set<GameState>()
        visited.insert(start)

        
        var parent: [GameState: (GameState, PlayerAction)] = [:]

        while head < queue.count {
            let current = queue[head]
            head += 1

            let actions = possibleActions(from: current, level: level)

            for action in actions {
                let next = simulate(action, from: current)

                if let violation = rules.firstViolation(level: level, from: current, action: action, to: next) {
                    _ = violation
                    continue
                }

                if let limit = level.crossingsLimit, next.crossings > limit {
                    continue
                }

                if visited.contains(next) { continue }

                visited.insert(next)
                parent[next] = (current, action)
                queue.append(next)

                if next.isWin(goalOnRight: level.goalOnRight) {
                    let path = reconstructPath(end: next, parent: parent)
                    return Result(
                        levelIndex: level.index,
                        title: level.title,
                        isSolvable: true,
                        exploredStates: visited.count,
                        solution: path
                    )
                }
            }
        }

        return Result(
            levelIndex: level.index,
            title: level.title,
            isSolvable: false,
            exploredStates: visited.count,
            solution: []
        )
    }

    
    private static func possibleActions(from state: GameState, level: LevelDefinition) -> [PlayerAction] {
        var result: [PlayerAction] = []

        let bank = state.bank(state.boatSide)
        if state.boatCargo.count < level.boatCapacity {
            for id in bank {
                if state.boatCargo.contains(id) { continue }
                result.append(.loadToBoat(objectId: id))
            }
        }

        for id in state.boatCargo {
            result.append(.unloadFromBoat(objectId: id))
        }

        if !state.boatCargo.isEmpty {
            result.append(.sail)
        }

        return result
    }


    private static func simulate(_ action: PlayerAction, from current: GameState) -> GameState {
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


    private static func reconstructPath(end: GameState, parent: [GameState: (GameState, PlayerAction)]) -> [PlayerAction] {
        var actions: [PlayerAction] = []
        var cur = end

        while let (prev, action) = parent[cur] {
            actions.append(action)
            cur = prev
        }

        return actions.reversed()
    }
}
