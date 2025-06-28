//
//  Wallpaper.swift
//  launchpad
//
//  Created by ken on 2025/6/25.
//

import Foundation
import SwiftUI
import CoreImage

struct WallpaperService {
    // 获取当前壁纸路径
    private static func getCurrentWallpaperPath() -> String? {
        let screens = NSScreen.screens
        
        // 尝试获取主屏幕或第一个屏幕的壁纸路径
        if let firstScreen = screens.first {
            return getScreenWallpaperPath(screen: firstScreen)
        }
        return nil
    }
    
    private static func getScreenWallpaperPath(screen: NSScreen) -> String? {
        // 处理不同macOS版本的API差异
        if #available(macOS 13.0, *) {
            return NSWorkspace.shared.desktopImageURL(for: screen)?.path
        } else {
            guard let workspace = NSWorkspace.shared.value(forKey: "_workspace") as? AnyObject,
                  let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
            else { return nil }
            
            let selector = #selector(NSWorkspace.desktopImageURL(for:))
            if workspace.responds(to: selector) {
                if let url = workspace.perform(selector, with: screenNumber).takeUnretainedValue() as? URL {
                    return url.path
                }
            }
            return nil
        }
    }
    
    // 创建模糊的壁纸图像
    static func createBlurredWallpaper(radius: CGFloat = 30.0) -> Image? {
        guard let wallpaperPath = getCurrentWallpaperPath(),
              let nsImage = NSImage(contentsOfFile: wallpaperPath) else {
            return nil
        }
        
        let context = CIContext()
        guard let tiffData = nsImage.tiffRepresentation,
              let ciImage = CIImage(data: tiffData),
              let filter = CIFilter(name: "CIGaussianBlur") else {
            return Image(nsImage: nsImage)
        }
        
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(radius, forKey: kCIInputRadiusKey)
        
        guard let output = filter.outputImage else {
            return Image(nsImage: nsImage)
        }
        
        // 计算裁剪区域（去除模糊半径影响的部分）
        let cropRect = CGRect(
            x: radius,
            y: radius,
            width: output.extent.width - 2 * radius,
            height: output.extent.height - 2 * radius
        )
        
        // 安全裁剪核心步骤
        let croppedOutput = cropRect.width > 0 && cropRect.height > 0
            ? output.cropped(to: cropRect)
            : output
        
        // 创建裁剪后的CGImage
        guard let cgImage = context.createCGImage(
            croppedOutput,
            from: croppedOutput.extent
        ) else {
            return Image(nsImage: nsImage)
        }
        
        let blurredImage = NSImage(cgImage: cgImage, size: CGSize(width: cropRect.width, height: cropRect.height))
        return Image(nsImage: blurredImage)
    }
}
