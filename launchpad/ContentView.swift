//
//  ContentView.swift
//  launchpad
//
//  Created by ken on 2025/6/24.
//

import SwiftUI

struct ContentView: View {
    let apps: [InstalledApp] = fetch_apps()
    
    var body: some View {
        ZStack {
            LaunchPad()
        }
    }
}



#Preview {
    ContentView()
}
