//
//  AppList.swift
//  launchpad
//
//  Created by ken on 2025/6/24.
//

import Foundation
import SwiftUI



struct InstalledApp: Identifiable {
    var id = UUID()
    
    var name: String
    var executable: String
    var bundleURL: URL?
    var icon: Image
    
    func launch() async -> Bool {
        guard let bundleURL = bundleURL else { return false }
        let configuration = NSWorkspace.OpenConfiguration()
        do {
            try await NSWorkspace.shared.openApplication(
                at: bundleURL,
                configuration: configuration
            )
            
            return true
        } catch {
            return false
        }
    }
}


func fetch_apps() -> [InstalledApp] {
    var apps: [InstalledApp] = []
    let fileManager = FileManager.default
    
    // 添加更多标准应用目录
    let searchPaths = [
        "/Applications",
        "/System/Applications",
        "~/Applications",
        "/System/Volumes/Preboot/Cryptexes/App/System/Applications" // For Apple Silicon
    ]
    
    for var path in searchPaths {
        if path.hasPrefix("~") {
            path = NSString(string: path).expandingTildeInPath
        }
        
        guard let enumerator = fileManager.enumerator(
            at: URL(fileURLWithPath: path),
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { continue }
        
        for case let url as URL in enumerator {
            guard url.pathExtension == "app",
                  let bundle = Bundle(url: url),
                  let infoDict = bundle.infoDictionary else { continue }
            
            // 获取应用名称
            let appName = infoDict["CFBundleDisplayName"] as? String ??
                          infoDict["CFBundleName"] as? String ??
                          url.deletingPathExtension().lastPathComponent
            
            // 获取可执行文件（更健壮的实现）
            guard let executableName = infoDict["CFBundleExecutable"] as? String else { continue }
            let executablePath = bundle.executablePath ?? url.appendingPathComponent(
                "Contents/MacOS/\(executableName)"
            ).path
            
            // 图标处理优化
            let icon: Image = {
                if let iconFile = infoDict["CFBundleIconFile"] as? String,
                   let resourcesURL = bundle.resourceURL,
                   let iconPath = [".icns", ""].first(where: {
                       let fullPath = resourcesURL.appendingPathComponent(iconFile + $0).path
                       return FileManager.default.fileExists(atPath: fullPath)
                   }) {
                    return Image(nsImage: NSImage(contentsOfFile: resourcesURL
                        .appendingPathComponent(iconFile + iconPath).path) ?? NSImage())
                }
                return Image(systemName: "questionmark.app")
            }()
            
            apps.append(InstalledApp(
                name: appName,
                executable: executablePath,
                bundleURL: bundle.bundleURL,   // 关键：存储 bundle URL
                icon: icon
            ))
        }
    }
    return apps
}

