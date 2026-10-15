import Foundation

// MARK: - Static content
//
// All balancing numbers live here. Pacing was tuned with an offline greedy-player
// simulation: Pre-Seed in ~2 min, Series A in ~10 min, Series C in ~40 min and the
// first IPO (prestige) after ~2 h of active play. Every later run is faster thanks
// to Reputation stars, which is what makes "one more run" so sticky.

struct StationDef: Identifiable {
    let id: Int
    let name: String
    let emoji: String
    let tagline: String
    let baseCost: Double
    let costGrowth: Double
    let baseRevenue: Double
    let baseCycle: Double
    let managerCost: Double
    let managerName: String
}

struct FundingRound: Identifiable {
    let id: Int
    let name: String
    let emoji: String
    /// Company valuation needed before investors take the pitch meeting.
    let valuationTarget: Double
    let investorLine: String
}

enum SkillID: String, Codable, CaseIterable, Identifiable {
    case hustle, leadership, charisma, negotiation, vision
    var id: String { rawValue }
}

struct SkillDef: Identifiable {
    let id: SkillID
    let name: String
    let emoji: String
    let perLevel: String
    let maxLevel: Int
}

struct AchievementDef: Identifiable {
    let id: String
    let emoji: String
    let title: String
    let detail: String
    let xp: Double
    let isMet: (GameState) -> Bool
}

enum GameData {
    /// Valuation shown to the player = earnings this run × this multiple (a "revenue multiple").
    static let valuationMultiple: Double = 20
    /// Round index (0-based) that is the IPO; closing it unlocks the Exit / prestige.
    static let ipoRoundIndex = 5
    static let speedMilestones = [25, 50, 100, 200, 300, 400]
    static let maxSkillLevel = 10

    static let stations: [StationDef] = [
        StationDef(id: 0, name: "Coffee Bar", emoji: "☕️", tagline: "Fuel for the founders",
                   baseCost: 4, costGrowth: 1.07, baseRevenue: 1, baseCycle: 0.6,
                   managerCost: 1_000, managerName: "Barista Bea"),
        StationDef(id: 1, name: "Code Ship", emoji: "💻", tagline: "Ship features, not excuses",
                   baseCost: 60, costGrowth: 1.15, baseRevenue: 60, baseCycle: 3,
                   managerCost: 15_000, managerName: "10x Dev Dex"),
        StationDef(id: 2, name: "Design Studio", emoji: "🎨", tagline: "Pixels people pay for",
                   baseCost: 720, costGrowth: 1.14, baseRevenue: 540, baseCycle: 6,
                   managerCost: 100_000, managerName: "Figma Fiona"),
        StationDef(id: 3, name: "Growth Lab", emoji: "📣", tagline: "Go viral on purpose",
                   baseCost: 8_640, costGrowth: 1.13, baseRevenue: 4_320, baseCycle: 12,
                   managerCost: 500_000, managerName: "Growth Hacker Gus"),
        StationDef(id: 4, name: "Sales Floor", emoji: "🤝", tagline: "Always be closing",
                   baseCost: 103_680, costGrowth: 1.12, baseRevenue: 51_840, baseCycle: 24,
                   managerCost: 1_200_000, managerName: "Closer Cleo"),
        StationDef(id: 5, name: "Cloud Infra", emoji: "☁️", tagline: "Five nines, zero sleep",
                   baseCost: 1_244_160, costGrowth: 1.11, baseRevenue: 622_080, baseCycle: 96,
                   managerCost: 10_000_000, managerName: "SRE Sam"),
        StationDef(id: 6, name: "AI Lab", emoji: "🤖", tagline: "Now with more AI",
                   baseCost: 14_929_920, costGrowth: 1.10, baseRevenue: 7_464_960, baseCycle: 384,
                   managerCost: 111_111_111, managerName: "Dr. Neural"),
        StationDef(id: 7, name: "Global HQ", emoji: "🌍", tagline: "Offices in every timezone",
                   baseCost: 179_159_040, costGrowth: 1.09, baseRevenue: 89_579_520, baseCycle: 1_536,
                   managerCost: 555_555_555, managerName: "COO Kai"),
        StationDef(id: 8, name: "Space Division", emoji: "🚀", tagline: "Disrupting gravity",
                   baseCost: 2_149_908_480, costGrowth: 1.08, baseRevenue: 1_074_954_240, baseCycle: 6_144,
                   managerCost: 10_000_000_000, managerName: "Astro Ava"),
        StationDef(id: 9, name: "Moonshot Factory", emoji: "🦄", tagline: "Impossible is a roadmap item",
                   baseCost: 25_798_901_760, costGrowth: 1.07, baseRevenue: 29_799_514_880, baseCycle: 36_864,
                   managerCost: 100_000_000_000, managerName: "The Visionary"),
    ]

    static let rounds: [FundingRound] = [
        FundingRound(id: 0, name: "Pre-Seed", emoji: "🌱", valuationTarget: 1e5,
                     investorLine: "\"Cute garage. Show me traction.\""),
        FundingRound(id: 1, name: "Seed", emoji: "🌿", valuationTarget: 1e7,
                     investorLine: "\"I like the team. Do you have users?\""),
        FundingRound(id: 2, name: "Series A", emoji: "🦄", valuationTarget: 1e9,
                     investorLine: "\"A unicorn? Prove it's not a horse with a party hat.\""),
        FundingRound(id: 3, name: "Series B", emoji: "📈", valuationTarget: 6e10,
                     investorLine: "\"Unit economics. Go.\""),
        FundingRound(id: 4, name: "Series C", emoji: "💎", valuationTarget: 2e12,
                     investorLine: "\"We're going to need a bigger term sheet.\""),
        FundingRound(id: 5, name: "IPO", emoji: "🔔", valuationTarget: 1e14,
                     investorLine: "\"The whole market is watching. Ring the bell.\""),
        FundingRound(id: 6, name: "Decacorn", emoji: "🐉", valuationTarget: 4e15,
                     investorLine: "\"Sovereign funds are calling.\""),
        FundingRound(id: 7, name: "Big Tech", emoji: "🏙️", valuationTarget: 2e17,
                     investorLine: "\"Congress wants a word.\""),
        FundingRound(id: 8, name: "Trillion Club", emoji: "👑", valuationTarget: 1e19,
                     investorLine: "\"Name a planet after the company?\""),
        FundingRound(id: 9, name: "Mars Colony", emoji: "🪐", valuationTarget: 6e20,
                     investorLine: "\"Earth is a solved market.\""),
        FundingRound(id: 10, name: "Galactic Empire", emoji: "🌌", valuationTarget: 4e22,
                     investorLine: "\"The final pitch. Make history.\""),
    ]

    static let skills: [SkillDef] = [
        SkillDef(id: .hustle, name: "Hustle", emoji: "⚡️", perLevel: "+50% tap speed-up", maxLevel: maxSkillLevel),
        SkillDef(id: .leadership, name: "Leadership", emoji: "🧭", perLevel: "+10% all revenue", maxLevel: maxSkillLevel),
        SkillDef(id: .charisma, name: "Charisma", emoji: "🎤", perLevel: "Bigger pitch sweet spot", maxLevel: maxSkillLevel),
        SkillDef(id: .negotiation, name: "Negotiation", emoji: "🤑", perLevel: "−3% upgrade costs", maxLevel: maxSkillLevel),
        SkillDef(id: .vision, name: "Vision", emoji: "🔮", perLevel: "+1h & +5% offline earnings", maxLevel: maxSkillLevel),
    ]

    /// Founder titles are the "pride" ladder shown on the share card.
    static let founderTitles: [(level: Int, title: String)] = [
        (1, "Wantrepreneur"), (3, "Side Hustler"), (6, "Builder"), (10, "Operator"),
        (15, "Rainmaker"), (20, "Visionary"), (30, "Titan"), (40, "Legend"), (50, "GOAT"),
    ]

    static let achievements: [AchievementDef] = [
        AchievementDef(id: "first_hire", emoji: "👋", title: "First Hire", detail: "Hire your first manager", xp: 25) {
            $0.stations.contains { $0.hasManager }
        },
        AchievementDef(id: "coffee_100", emoji: "☕️", title: "Caffeine Economy", detail: "Own 100 Coffee Bars", xp: 50) {
            $0.stations[0].owned >= 100
        },
        AchievementDef(id: "code_100", emoji: "💻", title: "Ship It", detail: "Own 100 Code Ships", xp: 75) {
            $0.stations[1].owned >= 100
        },
        AchievementDef(id: "all_depts", emoji: "🏢", title: "Full Org Chart", detail: "Open every department", xp: 200) {
            $0.stations.allSatisfy { $0.owned > 0 }
        },
        AchievementDef(id: "full_auto", emoji: "🤖", title: "Fully Automated", detail: "Hire every manager", xp: 300) {
            $0.stations.allSatisfy { $0.hasManager }
        },
        AchievementDef(id: "pre_seed", emoji: "🌱", title: "Funded!", detail: "Close your Pre-Seed", xp: 30) {
            $0.roundsClosed >= 1 || $0.exits > 0
        },
        AchievementDef(id: "unicorn", emoji: "🦄", title: "Unicorn", detail: "Hit a $1B valuation", xp: 150) {
            $0.bestValuation >= 1e9
        },
        AchievementDef(id: "ipo", emoji: "🔔", title: "Ring the Bell", detail: "Take a company public", xp: 500) {
            $0.roundsClosed > GameData.ipoRoundIndex || $0.exits > 0
        },
        AchievementDef(id: "exit_1", emoji: "🏝️", title: "First Exit", detail: "Exit a company and start again", xp: 500) {
            $0.exits >= 1
        },
        AchievementDef(id: "serial", emoji: "🔁", title: "Serial Founder", detail: "Exit 5 companies", xp: 2_000) {
            $0.exits >= 5
        },
        AchievementDef(id: "taps_1k", emoji: "👆", title: "Grinder", detail: "Tap 1,000 times", xp: 50) {
            $0.totalTaps >= 1_000
        },
        AchievementDef(id: "taps_10k", emoji: "🔥", title: "Built Different", detail: "Tap 10,000 times", xp: 300) {
            $0.totalTaps >= 10_000
        },
        AchievementDef(id: "unicorn_hunter", emoji: "✨", title: "Unicorn Hunter", detail: "Catch 25 golden unicorns", xp: 200) {
            $0.unicornsCaught >= 25
        },
        AchievementDef(id: "streak_7", emoji: "📅", title: "Showed Up", detail: "7-day streak", xp: 250) {
            $0.streakDays >= 7
        },
        AchievementDef(id: "streak_30", emoji: "🏆", title: "Relentless", detail: "30-day streak", xp: 1_500) {
            $0.streakDays >= 30
        },
        AchievementDef(id: "trillion", emoji: "👑", title: "Trillionaire", detail: "Hit a $1T valuation", xp: 1_000) {
            $0.bestValuation >= 1e12
        },
    ]
}
