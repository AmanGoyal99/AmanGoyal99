import SwiftUI

/// The "upskilling" screen: founder level, title ladder and skill tree.
struct FounderView: View {
    @EnvironmentObject var engine: GameEngine

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                VStack(spacing: 8) {
                    Text(engine.state.companyLogo).font(.system(size: 60))
                    Text(engine.founderTitle.uppercased())
                        .font(.game(26, .heavy))
                        .foregroundStyle(Theme.brand)
                    Text("Founder Level \(engine.state.founderLevel)").font(.game(16))
                    ProgressBar(value: engine.state.founderXP / engine.xpNeeded(for: engine.state.founderLevel), height: 12)
                    Text("\(Int(engine.state.founderXP)) / \(Int(engine.xpNeeded(for: engine.state.founderLevel))) XP")
                        .font(.game(12, .semibold)).foregroundStyle(.white.opacity(0.6))
                    if let next = GameData.founderTitles.first(where: { $0.level > engine.state.founderLevel }) {
                        Text("Become a **\(next.title)** at level \(next.level)")
                            .font(.game(13, .medium)).foregroundStyle(.white.opacity(0.7))
                    }
                }
                .frame(maxWidth: .infinity)
                .card()

                HStack {
                    Text("SKILLS").font(.game(13)).foregroundStyle(.white.opacity(0.5))
                    Spacer()
                    Text("\(engine.state.skillPoints) point\(engine.state.skillPoints == 1 ? "" : "s") to spend")
                        .font(.game(13))
                        .foregroundStyle(engine.state.skillPoints > 0 ? Theme.pink : .white.opacity(0.5))
                }
                .padding(.horizontal, 4)

                ForEach(GameData.skills) { skill in
                    SkillRow(skill: skill)
                }

                Text("Earn XP by tapping, buying, hiring, closing rounds and unlocking trophies.")
                    .font(.game(12, .medium)).foregroundStyle(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            .padding(14)
        }
        .scrollIndicators(.hidden)
    }
}

private struct SkillRow: View {
    @EnvironmentObject var engine: GameEngine
    let skill: SkillDef

    var body: some View {
        let level = engine.skillLevel(skill.id)
        let maxed = level >= skill.maxLevel
        let canUpgrade = engine.state.skillPoints > 0 && !maxed
        HStack(spacing: 12) {
            Text(skill.emoji).font(.system(size: 30)).frame(width: 44)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(skill.name).font(.game(16))
                    Text("Lv \(level)/\(skill.maxLevel)").font(.game(12)).foregroundStyle(.white.opacity(0.5))
                }
                Text(skill.perLevel).font(.game(12, .medium)).foregroundStyle(.white.opacity(0.6))
                HStack(spacing: 3) {
                    ForEach(0..<skill.maxLevel, id: \.self) { i in
                        Capsule()
                            .fill(i < level ? AnyShapeStyle(Theme.brand) : AnyShapeStyle(Color.white.opacity(0.1)))
                            .frame(height: 6)
                    }
                }
            }
            Button { engine.upgradeSkill(skill.id) } label: {
                Text(maxed ? "MAX" : "+1")
                    .font(.game(16, .heavy))
                    .frame(width: 54, height: 40)
                    .background(Capsule().fill(canUpgrade ? AnyShapeStyle(Theme.brand) : AnyShapeStyle(Color.white.opacity(0.08))))
            }
            .buttonStyle(PressableStyle())
            .disabled(!canUpgrade)
        }
        .card(highlighted: canUpgrade)
    }
}
