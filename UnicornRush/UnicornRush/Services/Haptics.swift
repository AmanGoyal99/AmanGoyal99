import UIKit

/// Tiny wrapper so every reward has a physical "click". Haptics are a big part of
/// why idle games feel satisfying.
enum Haptics {
    private static let tapGenerator = UIImpactFeedbackGenerator(style: .soft)
    private static let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let notifier = UINotificationFeedbackGenerator()

    static func tap() { tapGenerator.impactOccurred(intensity: 0.6) }
    static func light() { lightGenerator.impactOccurred() }
    static func success() { notifier.notificationOccurred(.success) }
    static func error() { notifier.notificationOccurred(.error) }
}
