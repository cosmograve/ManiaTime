import Foundation
import SwiftUI
import Combine

// MARK: - Achievements

enum AchievementID: String, Codable, CaseIterable, Identifiable, Hashable {
    case boat
    case calendarFirst
    case clock
    case threeStars

    var id: String { rawValue }
    var coinReward: Int { 10 }

    var title: String {
        switch self {
        case .boat: return "River Pro"
        case .calendarFirst: return "Daily Champion"
        case .clock: return "Speedrunner"
        case .threeStars: return "Three Stars"
        }
    }

    var subtitle: String {
        switch self {
        case .boat: return "Complete Level 4."
        case .calendarFirst: return "Open the game 5 days in a row."
        case .clock: return "Finish 5 levels with optimal crossings."
        case .threeStars: return "Finish all 12 levels and 8 of them optimally."
        }
    }
}

struct AchievementState: Codable, Identifiable, Equatable {
    let id: AchievementID
    var isUnlocked: Bool
    var unlockedAt: Date?
    var isClaimed: Bool
    var claimedAt: Date?

    init(
        id: AchievementID,
        isUnlocked: Bool = false,
        unlockedAt: Date? = nil,
        isClaimed: Bool = false,
        claimedAt: Date? = nil
    ) {
        self.id = id
        self.isUnlocked = isUnlocked
        self.unlockedAt = unlockedAt
        self.isClaimed = isClaimed
        self.claimedAt = claimedAt
    }
}

// MARK: - Popups

enum ProgressPopup: Equatable {
    case dailyLogin(coins: Int, day: Int, maxDays: Int)
    case dailyTask(coins: Int, title: String, subtitle: String)
    case levelRewards(totalCoins: Int, levelCoins: Int, daily5BonusCoins: Int, levelsCompletedToday: Int)
    case achievementUnlocked(id: AchievementID) // только уведомление об Unlock

    var coins: Int {
        switch self {
        case .dailyLogin(let coins, _, _): return coins
        case .dailyTask(let coins, _, _): return coins
        case .levelRewards(let totalCoins, _, _, _): return totalCoins
        case .achievementUnlocked: return 0
        }
    }
}

// MARK: - Levels (UI)

enum LevelCellState: Hashable {
    case completed
    case playable
    case locked
}

// MARK: - Persistence model

private struct GameProgressData: Codable {
    var coins: Int

    var completedLevels: Set<Int>
    var optimalCompletedLevels: Set<Int>

    var selectedLevel: Int

    var dailyCompletedLevelsCount: Int
    var lastDailyResetDayKey: String

    var loginStreak: Int
    var lastLoginDayKey: String

    var lastDailyLoginClaimedDayKey: String
    var lastDailyTaskClaimedDayKey: String

    var achievements: [AchievementState]
    var selectedAchievement: AchievementID?

    static func fresh() -> GameProgressData {
        GameProgressData(
            coins: 0,
            completedLevels: [],
            optimalCompletedLevels: [],
            selectedLevel: 1,
            dailyCompletedLevelsCount: 0,
            lastDailyResetDayKey: "",
            loginStreak: 0,
            lastLoginDayKey: "",
            lastDailyLoginClaimedDayKey: "",
            lastDailyTaskClaimedDayKey: "",
            achievements: AchievementID.allCases.map { AchievementState(id: $0) },
            selectedAchievement: nil
        )
    }
}

// MARK: - Progress Store

@MainActor
final class ProgressStore: ObservableObject {

    // MARK: Constants

    let totalLevels: Int = 12

    private let dailyFiveLevelsBonusCoins: Int = 10

    private let dailyLoginCoins: Int = 10
    private let dailyLoginMaxDays: Int = 7

    private let dailyTaskCoins: Int = 10

    // MARK: Published (UI)

    @Published private(set) var coins: Int = 0
    @Published private(set) var completedLevels: Set<Int> = []
    @Published private(set) var optimalCompletedLevels: Set<Int> = []
    @Published private(set) var achievements: [AchievementState] = AchievementID.allCases.map { AchievementState(id: $0) }

    @Published private(set) var dailyCompletedLevelsCount: Int = 0

    @Published var selectedAchievement: AchievementID? = nil {
        didSet {
            data.selectedAchievement = selectedAchievement
            save()
        }
    }

    @Published var selectedLevel: Int = 1 {
        didSet {
            let normalized = normalizeSelectedLevel(selectedLevel)
            guard normalized == selectedLevel else {
                selectedLevel = normalized
                return
            }
            data.selectedLevel = selectedLevel
            save()
        }
    }

    @Published private(set) var activePopup: ProgressPopup? = nil
    @Published var shouldStartGame: Bool = false

    // MARK: Storage

    private var data: GameProgressData
    private let ud: UserDefaults
    private let storageKey: String
    private let calendar: Calendar
    private var popupQueue: [ProgressPopup] = []

    // MARK: Init

    init(
        userDefaults: UserDefaults = .standard,
        storageKey: String = "mania.progress.v1",
        calendar: Calendar = .current
    ) {
        self.ud = userDefaults
        self.storageKey = storageKey
        self.calendar = calendar

        if
            let raw = userDefaults.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode(GameProgressData.self, from: raw)
        {
            self.data = decoded
        } else {
            self.data = .fresh()
        }

        applyPublished(from: data)
    }

    // MARK: - Game start

    func canPlaySelectedLevel() -> Bool {
        isLevelUnlocked(selectedLevel)
    }

    func startSelectedLevel() {
        guard canPlaySelectedLevel() else { return }
        shouldStartGame = true
    }

    func resetStartFlag() {
        shouldStartGame = false
    }

    // MARK: - App Launch

    func onAppLaunch(now: Date = Date()) {
        popupQueue.removeAll()
        activePopup = nil

        resetDailyIfNeeded(now: now)
        updateLoginStreakIfNeeded(now: now)

        enqueueDailyLoginIfNeeded(now: now)
        enqueueDailyTaskIfNeeded(now: now)

        checkAchievements(now: now)

        data.selectedLevel = normalizeSelectedLevel(data.selectedLevel)

        save()
        applyPublished(from: data)
        flushPopupQueueIfNeeded()
    }

    // MARK: - Levels

    func isLevelUnlocked(_ levelIndex: Int) -> Bool {
        if levelIndex <= 1 { return true }
        return data.completedLevels.contains(levelIndex - 1)
    }

    func maxUnlockedLevel(maxLevel: Int? = nil) -> Int {
        let maxL = maxLevel ?? totalLevels
        for lvl in stride(from: maxL, through: 1, by: -1) {
            if isLevelUnlocked(lvl) { return lvl }
        }
        return 1
    }

    func levelCellState(for levelIndex: Int) -> LevelCellState {
        if data.completedLevels.contains(levelIndex) { return .completed }
        if isLevelUnlocked(levelIndex) { return .playable }
        return .locked
    }

    func selectLevel(_ levelIndex: Int) {
        selectedLevel = levelIndex
    }

    // MARK: - Win flow

    func onLevelWin(levelIndex: Int, result: LevelResult, now: Date = Date()) {
        guard result.didWin else { return }

        resetDailyIfNeeded(now: now)

        data.completedLevels.insert(levelIndex)

        if let optimal = result.optimalCrossings, optimal == result.playerCrossings {
            data.optimalCompletedLevels.insert(levelIndex)
        }

        let levelCoins = result.coins
        data.coins += levelCoins

        data.dailyCompletedLevelsCount += 1

        let daily5BonusCoins: Int = (data.dailyCompletedLevelsCount == 5) ? dailyFiveLevelsBonusCoins : 0
        if daily5BonusCoins > 0 {
            data.coins += daily5BonusCoins
        }

        checkAchievements(now: now)

        let maxUnlocked = maxUnlockedLevel()
        if data.selectedLevel < maxUnlocked {
            data.selectedLevel = maxUnlocked
        }

        save()
        applyPublished(from: data)
    }

    func onWinIfPossible(levelIndex: Int, levelResult: LevelResult?, now: Date = Date()) {
        guard let levelResult, levelResult.didWin else { return }
        onLevelWin(levelIndex: levelIndex, result: levelResult, now: now)
    }

    // MARK: - Daily popups enqueue

    private func enqueueDailyLoginIfNeeded(now: Date) {
        let today = dayKey(for: now)
        if data.lastDailyLoginClaimedDayKey == today { return }
        guard (1...dailyLoginMaxDays).contains(data.loginStreak) else { return }
        enqueuePopup(.dailyLogin(coins: dailyLoginCoins, day: data.loginStreak, maxDays: dailyLoginMaxDays))
    }

    private func enqueueDailyTaskIfNeeded(now: Date) {
        let today = dayKey(for: now)
        if data.lastDailyTaskClaimedDayKey == today { return }

        let title = "Complete 1 level"
        let subtitle = "Complete 5 levels"

        enqueuePopup(.dailyTask(coins: dailyTaskCoins, title: title, subtitle: subtitle))
    }

    // MARK: - Claim active popup

    func claimActivePopup(now: Date = Date()) {
        guard let popup = activePopup else { return }
        let today = dayKey(for: now)

        switch popup {
        case .dailyLogin(let coins, _, _):
            data.coins += coins
            data.lastDailyLoginClaimedDayKey = today
            save()
            applyPublished(from: data)
            consumePopup()

        case .dailyTask(let coins, _, _):
            data.coins += coins
            data.lastDailyTaskClaimedDayKey = today
            save()
            applyPublished(from: data)
            consumePopup()

        default:
            consumePopup()
        }
    }

    var canClaimDailyReward: Bool {
        if case .dailyLogin = activePopup { return true }
        return false
    }

    func claimDailyReward(now: Date = Date()) {
        guard canClaimDailyReward else { return }
        claimActivePopup(now: now)
    }

    // MARK: - Popup queue

    private func enqueuePopup(_ popup: ProgressPopup) {
        popupQueue.append(popup)
    }

    func consumePopup() {
        guard !popupQueue.isEmpty else {
            activePopup = nil
            return
        }
        popupQueue.removeFirst()
        activePopup = popupQueue.first
    }

    private func flushPopupQueueIfNeeded() {
        if activePopup == nil {
            activePopup = popupQueue.first
        }
    }

    func closeDailyHub() {
        activePopup = nil
        popupQueue.removeAll()
    }

    // MARK: - Coins API

    func addCoins(_ amount: Int) {
        guard amount > 0 else { return }
        data.coins += amount
        save()
        applyPublished(from: data)
    }

    @discardableResult
    func spendCoins(_ amount: Int) -> Bool {
        guard amount > 0 else { return false }
        guard data.coins >= amount else { return false }
        data.coins -= amount
        save()
        applyPublished(from: data)
        return true
    }

    // MARK: - Reset

    func resetAllProgress() {
        data = .fresh()
        popupQueue.removeAll()
        activePopup = nil
        ud.removeObject(forKey: storageKey)
        applyPublished(from: data)
    }

    // MARK: - Achievements API (для AchievementsView)

    enum AchievementCellState: Hashable {
        case locked
        case earnedNotClaimed
        case claimed
    }

    func ensureSelectedAchievementIfNeeded() {
        if selectedAchievement != nil { return }

        if let first = AchievementID.allCases.first(where: { achievementCellState(for: $0) == .earnedNotClaimed }) {
            selectedAchievement = first
        } else {
            selectedAchievement = AchievementID.allCases.first
        }
    }

    func achievement(_ id: AchievementID) -> AchievementState {
        data.achievements.first(where: { $0.id == id }) ?? AchievementState(id: id)
    }

    func achievementCellState(for id: AchievementID) -> AchievementCellState {
        let st = achievement(id)
        if st.isClaimed { return .claimed }
        if st.isUnlocked { return .earnedNotClaimed }
        return .locked
    }

    func canClaimSelectedAchievement() -> Bool {
        guard let id = selectedAchievement else { return false }
        return achievementCellState(for: id) == .earnedNotClaimed
    }

    func claimSelectedAchievement(now: Date = Date()) {
        guard let id = selectedAchievement else { return }
        claimAchievement(id, now: now)
    }

    func claimAchievement(_ id: AchievementID, now: Date = Date()) {
        guard let idx = data.achievements.firstIndex(where: { $0.id == id }) else { return }
        guard data.achievements[idx].isUnlocked else { return }
        guard !data.achievements[idx].isClaimed else { return }

        data.achievements[idx].isClaimed = true
        data.achievements[idx].claimedAt = now

        data.coins += id.coinReward

        save()
        applyPublished(from: data)
    }

    // MARK: - Achievements unlocking rules

    private func checkAchievements(now: Date) {
        if data.completedLevels.contains(4) {
            unlockAchievementIfNeeded(.boat, now: now)
        }

        if data.loginStreak >= 5 {
            unlockAchievementIfNeeded(.calendarFirst, now: now)
        }

        if data.optimalCompletedLevels.count >= 5 {
            unlockAchievementIfNeeded(.clock, now: now)
        }

        if data.completedLevels.count >= totalLevels, data.optimalCompletedLevels.count >= 8 {
            unlockAchievementIfNeeded(.threeStars, now: now)
        }
    }

    private func unlockAchievementIfNeeded(_ id: AchievementID, now: Date) {
        guard let idx = data.achievements.firstIndex(where: { $0.id == id }) else { return }
        if data.achievements[idx].isUnlocked { return }

        data.achievements[idx].isUnlocked = true
        data.achievements[idx].unlockedAt = now

        enqueuePopup(.achievementUnlocked(id: id))
    }

    // MARK: - Persistence

    private func save() {
        if let encoded = try? JSONEncoder().encode(data) {
            ud.set(encoded, forKey: storageKey)
        }
    }

    private func applyPublished(from data: GameProgressData) {
        coins = data.coins
        completedLevels = data.completedLevels
        optimalCompletedLevels = data.optimalCompletedLevels
        achievements = data.achievements
        dailyCompletedLevelsCount = data.dailyCompletedLevelsCount

        let normalized = normalizeSelectedLevel(data.selectedLevel)
        if selectedLevel != normalized {
            selectedLevel = normalized
        }

        if selectedAchievement != data.selectedAchievement {
            selectedAchievement = data.selectedAchievement
        }
    }

    // MARK: - Dates / daily

    private func dayKey(for date: Date) -> String {
        let comp = calendar.dateComponents([.year, .month, .day], from: date)
        let y = comp.year ?? 0
        let m = comp.month ?? 0
        let d = comp.day ?? 0
        return "\(y)-\(m)-\(d)"
    }

    private func resetDailyIfNeeded(now: Date) {
        let today = dayKey(for: now)
        if data.lastDailyResetDayKey != today {
            data.lastDailyResetDayKey = today
            data.dailyCompletedLevelsCount = 0
        }
    }

    private func updateLoginStreakIfNeeded(now: Date) {
        let today = dayKey(for: now)

        if data.lastLoginDayKey.isEmpty {
            data.lastLoginDayKey = today
            data.loginStreak = 1
            return
        }

        if data.lastLoginDayKey == today {
            return
        }

        guard let yesterdayDate = calendar.date(byAdding: .day, value: -1, to: now) else {
            data.lastLoginDayKey = today
            data.loginStreak = 1
            return
        }

        let yesterday = dayKey(for: yesterdayDate)

        if data.lastLoginDayKey == yesterday {
            data.loginStreak += 1
        } else {
            data.loginStreak = 1
        }

        data.lastLoginDayKey = today
    }

    // MARK: - Selected level normalization

    private func normalizeSelectedLevel(_ value: Int) -> Int {
        var v = value
        if v < 1 { v = 1 }
        if v > totalLevels { v = totalLevels }

        let maxUnlocked = maxUnlockedLevel()
        if v > maxUnlocked { v = maxUnlocked }

        return v
    }
    
    func dropNonHubPopups() {
        popupQueue = popupQueue.filter {
            switch $0 {
            case .dailyLogin, .dailyTask:
                return true
            default:
                return false
            }
        }
        activePopup = popupQueue.first
    }
}
