import SwiftUI

struct OfficeView: View {
    @EnvironmentObject var engine: GameEngine
    @State private var showPitch = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 12) {
                    HUDView()
                    FundingBanner(showPitch: $showPitch)
                    if engine.isViral { ViralBanner() }
                    buyModePicker
                    ForEach(GameData.stations) { def in
                        if engine.isUnlocked(def.id) || (def.id > 0 && engine.isUnlocked(def.id - 1)) {
                            StationRow(def: def)
                        }
                    }
                    Text("Tip: tap a department's icon to hustle it faster. Hire a manager to automate it.")
                        .font(.game(12, .medium))
                        .foregroundStyle(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 20)
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)

            UnicornOverlay()
        }
        .fullScreenCover(isPresented: $showPitch) { PitchView() }
    }

    private var buyModePicker: some View {
        HStack(spacing: 6) {
            Text("Buy").font(.game(13)).foregroundStyle(.white.opacity(0.6))
            ForEach(BuyMode.allCases) { mode in
                Button {
                    engine.buyMode = mode
                    Haptics.light()
                } label: {
                    Text(mode.rawValue)
                        .font(.game(13))
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background(Capsule().fill(engine.buyMode == mode ? AnyShapeStyle(Theme.brand) : AnyShapeStyle(Theme.card)))
                }
                .buttonStyle(PressableStyle())
            }
        }
    }
}

// MARK: - HUD

struct HUDView: View {
    @EnvironmentObject var engine: GameEngine

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(engine.state.companyLogo).font(.system(size: 30))
                VStack(alignment: .leading, spacing: 2) {
                    Text(engine.state.companyName).font(.game(18)).lineLimit(1)
                    Text("\(engine.currentRoundName) · \(engine.founderTitle)")
                        .font(.game(12, .semibold)).foregroundStyle(Theme.pink)
                }
                Spacer()
                FounderBadge()
            }

            VStack(spacing: 2) {
                Text(Format.money(engine.state.cash))
                    .font(.game(40, .heavy))
                    .foregroundStyle(Theme.cash)
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text("\(Format.money(engine.incomePerSecond))/sec automated")
                    .font(.game(13, .semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }

            HStack(spacing: 14) {
                stat("🏦", "Valuation", Format.money(engine.valuation))
                stat("🔥", "Streak", "\(engine.state.streakDays)d")
                stat("⭐️", "Stars", "\(engine.state.stars)")
            }
        }
        .card()
    }

    private func stat(_ emoji: String, _ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text("\(emoji) \(value)").font(.game(15)).lineLimit(1).minimumScaleFactor(0.6)
            Text(label).font(.game(11, .medium)).foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

struct FounderBadge: View {
    @EnvironmentObject var engine: GameEngine

    var body: some View {
        let progress = engine.state.founderXP / engine.xpNeeded(for: engine.state.founderLevel)
        ZStack {
            Circle().stroke(Color.white.opacity(0.12), lineWidth: 5)
            Circle().trim(from: 0, to: progress)
                .stroke(Theme.brand, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: -2) {
                Text("LV").font(.game(9)).foregroundStyle(.white.opacity(0.6))
                Text("\(engine.state.founderLevel)").font(.game(17, .heavy))
            }
        }
        .frame(width: 50, height: 50)
        .overlay(alignment: .topTrailing) {
            if engine.state.skillPoints > 0 {
                Circle().fill(Theme.pink).frame(width: 14, height: 14)
                    .overlay(Text("\(engine.state.skillPoints)").font(.game(9)))
            }
        }
    }
}

// MARK: - Funding round banner (the "next level")

struct FundingBanner: View {
    @EnvironmentObject var engine: GameEngine
    @Binding var showPitch: Bool
    @State private var pulse = false

    var body: some View {
        if let round = engine.nextRound {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("NEXT ROUND").font(.game(11)).foregroundStyle(.white.opacity(0.5))
                    Spacer()
                    Text("\(round.emoji) \(round.name) at \(Format.money(round.valuationTarget))")
                        .font(.game(13))
                }
                ProgressBar(value: engine.roundProgress, height: 12)
                if engine.canPitch {
                    Button {
                        showPitch = true
                        Haptics.success()
                    } label: {
                        Text("🎤 Investors want in! PITCH NOW")
                            .font(.game(17, .heavy))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(Theme.goldGradient))
                            .foregroundStyle(.black)
                            .scaleEffect(pulse ? 1.04 : 0.98)
                    }
                    .buttonStyle(PressableStyle())
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) { pulse = true }
                    }
                } else if engine.pitchCooldownRemaining > 0, engine.valuation >= round.valuationTarget {
                    Text("Investors will see you again in \(Format.duration(engine.pitchCooldownRemaining))")
                        .font(.game(12, .semibold)).foregroundStyle(.white.opacity(0.6))
                } else {
                    Text("Close it to permanently 2x all revenue")
                        .font(.game(12, .semibold)).foregroundStyle(.white.opacity(0.5))
                }
            }
            .card(highlighted: engine.canPitch)
        } else {
            Text("🌌 You've conquered every market. Exit and do it again, bigger.")
                .font(.game(14)).card(highlighted: true)
        }
    }
}

struct ViralBanner: View {
    @EnvironmentObject var engine: GameEngine

    var body: some View {
        let remaining = max(0, (engine.viralBoostUntil ?? Date()).timeIntervalSinceNow)
        HStack {
            Text("🚀 VIRAL! 7x revenue").font(.game(15, .heavy))
            Spacer()
            Text(Format.duration(remaining)).font(.game(15, .heavy)).monospacedDigit()
        }
        .foregroundStyle(.black)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.goldGradient))
    }
}

// MARK: - Department row

struct StationRow: View {
    @EnvironmentObject var engine: GameEngine
    let def: StationDef
    @State private var popID = 0
    @State private var showPop = false

    private var s: StationState { engine.state.stations[def.id] }

    var body: some View {
        if s.owned == 0 {
            lockedRow
        } else {
            ownedRow
        }
    }

    private var lockedRow: some View {
        let p = engine.purchase(for: def.id)
        let unlocked = engine.isUnlocked(def.id)
        return HStack(spacing: 12) {
            Text(unlocked ? def.emoji : "🔒").font(.system(size: 30)).frame(width: 56)
            VStack(alignment: .leading, spacing: 2) {
                Text(def.name).font(.game(16))
                Text(unlocked ? def.tagline : "Open \(GameData.stations[def.id - 1].name) first")
                    .font(.game(12, .medium)).foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            if unlocked {
                Button { engine.buy(def.id) } label: {
                    VStack(spacing: 0) {
                        Text("OPEN").font(.game(12, .heavy))
                        Text(Format.money(p.cost)).font(.game(13))
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Capsule().fill(engine.canAfford(def.id) ? AnyShapeStyle(Theme.brand) : AnyShapeStyle(Color.white.opacity(0.1))))
                }
                .buttonStyle(PressableStyle())
            }
        }
        .card()
        .opacity(unlocked ? 1 : 0.55)
    }

    private var ownedRow: some View {
        let cycle = engine.cycleTime(def.id)
        let revenue = engine.revenuePerCycle(def.id)
        let p = engine.purchase(for: def.id)
        let affordable = engine.canAfford(def.id)
        let milestone = engine.nextMilestone(def.id) ?? s.owned

        return VStack(spacing: 10) {
            HStack(spacing: 12) {
                Button { engine.tapStation(def.id) } label: {
                    ZStack {
                        Circle().fill(Theme.card)
                        Circle().trim(from: 0, to: min(s.progress, 1))
                            .stroke(Theme.mint, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text(def.emoji).font(.system(size: 28))
                    }
                    .frame(width: 56, height: 56)
                    .overlay(alignment: .bottom) {
                        Text("\(s.owned)")
                            .font(.game(11, .heavy))
                            .padding(.horizontal, 6).padding(.vertical, 1)
                            .background(Capsule().fill(Theme.violet))
                            .offset(y: 6)
                    }
                }
                .buttonStyle(PressableStyle())

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(def.name).font(.game(16))
                        Spacer()
                        Text("+\(Format.money(revenue))")
                            .font(.game(14)).foregroundStyle(Theme.cash)
                    }
                    ProgressBar(value: s.progress, fill: AnyShapeStyle(Theme.mint), height: 8)
                    HStack {
                        Text(cycle < 0.15 && s.hasManager ? "\(Format.money(revenue / cycle))/s" : Format.duration(cycle * (1 - min(s.progress, 1))))
                            .font(.game(11, .semibold)).foregroundStyle(.white.opacity(0.6))
                        Spacer()
                        Text("Next ⚡️ at \(milestone)")
                            .font(.game(11, .semibold)).foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
            .overlay(alignment: .topTrailing) {
                if showPop {
                    Text("+\(Format.money(revenue))")
                        .font(.game(16, .heavy)).foregroundStyle(Theme.cash)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .offset(y: -18)
                        .id(popID)
                }
            }

            HStack(spacing: 8) {
                if !s.hasManager {
                    let mCost = engine.managerCost(def.id)
                    Button { engine.hireManager(def.id) } label: {
                        VStack(spacing: 0) {
                            Text("HIRE \(def.managerName.uppercased())").font(.game(10, .heavy)).lineLimit(1).minimumScaleFactor(0.6)
                            Text(Format.money(mCost)).font(.game(12))
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 7)
                        .background(Capsule().fill(engine.state.cash >= mCost ? AnyShapeStyle(Theme.goldGradient) : AnyShapeStyle(Color.white.opacity(0.08))))
                        .foregroundStyle(engine.state.cash >= mCost ? Color.black : Color.white.opacity(0.6))
                    }
                    .buttonStyle(PressableStyle())
                } else {
                    Text("🤝 \(def.managerName)")
                        .font(.game(11, .semibold)).foregroundStyle(.white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                }

                Button { engine.buy(def.id) } label: {
                    VStack(spacing: 0) {
                        Text("BUY ×\(p.count)").font(.game(11, .heavy))
                        Text(Format.money(p.cost)).font(.game(13))
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 7)
                    .background(Capsule().fill(affordable ? AnyShapeStyle(Theme.brand) : AnyShapeStyle(Color.white.opacity(0.08))))
                    .foregroundStyle(affordable ? Color.white : Color.white.opacity(0.6))
                }
                .buttonStyle(PressableStyle())
            }
        }
        .card()
        .onChange(of: engine.payoutPulse[def.id]) { _, _ in
            // Only pop for slower departments; fast ones would just flicker.
            guard cycle >= 0.5 else { return }
            popID += 1
            withAnimation(.easeOut(duration: 0.2)) { showPop = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation(.easeIn(duration: 0.2)) { showPop = false }
            }
        }
    }
}

// MARK: - Golden unicorn (variable-ratio reward)

struct UnicornOverlay: View {
    @EnvironmentObject var engine: GameEngine
    @State private var bob = false

    var body: some View {
        GeometryReader { geo in
            if let pos = engine.unicornPosition {
                Button { engine.catchUnicorn() } label: {
                    Text("🦄")
                        .font(.system(size: 54))
                        .shadow(color: Theme.gold, radius: bob ? 20 : 6)
                        .offset(y: bob ? -10 : 10)
                        .rotationEffect(.degrees(bob ? -8 : 8))
                }
                .buttonStyle(PressableStyle())
                .position(x: pos.x * geo.size.width, y: pos.y * geo.size.height)
                .transition(.scale.combined(with: .opacity))
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) { bob = true }
                }
            }
        }
        .animation(.spring, value: engine.unicornPosition)
    }
}
