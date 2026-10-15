import SwiftUI

struct RootView: View {
    @EnvironmentObject var engine: GameEngine
    @State private var tab = 0

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if engine.state.hasOnboarded {
                TabView(selection: $tab) {
                    OfficeView().themedBackground()
                        .tabItem { Label("Office", systemImage: "building.2.fill") }.tag(0)
                    FounderView().themedBackground()
                        .tabItem { Label("Founder", systemImage: "person.crop.circle.fill") }.tag(1)
                        .badge(engine.state.skillPoints)
                    TrophiesView().themedBackground()
                        .tabItem { Label("Trophies", systemImage: "trophy.fill") }.tag(2)
                    ShareCardView().themedBackground()
                        .tabItem { Label("Flex", systemImage: "sparkles") }.tag(3)
                }
                .tint(Theme.pink)
            } else {
                OnboardingView()
            }

            ToastOverlay()
            CelebrationOverlay()
        }
        .onAppear { engine.start() }
        .sheet(item: $engine.rewardPopup, onDismiss: { engine.rewardDismissed() }) { reward in
            RewardSheet(emoji: reward.emoji, title: reward.title, subtitle: reward.subtitle,
                        amount: reward.amount, footer: reward.footer)
        }
    }
}

// MARK: - Onboarding: naming your company creates instant ownership

struct OnboardingView: View {
    @EnvironmentObject var engine: GameEngine
    @State private var name = ""
    @State private var logo = "🦄"
    @FocusState private var focused: Bool

    private let logos = ["🦄", "🚀", "🔥", "💎", "🧠", "⚡️", "🐙", "🍕", "🌮", "🛸", "🐉", "🌈"]

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            Text(logo).font(.system(size: 96))
            Text("Every unicorn starts in a garage.")
                .font(.game(24, .heavy))
                .multilineTextAlignment(.center)
            Text("Name your startup. You'll take it from a coffee machine to an IPO.")
                .font(.game(15, .medium))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            TextField("", text: $name, prompt: Text("e.g. Pied Piper").foregroundColor(.white.opacity(0.3)))
                .font(.game(22))
                .multilineTextAlignment(.center)
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 16).fill(Theme.card))
                .focused($focused)
                .submitLabel(.go)
                .onSubmit(found)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                ForEach(logos, id: \.self) { l in
                    Button {
                        logo = l
                        Haptics.light()
                    } label: {
                        Text(l).font(.system(size: 30))
                            .frame(width: 48, height: 48)
                            .background(Circle().fill(logo == l ? AnyShapeStyle(Theme.brand) : AnyShapeStyle(Theme.card)))
                    }
                    .buttonStyle(PressableStyle())
                }
            }

            Spacer()

            Button(action: found) {
                Text("FOUND MY COMPANY")
                    .font(.game(20, .heavy))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Capsule().fill(Theme.brand))
                    .foregroundStyle(.white)
            }
            .buttonStyle(PressableStyle())
        }
        .padding(24)
        .onAppear { focused = true }
    }

    private func found() {
        Haptics.success()
        engine.foundCompany(name: name, logo: logo)
    }
}

// MARK: - Overlays

struct RewardSheet: View {
    @Environment(\.dismiss) private var dismiss
    let emoji: String
    let title: String
    let subtitle: String
    let amount: Double
    let footer: String

    var body: some View {
        VStack(spacing: 14) {
            Text(emoji).font(.system(size: 72))
            Text(title).font(.game(26, .heavy))
            Text(subtitle).font(.game(15, .medium)).foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            Text(Format.money(amount)).font(.game(44, .heavy)).foregroundStyle(Theme.cash)
            Text(footer).font(.game(12, .medium)).foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
            Button {
                Haptics.success()
                dismiss()
            } label: {
                Text("COLLECT")
                    .font(.game(20, .heavy))
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(Capsule().fill(Theme.goldGradient))
                    .foregroundStyle(.black)
            }
            .buttonStyle(PressableStyle())
        }
        .padding(24)
        .presentationDetents([.medium])
        .presentationBackground(Theme.background)
    }
}

struct ToastOverlay: View {
    @EnvironmentObject var engine: GameEngine

    var body: some View {
        VStack {
            if let toast = engine.toast {
                Text(toast)
                    .font(.game(14))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Capsule().fill(Color.black.opacity(0.85)).overlay(Capsule().stroke(Theme.brand, lineWidth: 1.5)))
                    .padding(.top, 6)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .id(toast)
                    .task(id: toast) {
                        try? await Task.sleep(nanoseconds: 2_200_000_000)
                        withAnimation { if engine.toast == toast { engine.toast = nil } }
                    }
            }
            Spacer()
        }
        .animation(.spring(response: 0.35), value: engine.toast)
        .allowsHitTesting(false)
    }
}

/// Big dopamine moments: closing a round, trophies, exits. Level-ups get a quick
/// banner instead so they don't interrupt the flow.
struct CelebrationOverlay: View {
    @EnvironmentObject var engine: GameEngine

    var body: some View {
        if let first = engine.celebrations.first {
            switch first {
            case .levelUp(let level):
                Color.clear
                    .task(id: first.id) {
                        engine.toast = "⬆️ Founder Level \(level)! +1 skill point"
                        engine.popCelebration()
                    }
            default:
                ZStack {
                    Color.black.opacity(0.75).ignoresSafeArea()
                    ConfettiView().ignoresSafeArea()
                    VStack(spacing: 14) {
                        content(for: first)
                        Button {
                            Haptics.light()
                            withAnimation { engine.popCelebration() }
                        } label: {
                            Text("LET'S GO")
                                .font(.game(18, .heavy))
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(Capsule().fill(Theme.brand))
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(PressableStyle())
                    }
                    .padding(24)
                    .background(RoundedRectangle(cornerRadius: 28).fill(Theme.bgTop))
                    .overlay(RoundedRectangle(cornerRadius: 28).stroke(Theme.brand, lineWidth: 2))
                    .padding(28)
                }
                .id(first.id)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
    }

    @ViewBuilder
    private func content(for celebration: Celebration) -> some View {
        switch celebration {
        case .roundClosed(let round):
            Text(round.emoji).font(.system(size: 80))
            Text("\(round.name) CLOSED!").font(.game(30, .heavy)).foregroundStyle(Theme.brand)
            Text("\(engine.state.companyName) is now worth \(Format.money(engine.valuation)).\nAll revenue is permanently 2x.")
                .font(.game(15, .medium)).multilineTextAlignment(.center)
            if round.id == GameData.ipoRoundIndex {
                Text("🏝️ You can now EXIT from the Trophies tab.")
                    .font(.game(14)).foregroundStyle(Theme.gold)
            }
            ShareCardButton(label: "Brag about it")
        case .achievement(let a):
            Text(a.emoji).font(.system(size: 80))
            Text("TROPHY UNLOCKED").font(.game(14, .heavy)).foregroundStyle(.white.opacity(0.6))
            Text(a.title).font(.game(30, .heavy)).foregroundStyle(Theme.goldGradient)
            Text("\(a.detail) · +\(Int(a.xp)) XP").font(.game(14, .medium))
        case .exit(let stars):
            Text("🏝️").font(.system(size: 80))
            Text("YOU EXITED!").font(.game(30, .heavy)).foregroundStyle(Theme.goldGradient)
            Text("+\(stars) Reputation stars. Your next company grows faster. Time to build something even bigger.")
                .font(.game(15, .medium)).multilineTextAlignment(.center)
        case .levelUp(let level):
            Text("Level \(level)")
        }
    }
}
