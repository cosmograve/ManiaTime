//
//  DomainModels.swift
//  OnOffBoat
//
//  Created by You on 2026-01-28.
//

import Foundation

// MARK: - Bank Side

enum BankSide: String, Codable, CaseIterable, Hashable {
    case left
    case right

    var opposite: BankSide { self == .left ? .right : .left }
}

// MARK: - Object Type

enum GameObjectType: String, Codable, CaseIterable, Hashable {
    case student
    case janitor
    case gardener

    var displayName: String {
        switch self {
        case .student: return "Schoolgirl"
        case .janitor: return "Janitor"
        case .gardener: return "Gardener"
        }
    }
}

// MARK: - Game Object (instance)

struct GameObject: Identifiable, Codable, Hashable {
    let id: UUID
    let type: GameObjectType
    let name: String

    init(id: UUID = UUID(), type: GameObjectType, name: String) {
        self.id = id
        self.type = type
        self.name = name
    }
}

// MARK: - Level Intro (2 sentences, English)

struct LevelIntro: Codable, Hashable {
    let line1: String
    let line2: String

    init(_ line1: String, _ line2: String) {
        self.line1 = line1
        self.line2 = line2
    }
}

// MARK: - Level Definition

struct LevelDefinition: Codable, Hashable {
    let index: Int
    let title: String
    let intro: LevelIntro

    let objects: [GameObject]

    let initialBoatSide: BankSide
    let initialLeft: Set<UUID>
    let initialRight: Set<UUID>

    let goalOnRight: Set<UUID>

    /// Fixed by your rules: 2
    let boatCapacity: Int

    /// Optional. If nil – no limit.
    let crossingsLimit: Int?

    init(
        index: Int,
        title: String,
        intro: LevelIntro,
        objects: [GameObject],
        initialBoatSide: BankSide = .left,
        initialLeft: Set<UUID>,
        initialRight: Set<UUID>,
        goalOnRight: Set<UUID>? = nil,
        boatCapacity: Int = 2,
        crossingsLimit: Int? = nil
    ) {
        self.index = index
        self.title = title
        self.intro = intro
        self.objects = objects
        self.initialBoatSide = initialBoatSide
        self.initialLeft = initialLeft
        self.initialRight = initialRight

        let allIds = Set(objects.map { $0.id })
        self.goalOnRight = goalOnRight ?? allIds

        self.boatCapacity = boatCapacity
        self.crossingsLimit = crossingsLimit
    }

    var objectById: [UUID: GameObject] {
        Dictionary(uniqueKeysWithValues: objects.map { ($0.id, $0) })
    }

    func validate() -> LevelValidationResult {
        let allIds = Set(objects.map { $0.id })

        if boatCapacity != 2 {
            return .invalid("boatCapacity must be 2 by the game rules.")
        }

        if !initialLeft.isSubset(of: allIds) { return .invalid("initialLeft has unknown ids.") }
        if !initialRight.isSubset(of: allIds) { return .invalid("initialRight has unknown ids.") }

        if !initialLeft.intersection(initialRight).isEmpty {
            return .invalid("An object is placed on both banks at start.")
        }

        if initialLeft.union(initialRight) != allIds {
            return .invalid("Not all objects are placed on banks at start.")
        }

        if !goalOnRight.isSubset(of: allIds) {
            return .invalid("goalOnRight has unknown ids.")
        }

        return .valid
    }
}

enum LevelValidationResult: Hashable {
    case valid
    case invalid(String)
}

// MARK: - Runtime State (IMPORTANT: boatCargo is new)

struct GameState: Codable, Hashable {
    /// Where the boat is docked right now.
    var boatSide: BankSide

    /// Who is on the left bank.
    var left: Set<UUID>

    /// Who is on the right bank.
    var right: Set<UUID>

    /// Who is currently inside the boat (cargo).
    var boatCargo: Set<UUID>

    /// How many crossings (boat moves) were made.
    var crossings: Int

    static func makeInitial(from level: LevelDefinition) -> GameState {
        GameState(
            boatSide: level.initialBoatSide,
            left: level.initialLeft,
            right: level.initialRight,
            boatCargo: [],
            crossings: 0
        )
    }

    func bank(_ side: BankSide) -> Set<UUID> {
        side == .left ? left : right
    }

    /// Win: all goal objects are on the right bank (boat cargo doesn't count).
    func isWin(goalOnRight: Set<UUID>) -> Bool {
        goalOnRight.isSubset(of: right)
    }
}

// MARK: - Player Actions (instead of Move)

/// Player can only do these actions:
/// 1) Load from the bank where the boat is docked -> to boat
/// 2) Unload from boat -> to the bank where the boat is docked
/// 3) Sail (tap on boat) -> boat moves to the opposite side (only if boatCargo not empty)
enum PlayerAction: Codable, Hashable {
    case loadToBoat(objectId: UUID)
    case unloadFromBoat(objectId: UUID)
    case sail
}

// MARK: - Rules Infrastructure

struct RuleViolation: Error, Hashable {
    let message: String
}

protocol Rule {
    func validate(level: LevelDefinition, from state: GameState, action: PlayerAction, to newState: GameState) -> RuleViolation?
}

struct RuleSet {
    let rules: [Rule]

    init(_ rules: [Rule]) {
        self.rules = rules
    }

    func firstViolation(level: LevelDefinition, from state: GameState, action: PlayerAction, to newState: GameState) -> RuleViolation? {
        for rule in rules {
            if let v = rule.validate(level: level, from: state, action: action, to: newState) {
                return v
            }
        }
        return nil
    }
}

// MARK: - Scoring (as you defined)

struct LevelResult: Codable, Hashable {
    let didWin: Bool
    let score: Int
    let coins: Int
    let playerCrossings: Int
    let optimalCrossings: Int?

    init(didWin: Bool, playerCrossings: Int, optimalCrossings: Int?) {
        self.didWin = didWin
        self.playerCrossings = playerCrossings
        self.optimalCrossings = optimalCrossings

        self.score = didWin ? 1 : 0

        guard didWin else {
            self.coins = 0
            return
        }

        guard let optimalCrossings, optimalCrossings > 0 else {
            self.coins = 1
            return
        }

        let extra = playerCrossings - optimalCrossings

        if extra <= 0 {
            self.coins = 3
        } else if extra == 1 {
            self.coins = 2
        } else {
            self.coins = 1
        }
    }
}

protocol OptimalCrossingsSolver {
    func minimalCrossings(for level: LevelDefinition, rules: RuleSet) -> Int?
}
