import SwiftUI

@main
struct UnicornRushApp: App {
    @StateObject private var engine = GameEngine()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(engine)
                .preferredColorScheme(.dark)
                .onAppear { GameCenterService.shared.authenticate() }
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            switch phase {
            case .active: engine.becameActive()
            case .background: engine.resignedActive()
            default: break
            }
        }
    }
}
