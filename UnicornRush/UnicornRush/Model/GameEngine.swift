import Foundation
import Combine
import QuartzCore

enum BuyMode: String, CaseIterable, Identifiable {
    case one = "x1", ten = "x10", hundred = "x100", max = "MAX"
    var id: String { rawValue }
}

/// A "you got paid" popup (offline earnings, daily streak). Queued so two never collide.
struct RewardPopup: Identifiable {
    let id = UUID()
    let emoji: String
    let title: String
    let subtitle: String
    let amount: Double
    let footer: String
}

enum Celebration: Identifiable {
    case roundClosed(FundingRound)
    case levelUp(Int)
    case achievement(AchievementDef)
    case exit(starsGained: Int)

    var id: String {
        switch self {
        case .roundClosed(let r): return "round-\(r.id)"
        case .levelUp(let l): return "level-\(l)"
        case .achievement(let a): return "ach-\(a.id)"
        case .exit(let s): return "exit-\(s)"
        }
    }
}

enum UnicornReward {
    case viral
    case cash(Double)
}

final class GameEngine: ObservableObject {
    @Published var state: GameState
    @Published var buyMode: BuyMode = .one
    @Published var viralBoostUntil: Date?
    @Published var unicornPosition: CGPoint?
    @Published var rewardPopup: RewardPopup?
    @Published var celebrations: [Celebration] = []
    @Published var toast: String?
    /// Bumped on every payout so rows can pop a "+$" label.
    @Published var payoutPulse: [Int] = Array(repeating: 0, count: GameData.stations.count)

    private var timer: Timer?
    private var lastTick = CACurrentMediaTime()
    private var saveClock: Double = 0
    private var achievementClock: Double = 0
    private var nextUnicornAt = Date().addingTimeInterval(40)
    private var unicornExpiresAt: Date?
    private var pendingRewards: [RewardPopup] = []
    private static let saveKey = "unicornrush.save.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.saveKey),
           let saved = try? JSONDecoder().decode(GameState.self, from: data) {
            state = saved
        } else {
            state = GameState()
        }
    }

    // MARK: - Lifecycle

    func start() {
        guard timer == nil else { return }
        lastTick = CACurrentMediaTime()
        let t = Timer(timeInterval: 1.0 / 20.0, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// Called whenever the app comes to the foreground.
    func becameActive() {
        applyOfflineEarnings()
        checkDailyStreak()
        start()
        NotificationService.shared.cancelAll()
    }

    /// Called when the app goes to the background.
    func resignedActive() {
        save()
        stop()
        NotificationService.shared.scheduleComebacks(offlinePerSecond: offlineIncomePerSecond,
                                                     streak: state.streakDays,
                                                     company: state.companyName)
    }

    func save() {
        state.lastSaved = Date()
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: Self.saveKey)
        }
    }

    // MARK: - Derived numbers

    func skillLevel(_ id: SkillID) -> Int { state.skills[id.rawValue] ?? 0 }

    var isViral: Bool { (viralBoostUntil ?? .distantPast) > Date() }

    var permanentMultiplier: Double {
        let leadership = 1 + 0.10 * Double(skillLevel(.leadership))
        let rounds = pow(2, Double(state.roundsClosed))
        let stars = 1 + 0.02 * Double(state.stars)
        return leadership * rounds * stars
    }

    var globalMultiplier: Double { permanentMultiplier * (isViral ? 7 : 1) }

    var valuation: Double { state.runEarnings * GameData.valuationMultiple }

    var costDiscount: Double { 1 - 0.03 * Double(skillLevel(.negotiation)) }

    func cycleTime(_ i: Int) -> Double {
        var t = GameData.stations[i].baseCycle
        let n = state.stations[i].owned
        for m in GameData.speedMilestones where n >= m { t /= 2 }
        return t
    }

    func revenuePerCycle(_ i: Int, multiplier: Double? = nil) -> Double {
        let n = state.stations[i].owned
        var mult = 1.0
        if n >= 500 { mult = pow(2, Double((n - 400) / 100)) }
        return GameData.stations[i].baseRevenue * Double(n) * mult * (multiplier ?? globalMultiplier)
    }

    /// Income per second from automated departments (what the HUD shows).
    var incomePerSecond: Double {
        var total = 0.0
        for i in state.stations.indices where state.stations[i].owned > 0 && state.stations[i].hasManager {
            total += revenuePerCycle(i) / cycleTime(i)
        }
        return total
    }

    var offlineIncomePerSecond: Double {
        var total = 0.0
        for i in state.stations.indices where state.stations[i].owned > 0 && state.stations[i].hasManager {
            total += revenuePerCycle(i, multiplier: permanentMultiplier) / cycleTime(i)
        }
        return total * offlineRate
    }

    var offlineRate: Double { 0.5 + 0.05 * Double(skillLevel(.vision)) }
    var offlineCapSeconds: Double { (2 + Double(skillLevel(.vision))) * 3_600 }

    /// Next milestone that halves this department's cycle time, if any.
    func nextMilestone(_ i: Int) -> Int? {
        let n = state.stations[i].owned
        if let m = GameData.speedMilestones.first(where: { $0 > n }) { return m }
        return ((n / 100) + 1) * 100
    }

    func isUnlocked(_ i: Int) -> Bool { i == 0 || state.stations[i - 1].owned > 0 }

    // MARK: - Buying

    func purchase(for i: Int) -> (count: Int, cost: Double) {
        let def = GameData.stations[i]
        let owned = Double(state.stations[i].owned)
        let g = def.costGrowth
        let first = def.baseCost * pow(g, owned) * costDiscount
        func cost(_ k: Int) -> Double { first * (pow(g, Double(k)) - 1) / (g - 1) }
        switch buyMode {
        case .one: return (1, cost(1))
        case .ten: return (10, cost(10))
        case .hundred: return (100, cost(100))
        case .max:
            let k = Int(floor(log(state.cash * (g - 1) / first + 1) / log(g)))
            let count = max(k, 1)
            return (count, cost(count))
        }
    }

    func canAfford(_ i: Int) -> Bool { purchase(for: i).cost <= state.cash && isUnlocked(i) }

    func buy(_ i: Int) {
        let p = purchase(for: i)
        guard isUnlocked(i), p.cost <= state.cash else { Haptics.error(); return }
        let before = state.stations[i].owned
        state.cash -= p.cost
        state.stations[i].owned += p.count
        addXP(Double(p.count) * 0.5)
        Haptics.light()
        if before == 0 {
            toast = "\(GameData.stations[i].emoji) \(GameData.stations[i].name) is open for business!"
        } else if let crossed = GameData.speedMilestones.first(where: { before < $0 && state.stations[i].owned >= $0 }) {
            toast = "⚡️ \(GameData.stations[i].name) hit \(crossed) — 2x speed!"
            Haptics.success()
        }
    }

    func hireManager(_ i: Int) {
        let cost = GameData.stations[i].managerCost * costDiscount
        guard !state.stations[i].hasManager, state.stations[i].owned > 0, state.cash >= cost else {
            Haptics.error(); return
        }
        state.cash -= cost
        state.stations[i].hasManager = true
        state.stations[i].running = true
        addXP(20)
        Haptics.success()
        toast = "🤝 \(GameData.stations[i].managerName) now runs \(GameData.stations[i].name)"
    }

    func managerCost(_ i: Int) -> Double { GameData.stations[i].managerCost * costDiscount }

    // MARK: - Tapping

    func tapStation(_ i: Int) {
        guard state.stations[i].owned > 0 else { return }
        state.totalTaps += 1
        addXP(0.25)
        if !state.stations[i].running {
            state.stations[i].running = true
            state.stations[i].progress = 0
        }
        // Hustle: every tap pushes the cycle forward.
        state.stations[i].progress += 0.06 * (1 + 0.5 * Double(skillLevel(.hustle)))
        Haptics.tap()
    }

    // MARK: - Simulation

    private func tick() {
        let now = CACurrentMediaTime()
        let dt = min(now - lastTick, 1.0)
        lastTick = now
        advance(by: dt)

        if let expires = unicornExpiresAt, Date() > expires {
            unicornPosition = nil
            unicornExpiresAt = nil
        }
        if unicornPosition == nil, Date() > nextUnicornAt, state.hasOnboarded {
            unicornPosition = CGPoint(x: Double.random(in: 0.15...0.85), y: Double.random(in: 0.25...0.75))
            unicornExpiresAt = Date().addingTimeInterval(8)
            nextUnicornAt = Date().addingTimeInterval(Double.random(in: 60...150))
        }
        if let until = viralBoostUntil, until < Date() { viralBoostUntil = nil }

        saveClock += dt
        if saveClock > 5 { saveClock = 0; save() }
        achievementClock += dt
        if achievementClock > 1 { achievementClock = 0; checkAchievements() }
    }

    private func advance(by dt: Double) {
        var earned = 0.0
        for i in state.stations.indices {
            var s = state.stations[i]
            guard s.owned > 0, s.running || s.hasManager else { continue }
            let cycle = cycleTime(i)
            let revenue = revenuePerCycle(i)
            if s.hasManager && cycle < 0.15 {
                // Too fast to animate per cycle: treat as a continuous stream.
                earned += revenue * dt / cycle
                s.progress = 1
            } else {
                s.progress += dt / cycle
                var paid = false
                while s.progress >= 1 {
                    earned += revenue
                    paid = true
                    if s.hasManager {
                        s.progress -= 1
                    } else {
                        s.progress = 0
                        s.running = false
                    }
                }
                if paid { payoutPulse[i] &+= 1 }
            }
            state.stations[i] = s
        }
        if earned > 0 { earn(earned) }
    }

    private func earn(_ amount: Double) {
        state.cash += amount
        state.runEarnings += amount
        state.lifetimeEarnings += amount
        state.bestValuation = max(state.bestValuation, valuation)
    }

    // MARK: - Funding rounds (levels)

    var nextRound: FundingRound? {
        state.roundsClosed < GameData.rounds.count ? GameData.rounds[state.roundsClosed] : nil
    }

    var currentRoundName: String {
        state.roundsClosed == 0 ? "Garage" : GameData.rounds[state.roundsClosed - 1].name
    }

    var roundProgress: Double {
        guard let r = nextRound else { return 1 }
        let previous = state.roundsClosed == 0 ? 0 : GameData.rounds[state.roundsClosed - 1].valuationTarget
        // Log scale so the bar always visibly moves.
        let lo = log10(max(previous, 1)), hi = log10(r.valuationTarget), v = log10(max(valuation, 1))
        return min(max((v - lo) / (hi - lo), 0), 1)
    }

    var canPitch: Bool {
        guard let r = nextRound else { return false }
        return valuation >= r.valuationTarget && Date() >= state.pitchCooldownUntil
    }

    var pitchCooldownRemaining: Double { max(0, state.pitchCooldownUntil.timeIntervalSinceNow) }

    /// Pitch difficulty: sweet-spot width (fraction of the meter) and needle speed.
    var pitchZoneWidth: Double { max(0.10, 0.30 - 0.018 * Double(state.roundsClosed)) + 0.012 * Double(skillLevel(.charisma)) }
    var pitchNeedleSpeed: Double { 2.2 + 0.25 * Double(state.roundsClosed) }
    var pitchMissesAllowed: Int { skillLevel(.charisma) >= 5 ? 2 : 1 }

    func finishPitch(success: Bool) {
        guard let round = nextRound else { return }
        if success {
            state.roundsClosed += 1
            addXP(40 * Double(round.id + 1))
            Haptics.success()
            celebrations.append(.roundClosed(round))
            GameCenterService.shared.submit(valuation: state.bestValuation)
            if round.id == 0 { NotificationService.shared.requestAuthorization() }
        } else {
            state.pitchCooldownUntil = Date().addingTimeInterval(20)
            Haptics.error()
            toast = "😬 They passed. Polish the deck and try again in 20s."
        }
        save()
    }

    // MARK: - Exit / prestige

    var canExit: Bool { state.roundsClosed > GameData.ipoRoundIndex }

    var starsOnExit: Int { Int(floor(10 * sqrt(state.runEarnings / 1e11))) }

    func exitCompany() {
        guard canExit else { return }
        let gained = starsOnExit
        state.stars += gained
        state.exits += 1
        state.cash = 0
        state.runEarnings = 0
        state.stations = GameState.freshStations()
        state.roundsClosed = 0
        viralBoostUntil = nil
        addXP(250)
        celebrations.append(.exit(starsGained: gained))
        Haptics.success()
        save()
    }

    // MARK: - Founder XP & skills

    func xpNeeded(for level: Int) -> Double { 25 * pow(Double(level), 1.6) }

    func addXP(_ amount: Double) {
        state.founderXP += amount
        while state.founderXP >= xpNeeded(for: state.founderLevel) {
            state.founderXP -= xpNeeded(for: state.founderLevel)
            state.founderLevel += 1
            state.skillPoints += 1
            celebrations.append(.levelUp(state.founderLevel))
        }
    }

    var founderTitle: String {
        GameData.founderTitles.last(where: { $0.level <= state.founderLevel })?.title ?? "Founder"
    }

    func upgradeSkill(_ id: SkillID) {
        guard state.skillPoints > 0, skillLevel(id) < GameData.maxSkillLevel else { Haptics.error(); return }
        state.skillPoints -= 1
        state.skills[id.rawValue] = skillLevel(id) + 1
        Haptics.success()
    }

    // MARK: - Golden unicorn

    @discardableResult
    func catchUnicorn() -> UnicornReward {
        unicornPosition = nil
        unicornExpiresAt = nil
        state.unicornsCaught += 1
        addXP(10)
        Haptics.success()
        if Bool.random() || incomePerSecond == 0 {
            let bonus = max(incomePerSecond * 900, 50 * permanentMultiplier)
            earn(bonus)
            toast = "✨ Angel investor! +\(Format.money(bonus))"
            return .cash(bonus)
        } else {
            viralBoostUntil = Date().addingTimeInterval(30)
            toast = "🚀 You went VIRAL! 7x revenue for 30s"
            return .viral
        }
    }

    // MARK: - Retention

    private func applyOfflineEarnings() {
        let elapsed = Date().timeIntervalSince(state.lastSaved)
        guard state.hasOnboarded, elapsed > 60 else { return }
        let seconds = min(elapsed, offlineCapSeconds)
        let amount = offlineIncomePerSecond * seconds
        guard amount > 0 else { return }
        earn(amount)
        enqueueReward(RewardPopup(emoji: "😴", title: "While you were away…",
                                  subtitle: "Your team worked \(Format.duration(seconds)) and earned",
                                  amount: amount,
                                  footer: "Level up Vision to earn more, for longer."))
        state.lastSaved = Date()
    }

    private func checkDailyStreak() {
        guard state.hasOnboarded else { return }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let today = f.string(from: Date())
        guard state.lastLoginDay != today else { return }
        let yesterday = f.string(from: Date().addingTimeInterval(-86_400))
        state.streakDays = state.lastLoginDay == yesterday ? state.streakDays + 1 : 1
        state.lastLoginDay = today
        let minutes = 5.0 + 5.0 * Double(min(state.streakDays, 30))
        let cash = max(incomePerSecond * 60 * minutes, 100 * Double(state.streakDays))
        let xp = 20.0 * Double(min(state.streakDays, 30))
        earn(cash)
        addXP(xp)
        enqueueReward(RewardPopup(emoji: "🔥", title: "Day \(state.streakDays) streak!",
                                  subtitle: "Showing up is the job. Today's bonus:",
                                  amount: cash,
                                  footer: "+\(Int(xp)) XP · Come back tomorrow to keep the streak alive"))
        save()
    }

    private func enqueueReward(_ reward: RewardPopup) {
        if rewardPopup == nil { rewardPopup = reward } else { pendingRewards.append(reward) }
    }

    /// Called by the sheet's onDismiss; shows the next queued popup, if any.
    func rewardDismissed() {
        rewardPopup = nil
        guard !pendingRewards.isEmpty else { return }
        let next = pendingRewards.removeFirst()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in self?.rewardPopup = next }
    }

    private func checkAchievements() {
        for a in GameData.achievements where !state.unlockedAchievements.contains(a.id) && a.isMet(state) {
            state.unlockedAchievements.append(a.id)
            addXP(a.xp)
            celebrations.append(.achievement(a))
        }
    }

    // MARK: - Onboarding

    func foundCompany(name: String, logo: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        state.companyName = trimmed.isEmpty ? "Stealth Startup" : String(trimmed.prefix(24))
        state.companyLogo = logo
        state.hasOnboarded = true
        nextUnicornAt = Date().addingTimeInterval(45)
        // Day one counts toward the streak, but no popup over the very first screen.
        checkDailyStreak()
        rewardPopup = nil
        pendingRewards.removeAll()
        save()
    }

    func popCelebration() {
        if !celebrations.isEmpty { celebrations.removeFirst() }
    }
}
