import Foundation

struct StationState: Codable, Equatable {
    var owned: Int = 0
    var hasManager: Bool = false
    /// 0...1 progress of the current production cycle.
    var progress: Double = 0
    var running: Bool = false
}

/// Everything that gets saved. Decoding is tolerant of missing keys so new fields can
/// be added in updates without wiping anyone's company.
struct GameState: Codable {
    // Identity — the stuff players get attached to.
    var companyName: String = ""
    var companyLogo: String = "🦄"
    var hasOnboarded: Bool = false

    // Current run.
    var cash: Double = 0
    var runEarnings: Double = 0
    var stations: [StationState] = GameState.freshStations()
    var roundsClosed: Int = 0
    var pitchCooldownUntil: Date = .distantPast

    // Permanent progression (survives an Exit).
    var lifetimeEarnings: Double = 0
    var bestValuation: Double = 0
    var founderLevel: Int = 1
    var founderXP: Double = 0
    var skillPoints: Int = 0
    var skills: [String: Int] = [:]
    var stars: Int = 0
    var exits: Int = 0
    var unlockedAchievements: [String] = []
    var totalTaps: Int = 0
    var unicornsCaught: Int = 0

    // Retention.
    var streakDays: Int = 0
    var lastLoginDay: String = ""
    var lastSaved: Date = Date()

    static func freshStations() -> [StationState] {
        var list = Array(repeating: StationState(), count: GameData.stations.count)
        list[0].owned = 1
        return list
    }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = GameState()
        companyName = try c.decodeIfPresent(String.self, forKey: .companyName) ?? d.companyName
        companyLogo = try c.decodeIfPresent(String.self, forKey: .companyLogo) ?? d.companyLogo
        hasOnboarded = try c.decodeIfPresent(Bool.self, forKey: .hasOnboarded) ?? d.hasOnboarded
        cash = try c.decodeIfPresent(Double.self, forKey: .cash) ?? d.cash
        runEarnings = try c.decodeIfPresent(Double.self, forKey: .runEarnings) ?? d.runEarnings
        stations = try c.decodeIfPresent([StationState].self, forKey: .stations) ?? d.stations
        roundsClosed = try c.decodeIfPresent(Int.self, forKey: .roundsClosed) ?? d.roundsClosed
        pitchCooldownUntil = try c.decodeIfPresent(Date.self, forKey: .pitchCooldownUntil) ?? d.pitchCooldownUntil
        lifetimeEarnings = try c.decodeIfPresent(Double.self, forKey: .lifetimeEarnings) ?? d.lifetimeEarnings
        bestValuation = try c.decodeIfPresent(Double.self, forKey: .bestValuation) ?? d.bestValuation
        founderLevel = try c.decodeIfPresent(Int.self, forKey: .founderLevel) ?? d.founderLevel
        founderXP = try c.decodeIfPresent(Double.self, forKey: .founderXP) ?? d.founderXP
        skillPoints = try c.decodeIfPresent(Int.self, forKey: .skillPoints) ?? d.skillPoints
        skills = try c.decodeIfPresent([String: Int].self, forKey: .skills) ?? d.skills
        stars = try c.decodeIfPresent(Int.self, forKey: .stars) ?? d.stars
        exits = try c.decodeIfPresent(Int.self, forKey: .exits) ?? d.exits
        unlockedAchievements = try c.decodeIfPresent([String].self, forKey: .unlockedAchievements) ?? d.unlockedAchievements
        totalTaps = try c.decodeIfPresent(Int.self, forKey: .totalTaps) ?? d.totalTaps
        unicornsCaught = try c.decodeIfPresent(Int.self, forKey: .unicornsCaught) ?? d.unicornsCaught
        streakDays = try c.decodeIfPresent(Int.self, forKey: .streakDays) ?? d.streakDays
        lastLoginDay = try c.decodeIfPresent(String.self, forKey: .lastLoginDay) ?? d.lastLoginDay
        lastSaved = try c.decodeIfPresent(Date.self, forKey: .lastSaved) ?? d.lastSaved

        // New departments added in an update get appended rather than crashing old saves.
        if stations.count < GameData.stations.count {
            stations += Array(repeating: StationState(), count: GameData.stations.count - stations.count)
        }
    }
}

enum Format {
    private static let suffixes = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc",
                                   "UDc", "DDc", "TDc", "QaDc", "QiDc", "SxDc", "SpDc", "OcDc", "NoDc", "Vg"]

    static func number(_ value: Double) -> String {
        guard value.isFinite else { return "∞" }
        if value < 1_000 {
            return value < 10 && value != value.rounded()
                ? String(format: "%.1f", value)
                : String(format: "%.0f", value)
        }
        var tier = Int(log10(value) / 3)
        tier = min(tier, suffixes.count - 1)
        let scaled = value / pow(1_000, Double(tier))
        let digits = scaled >= 100 ? "%.0f" : (scaled >= 10 ? "%.1f" : "%.2f")
        return String(format: digits, scaled) + suffixes[tier]
    }

    static func money(_ value: Double) -> String { "$" + number(value) }

    static func duration(_ seconds: Double) -> String {
        if seconds < 1 { return String(format: "%.1fs", max(seconds, 0)) }
        let s = Int(seconds.rounded(.up))
        if s < 60 { return "\(s)s" }
        if s < 3_600 { return "\(s / 60)m \(s % 60)s" }
        if s < 86_400 { return "\(s / 3_600)h \((s % 3_600) / 60)m" }
        return "\(s / 86_400)d \((s % 86_400) / 3_600)h"
    }
}
