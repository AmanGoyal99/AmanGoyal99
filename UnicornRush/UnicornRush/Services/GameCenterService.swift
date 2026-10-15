import GameKit
import UIKit

/// Global valuation leaderboard. Works once Game Center is enabled for the app in
/// App Store Connect with a leaderboard using `leaderboardID`; until then every call
/// is a silent no-op so the game runs fine without it.
final class GameCenterService {
    static let shared = GameCenterService()
    let leaderboardID = "unicornrush.valuation"
    private(set) var isAuthenticated = false

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            if let viewController = viewController {
                let root = UIApplication.shared.connectedScenes
                    .compactMap { ($0 as? UIWindowScene)?.keyWindow }
                    .first?.rootViewController
                root?.present(viewController, animated: true)
            }
            self?.isAuthenticated = (error == nil) && GKLocalPlayer.local.isAuthenticated
        }
    }

    func submit(valuation: Double) {
        guard isAuthenticated else { return }
        let score = Int(min(valuation, 9e18))
        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local,
                                  leaderboardIDs: [leaderboardID]) { _ in }
    }
}
