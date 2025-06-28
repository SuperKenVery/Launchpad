//
//  SingleApp.swift
//  launchpad
//
//  Created by ken on 2025/6/24.
//

// This View displays a single app in the launch pad

import SwiftUI

struct SingleApp: View {
    static let width: CGFloat = 130
    let app: InstalledApp
    @State var openFailed = false
    
    var body: some View {
        
        VStack(spacing: 8) {
            // 应用图标
            app.icon
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: SingleApp.width, height: SingleApp.width)
                .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 4)
            
            // 应用名称
            Text(app.name)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(maxWidth: SingleApp.width)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            Task {
                let success = await app.launch()
                if success {
                    try! await Task.sleep(nanoseconds: UInt64(1e8)) // 0.1s
                    exit(0)
                } else {
                    self.openFailed = true
                }
            }
        }
        .alert("Failed to open app", isPresented: $openFailed) {
            VStack {
                Text("Failed to open \(app.name)")
                Button("OK") {
                }
            }
        }
        
        

    }
}

#Preview {
    SingleApp(app: fetch_apps()[0])
}
