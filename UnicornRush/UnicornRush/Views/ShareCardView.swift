import SwiftUI

/// The viral loop. A 9:16 "Founder Card" sized for Instagram / TikTok stories,
/// rendered to an image and shared through the system share sheet.
struct ShareCardView: View {
    @EnvironmentObject var engine: GameEngine

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Flex your startup").font(.game(22, .heavy))
                FounderCard(snapshot: CardSnapshot(engine: engine))
                    .frame(width: 270, height: 480)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: Theme.pink.opacity(0.4), radius: 24)
                ShareCardButton(label: "Share my Founder Card")
                Text("Post it to your story and challenge a friend to beat your valuation.")
                    .font(.game(12, .medium)).foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
    }
}

/// Plain values so the card renders identically on screen and in ImageRenderer.
struct CardSnapshot {
    let company: String
    let logo: String
    let title: String
    let level: Int
    let roundName: String
    let roundEmoji: String
    let valuation: Double
    let streak: Int
    let stars: Int
    let exits: Int
    let tier: (name: String, emoji: String)

    init(engine: GameEngine) {
        company = engine.state.companyName
        logo = engine.state.companyLogo
        title = engine.founderTitle
        level = engine.state.founderLevel
        roundName = engine.currentRoundName
        roundEmoji = engine.state.roundsClosed == 0 ? "🏚️" : GameData.rounds[engine.state.roundsClosed - 1].emoji
        valuation = max(engine.valuation, engine.state.bestValuation)
        streak = engine.state.streakDays
        stars = engine.state.stars
        exits = engine.state.exits
        tier = CardSnapshot.tier(for: valuation)
    }

    static func tier(for valuation: Double) -> (name: String, emoji: String) {
        switch valuation {
        case ..<1e7: return ("Bronze", "🥉")
        case ..<1e9: return ("Silver", "🥈")
        case ..<1e12: return ("Gold", "🥇")
        case ..<1e15: return ("Diamond", "💎")
        default: return ("Legend", "👑")
        }
    }

    var shareText: String {
        "My startup \(company) \(logo) is worth \(Format.money(valuation)) (\(roundName)). I'm a Level \(level) \(title). Think you can build a bigger one? #UnicornRush"
    }
}

struct FounderCard: View {
    let snapshot: CardSnapshot

    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.violet, Theme.pink, Theme.gold],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            Color.black.opacity(0.25)
            VStack(spacing: 10) {
                Text("UNICORN RUSH").font(.game(12, .heavy)).tracking(4).opacity(0.8)
                Spacer(minLength: 4)
                Text(snapshot.logo).font(.system(size: 72))
                Text(snapshot.company).font(.game(26, .heavy)).lineLimit(1).minimumScaleFactor(0.5)
                Text("\(snapshot.roundEmoji) \(snapshot.roundName)")
                    .font(.game(15))
                    .padding(.horizontal, 12).padding(.vertical, 4)
                    .background(Capsule().fill(Color.black.opacity(0.3)))
                Spacer(minLength: 4)
                Text("VALUATION").font(.game(11, .heavy)).tracking(2).opacity(0.8)
                Text(Format.money(snapshot.valuation))
                    .font(.game(44, .heavy))
                    .lineLimit(1).minimumScaleFactor(0.5)
                    .shadow(color: .black.opacity(0.3), radius: 4)
                Text("\(snapshot.tier.emoji) \(snapshot.tier.name) Founder")
                    .font(.game(15))
                Spacer(minLength: 4)
                HStack(spacing: 0) {
                    pill("LV \(snapshot.level)", snapshot.title)
                    pill("🔥 \(snapshot.streak)", "day streak")
                    pill("⭐️ \(snapshot.stars)", "\(snapshot.exits) exits")
                }
                Spacer(minLength: 4)
                Text("Can you beat me?").font(.game(16, .heavy))
                Text("#UnicornRush").font(.game(12, .semibold)).opacity(0.8)
            }
            .foregroundStyle(.white)
            .padding(20)
        }
    }

    private func pill(_ top: String, _ bottom: String) -> some View {
        VStack(spacing: 2) {
            Text(top).font(.game(15, .heavy)).lineLimit(1).minimumScaleFactor(0.6)
            Text(bottom).font(.game(10, .semibold)).opacity(0.8).lineLimit(1).minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Renders the card to a high-res image on tap (not every frame) and opens the share sheet.
struct ShareCardButton: View {
    @EnvironmentObject var engine: GameEngine
    var label: String
    @State private var shareItems: ShareItems?

    var body: some View {
        Button {
            let snapshot = CardSnapshot(engine: engine)
            let renderer = ImageRenderer(content: FounderCard(snapshot: snapshot).frame(width: 360, height: 640))
            renderer.scale = 3
            var items: [Any] = [snapshot.shareText]
            if let image = renderer.uiImage { items.insert(image, at: 0) }
            shareItems = ShareItems(items: items)
            Haptics.light()
        } label: {
            Label(label, systemImage: "square.and.arrow.up")
                .font(.game(17, .heavy))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Capsule().fill(Theme.brand))
                .foregroundStyle(.white)
        }
        .buttonStyle(PressableStyle())
        .sheet(item: $shareItems) { share in
            ActivityView(items: share.items)
                .presentationDetents([.medium, .large])
        }
    }
}

struct ShareItems: Identifiable {
    let id = UUID()
    let items: [Any]
}

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
