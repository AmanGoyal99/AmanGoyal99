import SwiftUI

/// The "boss fight" for each level: a timing mini-game. Stop the needle in the
/// sweet spot three times to close the round. Charisma widens the sweet spot.
struct PitchView: View {
    @EnvironmentObject var engine: GameEngine
    @Environment(\.dismiss) private var dismiss

    @State private var start = Date()
    @State private var zoneCenter = 0.5
    @State private var hits = 0
    @State private var misses = 0
    @State private var feedback = "Tap when the needle is in the green zone"
    @State private var finished = false
    @State private var shake = false

    private let hitsNeeded = 3
    private let hitLines = ["🔥 Killer metric!", "😮 They're leaning in...", "🤝 Term sheet incoming!"]
    private let missLines = ["😬 Awkward silence...", "🫠 \"Who are your competitors?\"", "🥶 Someone checked their phone"]

    private var round: FundingRound? { engine.nextRound }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            if let round = round {
                VStack(spacing: 22) {
                    HStack {
                        Button("Leave") { dismiss() }
                            .font(.game(15)).foregroundStyle(.white.opacity(0.6))
                        Spacer()
                    }
                    Text("\(round.emoji) \(round.name) PITCH")
                        .font(.game(28, .heavy))
                        .foregroundStyle(Theme.brand)
                    Text("🧐").font(.system(size: 90))
                    Text(round.investorLine)
                        .font(.game(17, .semibold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal)

                    HStack(spacing: 12) {
                        ForEach(0..<hitsNeeded, id: \.self) { i in
                            Circle()
                                .fill(i < hits ? AnyShapeStyle(Theme.mint) : AnyShapeStyle(Color.white.opacity(0.12)))
                                .frame(width: 22, height: 22)
                        }
                    }
                    Text("Strikes left: \(max(0, engine.pitchMissesAllowed - misses))")
                        .font(.game(13, .semibold)).foregroundStyle(.white.opacity(0.6))

                    meter
                        .offset(x: shake ? -8 : 0)

                    Text(feedback)
                        .font(.game(18))
                        .frame(height: 30)

                    Spacer()

                    Button(action: pitchTapped) {
                        Text(finished ? "..." : "PITCH!")
                            .font(.game(30, .heavy))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                            .background(RoundedRectangle(cornerRadius: 26).fill(Theme.goldGradient))
                    }
                    .buttonStyle(PressableStyle())
                    .disabled(finished)
                }
                .padding(20)
            }
        }
        .onAppear { zoneCenter = randomZone() }
    }

    private var meter: some View {
        TimelineView(.animation(paused: finished)) { timeline in
            GeometryReader { geo in
                let w = geo.size.width
                let needle = needlePosition(at: timeline.date)
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.10))
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.mint.opacity(0.75))
                        .frame(width: w * engine.pitchZoneWidth)
                        .offset(x: w * (zoneCenter - engine.pitchZoneWidth / 2))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white)
                        .frame(width: 6, height: 64)
                        .shadow(color: .white, radius: 6)
                        .offset(x: w * needle - 3)
                }
            }
            .frame(height: 56)
        }
    }

    private func needlePosition(at date: Date) -> Double {
        let t = date.timeIntervalSince(start)
        return (sin(t * engine.pitchNeedleSpeed) + 1) / 2
    }

    private func randomZone() -> Double {
        let half = engine.pitchZoneWidth / 2
        return Double.random(in: half...(1 - half))
    }

    private func pitchTapped() {
        guard !finished else { return }
        let needle = needlePosition(at: Date())
        if abs(needle - zoneCenter) <= engine.pitchZoneWidth / 2 {
            feedback = hitLines[min(hits, hitLines.count - 1)]
            hits += 1
            Haptics.success()
            if hits >= hitsNeeded {
                finish(success: true)
            } else {
                withAnimation(.spring) { zoneCenter = randomZone() }
            }
        } else {
            feedback = missLines[min(misses, missLines.count - 1)]
            misses += 1
            Haptics.error()
            withAnimation(.default.repeatCount(3, autoreverses: true).speed(4)) { shake = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { shake = false }
            if misses > engine.pitchMissesAllowed {
                finish(success: false)
            }
        }
    }

    private func finish(success: Bool) {
        finished = true
        if !success { feedback = "❌ They passed... for now." }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            engine.finishPitch(success: success)
            dismiss()
        }
    }
}
