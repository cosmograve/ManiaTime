import Foundation

enum BankTypeCounter {
    static func counts(on bank: Set<UUID>, in level: LevelDefinition) -> [GameObjectType: Int] {
        let map = level.objectById
        var result: [GameObjectType: Int] = [.student: 0, .janitor: 0, .gardener: 0]

        for id in bank {
            guard let obj = map[id] else { continue }
            result[obj.type, default: 0] += 1
        }
        return result
    }

    static func totalCount(on bank: Set<UUID>) -> Int {
        bank.count
    }
}

struct SchoolgirlCannotBeAloneWithGardenerRule: Rule {
    func validate(
        level: LevelDefinition,
        from state: GameState,
        action: PlayerAction,
        to newState: GameState
    ) -> RuleViolation? {

        for side in BankSide.allCases {
            if newState.boatSide == side { continue }

            let bank = newState.bank(side)
            let c = BankTypeCounter.counts(on: bank, in: level)

            let hasStudent = (c[.student] ?? 0) > 0
            let hasGardener = (c[.gardener] ?? 0) > 0
            let hasJanitor = (c[.janitor] ?? 0) > 0

            if hasStudent && hasGardener && !hasJanitor {
                return RuleViolation(message: "A schoolgirl can't be alone with a gardener.")
            }
        }

        return nil
    }
}

struct SchoolgirlCannotBeAloneWithJanitorRule: Rule {
    func validate(
        level: LevelDefinition,
        from state: GameState,
        action: PlayerAction,
        to newState: GameState
    ) -> RuleViolation? {

        for side in BankSide.allCases {
            if newState.boatSide == side { continue }

            let bank = newState.bank(side)
            let c = BankTypeCounter.counts(on: bank, in: level)

            let hasStudent = (c[.student] ?? 0) > 0
            let hasJanitor = (c[.janitor] ?? 0) > 0
            let hasGardener = (c[.gardener] ?? 0) > 0

            if hasStudent && hasJanitor && !hasGardener {
                return RuleViolation(message: "A schoolgirl can't be alone with a janitor.")
            }
        }

        return nil
    }
}

struct BoatCapacityRule: Rule {
    func validate(
        level: LevelDefinition,
        from state: GameState,
        action: PlayerAction,
        to newState: GameState
    ) -> RuleViolation? {
        if newState.boatCargo.count > level.boatCapacity {
            return RuleViolation(message: "Boat capacity is \(level.boatCapacity).")
        }
        return nil
    }
}

struct BoatMustHavePassengerToSailRule: Rule {
    func validate(
        level: LevelDefinition,
        from state: GameState,
        action: PlayerAction,
        to newState: GameState
    ) -> RuleViolation? {
        guard case .sail = action else { return nil }
        if state.boatCargo.isEmpty {
            return RuleViolation(message: "The boat can't move without at least one passenger.")
        }
        return nil
    }
}

struct CrossingsLimitRule: Rule {
    func validate(
        level: LevelDefinition,
        from state: GameState,
        action: PlayerAction,
        to newState: GameState
    ) -> RuleViolation? {
        guard let limit = level.crossingsLimit else { return nil }
        if newState.crossings > limit {
            return RuleViolation(message: "Crossings limit exceeded.")
        }
        return nil
    }
}

struct LoadUnloadValidityRule: Rule {
    func validate(
        level: LevelDefinition,
        from state: GameState,
        action: PlayerAction,
        to newState: GameState
    ) -> RuleViolation? {

        switch action {
        case .loadToBoat(let id):
            if level.objectById[id] == nil {
                return RuleViolation(message: "Unknown object.")
            }

            if state.boatCargo.contains(id) {
                return RuleViolation(message: "This object is already in the boat.")
            }

            let sourceBank = state.bank(state.boatSide)
            if !sourceBank.contains(id) {
                return RuleViolation(message: "You can load only from the bank where the boat is docked.")
            }

            return nil

        case .unloadFromBoat(let id):
            if !state.boatCargo.contains(id) {
                return RuleViolation(message: "You can unload only from the boat.")
            }
            return nil

        case .sail:
            return nil
        }
    }
}
