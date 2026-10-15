import SwiftUI

enum Theme {
    static let bgTop = Color(red: 0.12, green: 0.05, blue: 0.24)
    static let bgBottom = Color(red: 0.03, green: 0.02, blue: 0.10)
    static let card = Color.white.opacity(0.07)
    static let cardStroke = Color.white.opacity(0.10)
    static let pink = Color(red: 0.98, green: 0.34, blue: 0.90)
    static let violet = Color(red: 0.55, green: 0.36, blue: 1.0)
    static let mint = Color(red: 0.30, green: 0.95, blue: 0.70)
    static let gold = Color(red: 1.0, green: 0.80, blue: 0.25)
    static let cash = Color(red: 0.45, green: 1.0, blue: 0.55)

    static let brand = LinearGradient(colors: [pink, violet], startPoint: .leading, endPoint: .trailing)
    static let goldGradient = LinearGradient(colors: [gold, Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let background = LinearGradient(colors: [bgTop, bgBottom], startPoint: .top, endPoint: .bottom)
}

extension Font {
    static func game(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

struct CardBackground: ViewModifier {
    var highlighted = false
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(highlighted ? AnyShapeStyle(Theme.brand) : AnyShapeStyle(Theme.cardStroke),
                                    lineWidth: highlighted ? 2 : 1)
                    )
            )
    }
}

extension View {
    func card(highlighted: Bool = false) -> some View { modifier(CardBackground(highlighted: highlighted)) }
}

/// A chunky, juicy button style: squashes on press.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct ProgressBar: View {
    var value: Double
    var fill: AnyShapeStyle = AnyShapeStyle(Theme.brand)
    var height: CGFloat = 10

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.10))
                Capsule().fill(fill)
                    .frame(width: max(height, geo.size.width * min(max(value, 0), 1)))
            }
        }
        .frame(height: height)
    }
}

/// Lightweight emoji confetti burst, no assets needed.
struct ConfettiView: View {
    struct Piece: Identifiable {
        let id: Int
        let x: Double
        let speed: Double
        let spin: Double
        let delay: Double
    }

    var emojis = ["🎉", "✨", "💸", "🦄", "⭐️", "🚀"]
    @State private var start = Date()
    @State private var pieces: [Piece] = (0..<40).map { i in
        Piece(id: i, x: Double.random(in: 0...1), speed: Double.random(in: 0.6...1.3),
              spin: Double.random(in: -3...3), delay: Double.random(in: 0...0.6))
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            GeometryReader { geo in
                let t = timeline.date.timeIntervalSince(start)
                ZStack {
                    ForEach(pieces) { p in
                        let local = max(0, t - p.delay)
                        let px = CGFloat(p.x) * geo.size.width + CGFloat(sin(local * 3 + p.x * 10)) * 20
                        let py = CGFloat(local * p.speed) * geo.size.height * 0.8 - 30
                        Text(emojis[p.id % emojis.count])
                            .font(.system(size: 26))
                            .rotationEffect(.radians(p.spin * local))
                            .position(x: px, y: py)
                            .opacity(local > 2.2 ? 0 : 1)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

extension View {
    /// Tab contents sit on an opaque system background by default; paint ours instead.
    func themedBackground() -> some View {
        background(Theme.background.ignoresSafeArea())
    }
}
