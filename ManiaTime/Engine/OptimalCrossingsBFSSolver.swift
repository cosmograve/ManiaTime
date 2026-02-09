
struct OptimalCrossingsBFSSolver: OptimalCrossingsSolver {
    func minimalCrossings(for level: LevelDefinition, rules: RuleSet) -> Int? {

        let start = GameState.makeInitial(from: level)

        if start.isWin(goalOnRight: level.goalOnRight) {
            return 0
        }

        var deque: [GameState] = [start]
        var bestCost: [GameState: Int] = [start: 0]

        while !deque.isEmpty {
            let state = deque.removeFirst()
            let currentCost = bestCost[state] ?? Int.max

            for action in availableActions(state: state, level: level) {

                guard let newState = apply(action: action, level: level, from: state) else {
                    continue
                }

                if let limit = level.crossingsLimit,
                   newState.crossings > limit {
                    continue
                }

                if rules.firstViolation(
                    level: level,
                    from: state,
                    action: action,
                    to: newState
                ) != nil {
                    continue
                }

                let addCost = (action == .sail) ? 1 : 0
                let newCost = currentCost + addCost

                if newCost < (bestCost[newState] ?? Int.max) {
                    bestCost[newState] = newCost

                    if addCost == 0 {
                        deque.insert(newState, at: 0)
                    } else {
                        deque.append(newState)
                    }

                    if newState.isWin(goalOnRight: level.goalOnRight) {
                        return newCost
                    }
                }
            }
        }

        return nil
    }

    // MARK: - Actions

    private func availableActions(
        state: GameState,
        level: LevelDefinition
    ) -> [PlayerAction] {

        var actions: [PlayerAction] = []

        let bankIds = state.bank(state.boatSide)

        if state.boatCargo.count < level.boatCapacity {
            for id in bankIds {
                actions.append(.loadToBoat(objectId: id))
            }
        }

        for id in state.boatCargo {
            actions.append(.unloadFromBoat(objectId: id))
        }

        if !state.boatCargo.isEmpty {
            actions.append(.sail)
        }

        return actions
    }

    // MARK: - Transition

    private func apply(
        action: PlayerAction,
        level: LevelDefinition,
        from state: GameState
    ) -> GameState? {

        var s = state

        switch action {

        case .loadToBoat(let id):
            if !s.bank(s.boatSide).contains(id) { return nil }
            if s.boatCargo.count >= level.boatCapacity { return nil }

            if s.boatSide == .left {
                s.left.remove(id)
            } else {
                s.right.remove(id)
            }
            s.boatCargo.insert(id)
            return s

        case .unloadFromBoat(let id):
            if !s.boatCargo.contains(id) { return nil }

            s.boatCargo.remove(id)
            if s.boatSide == .left {
                s.left.insert(id)
            } else {
                s.right.insert(id)
            }
            return s

        case .sail:
            if s.boatCargo.isEmpty { return nil }

            s.boatSide = s.boatSide.opposite
            s.crossings += 1
            return s
        }
    }
}
