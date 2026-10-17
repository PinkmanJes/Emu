
import SwiftUI

@main
struct NOVAApp: App {
    var body: some Scene {
        WindowGroup {
            LibraryView()
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
        }
    }
}
