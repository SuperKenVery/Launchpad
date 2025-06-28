//
//  Gesture.swift
//  launchpad
//
//  Created by ken on 2025/6/28.
//

// =====================================================================
// This file is just a draft, it hasn't been integrated into the UI yet.
// =====================================================================

import Foundation
import SwiftUI


class FiveFingerGestureRecognizer: NSGestureRecognizer {
    // Tracks touches
    private var initialPositions: [Int: CGPoint] = [:]
    private var currentPositions: [Int: CGPoint] = [:]
    
    // Handlers
    var onPinch: ((CGFloat) -> Void)?
    var onFinished: (() -> Void)?

    // Constants
    private let maxPinchScale: CGFloat = 0.3 // 最终缩放比例
    private let minPinchScale: CGFloat = 1.0 // 初始（张开）比例
    private var initialBoundingWidth: CGFloat = 0
    
    init(
        onPinch: @escaping (CGFloat) -> Void,
        onFinished: @escaping () -> Void
    ) {
        self.onPinch = onPinch
        self.onFinished = onFinished
        super.init(target: nil, action: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented, storyboard not supported")
    }
    
    override func touchesBegan(with event: NSEvent) {
        super.touchesBegan(with: event)

        let touches = event.touches(matching: .began, in: nil)
        initialPositions = touches.enumerated().reduce(into: [Int: CGPoint]()) { result, pair in
            let (index, touch) = (pair.offset, pair.element)
            result[index] = touch.normalizedLocation(in: self.view)
        }
        initialBoundingWidth = boundingWidth(from: initialPositions.map { $0.value })
    }

    override func touchesMoved(with event: NSEvent) {
        super.touchesMoved(with: event)
        
        let touches = event.touches(matching: .moved, in: nil)
        guard touches.count==5 else {return}
        
        currentPositions = touches.enumerated().reduce(into: [Int: CGPoint]()) { result, pair in
            let (index, touch) = (pair.offset, pair.element)
            result[index] = touch.normalizedLocation(in: self.view)
        }

        let currentPoints = currentPositions.map { $0.value }
        guard currentPoints.count >= 2 else { return }

        let currentWidth = boundingWidth(from: currentPoints)
        let progress = (currentWidth - initialBoundingWidth * maxPinchScale) /
                       (initialBoundingWidth - initialBoundingWidth * maxPinchScale)

        let boundedProgress = max(min(1.0, progress), 0.0)
        let reversedProgress = 1.0 - boundedProgress  // 0 = 合拢，1 = 张开

        if reversedProgress > 0.1 {
            onPinch?(reversedProgress)
        } else {
            onPinch?(0)
            self.state = .recognized
            onFinished?()
        }
    }

    override func touchesEnded(with event: NSEvent) {
        super.touchesEnded(with: event)

        if event.touches(matching: .ended, in: nil).count >= 5 {
            onPinch?(0)
            self.state = .recognized
            onFinished?()
        }
    }

    override func reset() { }

    // Helper for bounding rectangle
    private func boundingWidth(from points: [CGPoint]) -> CGFloat {
        guard let minX = points.map({ $0.x }).min(),
              let maxX = points.map({ $0.x }).max(),
              let minY = points.map({ $0.y }).min(),
              let maxY = points.map({ $0.y }).max()
        else { return 0 }

        return sqrt(pow(maxX - minX, 2) + pow(maxY - minY, 2))
    }
}

extension NSTouch {
    func normalizedLocation(in view: NSView?) -> CGPoint {
        guard let view = view else { return self.normalizedLocation(in: nil) }

        let locInView = self.location(in: view)
        let bounds = view.bounds
        return CGPoint(x: locInView.x / bounds.width,
                       y: locInView.y / bounds.height)
    }
}

struct LaunchpadGestureHost: NSViewRepresentable {
    @Binding var pinchProgress: CGFloat
    @Binding var isPresented: Bool

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        let recognizer = FiveFingerGestureRecognizer(
            onPinch: { progress in
                pinchProgress = progress
            },
            onFinished: {
                isPresented = false
            }
        )
        view.addGestureRecognizer(recognizer)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
