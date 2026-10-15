import SwiftUI

/// Trophies, lifetime stats, and the Exit (prestige) button.
struct TrophiesView: View {
    @EnvironmentObject var engine: GameEngine
    @State private var confirmExit = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                exitCard

                VStack(alignment: .leading, spacing: 8) {
                    Text("CAREER").font(.game(13)).foregroundStyle(.white.opacity(0.5))
                    statRow("Best valuation", Format.money(engine.state.bestValuation))
                    statRow("Lifetime revenue", Format.money(engine.state.lifetimeEarnings))
                    statRow("Companies exited", "\(engine.state.exits)")
                    statRow("Reputation stars", "\(engine.state.stars) (+\(engine.state.stars * 2)% revenue)")
                    statRow("Golden unicorns caught", "\(engine.state.unicornsCaught)")
                    statRow("Total taps", "\(engine.state.totalTaps)")
                }
                .card()

                HStack {
                    Text("TROPHIES").font(.game(13)).foregroundStyle(.white.opacity(0.5))
                    Spacer()
                    Text("\(engine.state.unlockedAchievements.count)/\(GameData.achievements.count)")
                        .font(.game(13))
                }
                .padding(.horizontal, 4)

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(GameData.achievements) { a in
                        let unlocked = engine.state.unlockedAchievements.contains(a.id)
                        VStack(spacing: 4) {
                            Text(unlocked ? a.emoji : "🔒").font(.system(size: 32))
                            Text(a.title).font(.game(12)).lineLimit(1).minimumScaleFactor(0.7)
                            Text(a.detail).font(.game(10, .medium))
                                .foregroundStyle(.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, minHeight: 100)
                        .card(highlighted: unlocked)
                        .opacity(unlocked ? 1 : 0.5)
                    }
                }
            }
            .padding(14)
        }
        .scrollIndicators(.hidden)
        .alert("Exit \(engine.state.companyName)?", isPresented: $confirmExit) {
            Button("Cancel", role: .cancel) {}
            Button("Exit for \(engine.starsOnExit) ⭐️") { engine.exitCompany() }
        } message: {
            Text("You'll start a new company from the garage, but keep your founder level, skills, trophies and every star (+2% revenue each, forever).")
        }
    }

    private var exitCard: some View {
        VStack(spacing: 8) {
            Text("🏝️ THE EXIT").font(.game(20, .heavy)).foregroundStyle(Theme.goldGradient)
            if engine.canExit {
                Text("Sell \(engine.state.companyName) and start over with \(engine.starsOnExit) new Reputation stars.")
                    .font(.game(14, .medium)).multilineTextAlignment(.center)
                Button { confirmExit = true } label: {
                    Text("EXIT FOR \(engine.starsOnExit) ⭐️")
                        .font(.game(18, .heavy)).foregroundStyle(.black)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Capsule().fill(Theme.goldGradient))
                }
                .buttonStyle(PressableStyle())
            } else {
                Text("Ring the IPO bell to unlock your first exit. Each exit makes every future company grow faster.")
                    .font(.game(13, .medium)).multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.6))
                Text("Stars if you could exit now: \(engine.starsOnExit)")
                    .font(.game(12)).foregroundStyle(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity)
        .card(highlighted: engine.canExit)
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.game(14, .medium)).foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text(value).font(.game(14))
        }
    }
}
