//
//  LaunchPad.swift
//  launchpad
//
//  Created by ken on 2025/6/24.
//

import SwiftUI
import TranslucentWindowStyle

struct LaunchPad: View {
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 20), count: 7)
    @State private var apps: [InstalledApp] = []
    @State private var background: Image?
    private let blurRadius: CGFloat = 50
    private let cols = 7, rows = 5
    private var pageSize: Int {
        cols * rows
    }
    
    var body: some View {
        GeometryReader{ geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(0..<numberOfPages, id: \.self) { page in
                        PageContent(
                            apps: appsForPage(page),
                        )
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
        }
        .onAppear {
            apps = fetch_apps()
            DispatchQueue.global(qos: .userInitiated).async {
                if let blurredWallpaper = WallpaperService.createBlurredWallpaper(radius: blurRadius) {
                    DispatchQueue.main.async {
                        withAnimation {
                            self.background = blurredWallpaper
                        }
                    }
                }
            }
        }
        .background(background)
    }
    
    private var numberOfPages: Int {
        (apps.count + pageSize - 1) / pageSize // 向上取整的分页计算
    }
    
    private func appsForPage(_ page: Int) -> [InstalledApp] {
        let start = page * pageSize
        var end = start + pageSize
        end = end > apps.count ? apps.count : end
        
        return Array(apps[start..<end])
    }
}

struct PageContent: View {
    let apps: [InstalledApp]
    private let columns = Array(repeating: GridItem(.fixed(SingleApp.width), spacing: 160), count: 7)
    
    var body: some View {
        GeometryReader { geometry in
            let spacing = calc_padding(geometry: geometry)
            let columns = Array(repeating: GridItem(.fixed(SingleApp.width), spacing: spacing.horizontal), count: 7)
            
            // 主网格区域
            LazyVGrid(columns: columns, spacing: spacing.vertical) {
                // 应用图标
                ForEach(apps) { app in
                    SingleApp(app: app)
                }
            }
        }
        .padding(.vertical, 100)
    }
    
    private func calc_padding(geometry: GeometryProxy) -> (horizontal: Double, vertical: Double) {
        // 横向空间占用：7*130 + 6*160k
        // 纵向空间占用：5*(130+8+16?) + 4*120k
        // 上面的数字来自SingleApp view
        
        let horizontal_k = (geometry.size.width - 7*130) / (160*6)
        let vertical_k = (geometry.size.height - 5*(130+8+16)) / (120*4)
        
        
        let k = min(horizontal_k, vertical_k)
        
        return (
            horizontal: 160*k,
            vertical: 120*k
        )
    }
    
}




#Preview {
    LaunchPad()
}
