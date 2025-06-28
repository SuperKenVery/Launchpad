//
//  launchpadApp.swift
//  launchpad
//
//  Created by ken on 2025/6/24.
//

import SwiftUI

@main
struct launchpadApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    DispatchQueue.main.async {
                        if let window = NSApplication.shared.windows.last {
                            window.toggleFullScreen(nil)
                        }
                    }
                }
        }
    }
}
