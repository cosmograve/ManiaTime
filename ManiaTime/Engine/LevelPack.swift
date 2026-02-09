import Foundation

struct LevelPack {
    let level: LevelDefinition
    let rules: RuleSet
}

enum LevelFactory {

    static func makeAllLevelPacks() -> [LevelPack] {
        [
            makeTutorialLevel(),
            makeLevel2(),
            makeLevel3(),
            makeLevel4(),
            makeLevel5(),
            makeLevel6(),
            makeLevel7(),
            makeLevel8(),
            makeLevel9(),
            makeLevel10(),
            makeLevel11(),
            makeLevel12()
        ]
    }

    private static func makeTutorialLevel() -> LevelPack {
        let student1 = GameObject(type: .student, name: "Schoolgirl #1")
        let student2 = GameObject(type: .student, name: "Schoolgirl #2")

        let objects = [student1, student2]
        let left: Set<UUID> = Set(objects.map { $0.id })
        let right: Set<UUID> = []

        let level = LevelDefinition(
            index: 1,
            title: "First Crossing",
            intro: LevelIntro(
                "Welcome to the river crossing puzzle.",
                "Drag characters to the boat, then tap the boat to sail."
            ),
            objects: objects,
            initialBoatSide: .left,
            initialLeft: left,
            initialRight: right,
            goalOnRight: Set(objects.map { $0.id }),
            boatCapacity: 2,
            crossingsLimit: 5
        )

        let rules = RuleSetFactory.makeTutorialRules()
        return LevelPack(level: level, rules: rules)
    }

    private static func makeLevel2() -> LevelPack {
        let student1 = GameObject(type: .student, name: "Schoolgirl")
        let student2 = GameObject(type: .student, name: "Schoolgirl")
        let gardener = GameObject(type: .gardener, name: "Gardener")

        let objects = [student1, student2, gardener]
        let left: Set<UUID> = Set(objects.map { $0.id })
        let right: Set<UUID> = []

        let level = LevelDefinition(
            index: 2,
            title: "The Gardener",
            intro: LevelIntro(
                "A gardener joined the crossing.",
                "Rule: A schoolgirl can't be alone with a gardener."
            ),
            objects: objects,
            initialBoatSide: .left,
            initialLeft: left,
            initialRight: right,
            goalOnRight: Set(objects.map { $0.id }),
            boatCapacity: 2,
            crossingsLimit: 7
        )

        let rules = RuleSetFactory.makeEasyRules()
        return LevelPack(level: level, rules: rules)
    }

    private static func makeLevel3() -> LevelPack {
        let student1 = GameObject(type: .student, name: "Schoolgirl")
        let student2 = GameObject(type: .student, name: "Schoolgirl")
        let janitor = GameObject(type: .janitor, name: "Janitor")

        let objects = [student1, student2, janitor]
        let left: Set<UUID> = Set(objects.map { $0.id })
        let right: Set<UUID> = []

        let level = LevelDefinition(
            index: 3,
            title: "The Janitor",
            intro: LevelIntro(
                "Now a janitor wants to cross too.",
                "Rule: A schoolgirl can't be alone with a janitor."
            ),
            objects: objects,
            initialBoatSide: .left,
            initialLeft: left,
            initialRight: right,
            goalOnRight: Set(objects.map { $0.id }),
            boatCapacity: 2,
            crossingsLimit: 7
        )

        let rules = RuleSetFactory.makeMediumRules()
        return LevelPack(level: level, rules: rules)
    }

    private static func makeLevel4() -> LevelPack {
        let student = GameObject(type: .student, name: "Schoolgirl")
        let janitor = GameObject(type: .janitor, name: "Janitor")
        let gardener = GameObject(type: .gardener, name: "Gardener")

        let objects = [student, janitor, gardener]
        let left: Set<UUID> = Set(objects.map { $0.id })
        let right: Set<UUID> = []

        let level = LevelDefinition(
            index: 4,
            title: "The Trio",
            intro: LevelIntro(
                "All three types need to cross together.",
                "Remember both rules as you plan your trip."
            ),
            objects: objects,
            initialBoatSide: .left,
            initialLeft: left,
            initialRight: right,
            goalOnRight: Set(objects.map { $0.id }),
            boatCapacity: 2,
            crossingsLimit: 9
        )

        let rules = RuleSetFactory.makeHardRules()
        return LevelPack(level: level, rules: rules)
    }

    private static func makeLevel5() -> LevelPack {
        let students = (1...2).map { GameObject(type: .student, name: "Schoolgirl #\($0)") }
        let janitors = (1...2).map { GameObject(type: .janitor, name: "Janitor #\($0)") }
        let gardeners = (1...2).map { GameObject(type: .gardener, name: "Gardener #\($0)") }

        let objects = students + janitors + gardeners
        let left: Set<UUID> = Set(objects.map { $0.id })
        let right: Set<UUID> = []

        let level = LevelDefinition(
            index: 5,
            title: "Balanced Groups",
            intro: LevelIntro(
                "Two of each type makes coordination important.",
                "Plan carefully to avoid leaving schoolgirls in bad pairs."
            ),
            objects: objects,
            initialBoatSide: .left,
            initialLeft: left,
            initialRight: right,
            goalOnRight: Set(objects.map { $0.id }),
            boatCapacity: 2,
            crossingsLimit: 11
        )

        let rules = RuleSetFactory.makeHardRules()
        return LevelPack(level: level, rules: rules)
    }

    private static func makeLevel6() -> LevelPack {
        let students = (1...3).map { GameObject(type: .student, name: "Schoolgirl #\($0)") }
        let janitors = (1...2).map { GameObject(type: .janitor, name: "Janitor #\($0)") }
        let gardener = GameObject(type: .gardener, name: "Gardener")

        let objects = students + janitors + [gardener]
        let left: Set<UUID> = Set(objects.map { $0.id })
        let right: Set<UUID> = []

        let level = LevelDefinition(
            index: 6,
            title: "School Trip",
            intro: LevelIntro(
                "Three schoolgirls on an excursion.",
                "With limited supervisors, every move counts."
            ),
            objects: objects,
            initialBoatSide: .left,
            initialLeft: left,
            initialRight: right,
            goalOnRight: Set(objects.map { $0.id }),
            boatCapacity: 2,
            crossingsLimit: 13
        )

        let rules = RuleSetFactory.makeHardRules()
        return LevelPack(level: level, rules: rules)
    }

    private static func makeLevel7() -> LevelPack {
        let students = (1...2).map { GameObject(type: .student, name: "Schoolgirl #\($0)") }
        let janitors = (1...2).map { GameObject(type: .janitor, name: "Janitor #\($0)") }
        let gardeners = (1...2).map { GameObject(type: .gardener, name: "Gardener #\($0)") }

        let objects = students + janitors + gardeners
        let left: Set<UUID> = [students[0].id, janitors[0].id, gardeners[0].id]
        let right: Set<UUID> = [students[1].id, janitors[1].id, gardeners[1].id]

        let level = LevelDefinition(
            index: 7,
            title: "Split Groups",
            intro: LevelIntro(
                "The groups started on opposite banks.",
                "Reunite everyone while following all rules."
            ),
            objects: objects,
            initialBoatSide: .left,
            initialLeft: left,
            initialRight: right,
            goalOnRight: Set(objects.map { $0.id }),
            boatCapacity: 2,
            crossingsLimit: 11
        )

        let rules = RuleSetFactory.makeHardRules()
        return LevelPack(level: level, rules: rules)
    }

    private static func makeLevel8() -> LevelPack {
        let students = (1...2).map { GameObject(type: .student, name: "Schoolgirl #\($0)") }
        let janitors = (1...2).map { GameObject(type: .janitor, name: "Janitor #\($0)") }
        let gardeners = (1...2).map { GameObject(type: .gardener, name: "Gardener #\($0)") }

        let objects = students + janitors + gardeners

        let right: Set<UUID> = [janitors[0].id]
        var left: Set<UUID> = Set(objects.map { $0.id })
        left.remove(janitors[0].id)

        let level = LevelDefinition(
            index: 8,
            title: "Boat on the Other Side",
            intro: LevelIntro(
                "The boat is waiting on the opposite bank.",
                "Bring it back with someone, then start crossings."
            ),
            objects: objects,
            initialBoatSide: .right,
            initialLeft: left,
            initialRight: right,
            goalOnRight: Set(objects.map { $0.id }),
            boatCapacity: 2,
            crossingsLimit: 15
        )

        let rules = RuleSetFactory.makeHardRules()
        return LevelPack(level: level, rules: rules)
    }

    private static func makeLevel9() -> LevelPack {
        let students = (1...3).map { GameObject(type: .student, name: "Schoolgirl #\($0)") }
        let janitors = (1...3).map { GameObject(type: .janitor, name: "Janitor #\($0)") }
        let gardeners = (1...3).map { GameObject(type: .gardener, name: "Gardener #\($0)") }

        let objects = students + janitors + gardeners
        let left: Set<UUID> = Set(objects.map { $0.id })
        let right: Set<UUID> = []

        let level = LevelDefinition(
            index: 9,
            title: "Bigger Boat",
            intro: LevelIntro(
                "The boat can now carry three passengers!",
                "Use the extra capacity to solve efficiently."
            ),
            objects: objects,
            initialBoatSide: .left,
            initialLeft: left,
            initialRight: right,
            goalOnRight: Set(objects.map { $0.id }),
            boatCapacity: 3,
            crossingsLimit: 11
        )

        let rules = RuleSetFactory.makeHardRules()
        return LevelPack(level: level, rules: rules)
    }

    private static func makeLevel10() -> LevelPack {
        let students = (1...4).map { GameObject(type: .student, name: "Schoolgirl #\($0)") }
        let janitors = (1...3).map { GameObject(type: .janitor, name: "Janitor #\($0)") }
        let gardeners = (1...3).map { GameObject(type: .gardener, name: "Gardener #\($0)") }

        let objects = students + janitors + gardeners
        let left: Set<UUID> = Set(objects.map { $0.id })
        let right: Set<UUID> = []

        let level = LevelDefinition(
            index: 10,
            title: "Large Party",
            intro: LevelIntro(
                "Ten people need to cross together.",
                "With so many, careful planning is essential."
            ),
            objects: objects,
            initialBoatSide: .left,
            initialLeft: left,
            initialRight: right,
            goalOnRight: Set(objects.map { $0.id }),
            boatCapacity: 2,
            crossingsLimit: 19
        )

        let rules = RuleSetFactory.makeHardRules()
        return LevelPack(level: level, rules: rules)
    }

    private static func makeLevel11() -> LevelPack {
        let students = (1...3).map { GameObject(type: .student, name: "Schoolgirl #\($0)") }
        let janitors = (1...2).map { GameObject(type: .janitor, name: "Janitor #\($0)") }
        let gardener = GameObject(type: .gardener, name: "Gardener")

        let objects = students + janitors + [gardener]
        let left: Set<UUID> = [students[0].id, gardener.id]
        let right: Set<UUID> = [students[1].id, students[2].id, janitors[0].id, janitors[1].id]

        let level = LevelDefinition(
            index: 11,
            title: "Tricky Start",
            intro: LevelIntro(
                "You arrive to a complicated situation.",
                "Quickly fix the rule violation before proceeding."
            ),
            objects: objects,
            initialBoatSide: .left,
            initialLeft: left,
            initialRight: right,
            goalOnRight: Set(objects.map { $0.id }),
            boatCapacity: 2,
            crossingsLimit: 15
        )

        let rules = RuleSetFactory.makeHardRules()
        return LevelPack(level: level, rules: rules)
    }

    private static func makeLevel12() -> LevelPack {
        let students = (1...4).map { GameObject(type: .student, name: "Schoolgirl #\($0)") }
        let janitors = (1...3).map { GameObject(type: .janitor, name: "Janitor #\($0)") }
        let gardeners = (1...3).map { GameObject(type: .gardener, name: "Gardener #\($0)") }

        let objects = students + janitors + gardeners
        let left: Set<UUID> = [students[0].id, students[1].id, janitors[0].id, gardeners[0].id]
        let right: Set<UUID> = [students[2].id, students[3].id, janitors[1].id, janitors[2].id, gardeners[1].id, gardeners[2].id]

        let level = LevelDefinition(
            index: 12,
            title: "Master Challenge",
            intro: LevelIntro(
                "The ultimate test of river crossing skill.",
                "Combine everything you've learned to succeed."
            ),
            objects: objects,
            initialBoatSide: .right,
            initialLeft: left,
            initialRight: right,
            goalOnRight: Set(objects.map { $0.id }),
            boatCapacity: 2,
            crossingsLimit: 21
        )

        let rules = RuleSetFactory.makeHardRules()
        return LevelPack(level: level, rules: rules)
    }
}
