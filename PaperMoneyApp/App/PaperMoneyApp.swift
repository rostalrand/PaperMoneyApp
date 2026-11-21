import SwiftUI

@main
struct PaperMoneyApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark) // Sleek dark financial trading aesthetic
        }
    }
}
