import Foundation

enum RuleSetFactory {

    private static func baseRules() -> [Rule] {
        [
            LoadUnloadValidityRule(),
            BoatCapacityRule(),
            BoatMustHavePassengerToSailRule(),
            CrossingsLimitRule()
        ]
    }

    static func makeRules(includeC1: Bool, includeC2: Bool) -> RuleSet {
        var rules = baseRules()
        if includeC1 { rules.append(SchoolgirlCannotBeAloneWithGardenerRule()) }
        if includeC2 { rules.append(SchoolgirlCannotBeAloneWithJanitorRule()) }
        return RuleSet(rules)
    }

    static func makeTutorialRules() -> RuleSet {
        RuleSet(baseRules())
    }

    static func makeEasyRules() -> RuleSet {
        var rules = baseRules()
        rules.append(SchoolgirlCannotBeAloneWithGardenerRule())
        return RuleSet(rules)
    }

    static func makeMediumRules() -> RuleSet {
        var rules = baseRules()
        rules.append(SchoolgirlCannotBeAloneWithJanitorRule())
        return RuleSet(rules)
    }

    static func makeHardRules() -> RuleSet {
        makeRules(includeC1: true, includeC2: true)
    }
}
