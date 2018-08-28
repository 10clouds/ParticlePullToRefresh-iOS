//
//  ParticlePullToRefresh.swift
//  10Clouds
//
//  Created by Alex on 27/08/2018.
//  Copyright © 2018 10Clouds. All rights reserved.
//

import UIKit

final public class ParticlePullToRefresh: UIControl {

    private enum RefreshState: Equatable {
        case initial
        case pulling(progress: CGFloat)
        case loading
        case completed
    }

    // MARK: - Properties

    var action: (() -> Void)?

    // Pull to refresh logic
    private let scrollView: UIScrollView
    private let color: UIColor
    private let threshold: CGFloat = 160
    private let refreshViewHeight: CGFloat = 120
    private var refreshState: RefreshState = .initial
    private var defaultContentOffset: CGPoint = .zero
    private var defaultContentInset: UIEdgeInsets = .zero
    private var contentOffsetObserver: NSKeyValueObservation?
    private var contentInsetObserver: NSKeyValueObservation?
    private var didSetDefaultContentArea = false
    private var canUpdateScrollViewInsets = true

    // Point
    private let pointSize: CGFloat = 6
    private let pointLayer = CAShapeLayer()
    private var initialPosition: CGPoint!

    // Circle
    private let emitterLayer = CAEmitterLayer()
    private let circleLayer = CAShapeLayer()
    private let cell = CAEmitterCell()
    private let radius: CGFloat = 20
    private var centerX: CGFloat!
    private var centerY: CGFloat!
    private var path: UIBezierPath!

    // MARK: - Initialization

    init(color: UIColor, scrollView: UIScrollView) {
        self.scrollView = scrollView
        self.color = color
        super.init(frame: .zero)

        setupPointLayer()
        setupCircleLayer()
        registerObservers()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        unregisterObservers()
    }

    // MARK: - View Lifecycle

    override public func layoutSubviews() {
        super.layoutSubviews()

        // Set default content offset and inset once
        if !didSetDefaultContentArea {
            defaultContentOffset = scrollView.contentOffset
            defaultContentInset = scrollView.contentInset
            didSetDefaultContentArea = true
        }
    }

    // MARK: - Additional Helpers

    public func endRefreshing() {
        if refreshState == .loading {
            refreshState = .completed
        }

        UIView.animate(withDuration: 0.2, animations: {
            self.scrollView.contentInset = self.defaultContentInset
            self.resetAnimationState()
        }, completion: { _ in
            self.refreshState = .initial
            self.circleLayer.removeFromSuperlayer()
            self.emitterLayer.removeFromSuperlayer()
        })
    }

    private func setupPointLayer() {
        initialPosition = CGPoint(x: scrollView.bounds.width / 2 - pointSize / 2, y: refreshViewHeight / 2 - pointSize / 2)

        let origin: CGPoint = .zero
        let size = CGSize(width: pointSize, height: pointSize)

        pointLayer.path = UIBezierPath(ovalIn: CGRect(origin: origin, size: size)).cgPath
        pointLayer.fillColor = color.cgColor
        pointLayer.position = initialPosition
        pointLayer.opacity = 0
        layer.addSublayer(pointLayer)
    }

    private func setupCircleLayer() {
        centerX = scrollView.bounds.width / 2
        centerY = refreshViewHeight / 2
        path = UIBezierPath(
            arcCenter: CGPoint(x: centerX, y: centerY),
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: 3 * .pi / 2,
            clockwise: true
        )

        circleLayer.path = path.cgPath
        circleLayer.strokeColor = color.cgColor
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.lineWidth = 3
        circleLayer.strokeEnd = 0
        circleLayer.lineCap = kCALineCapRound

        emitterLayer.beginTime = CACurrentMediaTime()
        emitterLayer.emitterShape = kCAEmitterLayerPoint
        emitterLayer.emitterPosition = CGPoint(x: centerX, y: centerY - radius)

        cell.name = "particle"
        cell.birthRate = 300
        cell.lifetime = 0.7
        cell.velocity = 15
        cell.velocityRange = 10
        cell.scale = 0.12
        cell.scaleRange = 0.2
        cell.emissionRange = .pi
        cell.emissionLongitude = .pi
        cell.contents = UIImage.drawParticle(color: color).cgImage
        cell.alphaSpeed = -1/0.7
        emitterLayer.emitterCells = [cell]
    }

    private func calculatePullToRefreshFrame(
        for scrollView: UIScrollView,
        pullValue: CGFloat
        ) {
        self.frame = CGRect(
            x: 0,
            y: 0,
            width: scrollView.bounds.width,
            height: pullValue > 0 ? 0 : pullValue
        )
    }

    private func handlePullProgress(for scrollView: UIScrollView, pullValue: CGFloat) {
        guard pullValue < 0 else { return }

        // Pull progress from 0 to 1
        let progress = (-pullValue / refreshViewHeight * 10).rounded(.toNearestOrAwayFromZero) / 10

        // When we are scrolling normally hide point
        if progress <= 0 {
            pointLayer.opacity = 0
            pointLayer.position = initialPosition
        }

        // Change circle opacity so it hides when we are scrolling normally during loading state
        if refreshState == .loading {
            emitterLayer.opacity = Float(progress)
            circleLayer.opacity = Float(progress)
        }

        // When we are pulling set corresponding state and animate point
        if progress > 0 && refreshState != .loading {
            refreshState = .pulling(progress: progress)

            CATransaction.begin()
            pointLayer.opacity = Float(progress)
            pointLayer.position = CGPoint(x: pointLayer.position.x, y: refreshViewHeight / 2 - radius * progress)
            CATransaction.commit()
        }

        // Condition to trigger loading state
        if progress >= 1 && scrollView.isDragging == false && refreshState != .loading {
            refreshState = .loading
            action?()

            // Movie point to a position where circle animation starts
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.2)
            CATransaction.setCompletionBlock {
                self.pointLayer.opacity = 0
                self.showAnimatedCircle()
            }

            pointLayer.position = CGPoint(x: pointLayer.position.x, y: refreshViewHeight / 2 - radius)

            CATransaction.commit()

            // Fixes jump stutter after releasing finger
            let contentOffset = scrollView.contentOffset

            canUpdateScrollViewInsets = false

            // Set content inset to show pull to refresh view while loading
            UIView.animate(withDuration: 0.2) {
                let top = self.refreshViewHeight + self.defaultContentInset.top
                scrollView.contentInset.top = top
                scrollView.contentOffset = contentOffset
            }
        }
    }

    private func showAnimatedCircle() {
        layer.addSublayer(circleLayer)
        layer.addSublayer(emitterLayer)

        let duration: CFTimeInterval = 1.4
        let delay = 0.1
        let timingFunction = CAMediaTimingFunction(controlPoints: 0.7, 0, 0.1, 1)

        let positionAnimation = CAKeyframeAnimation(keyPath: "emitterPosition")
        positionAnimation.path = path.cgPath
        positionAnimation.duration = duration
        positionAnimation.repeatCount = .infinity
        positionAnimation.beginTime = emitterLayer.convertTime(CACurrentMediaTime(), from: nil) + delay
        positionAnimation.timingFunction = timingFunction
        emitterLayer.add(positionAnimation, forKey: "emitterPosition")

        let strokeEndAnimation = CABasicAnimation(keyPath: "strokeEnd")
        strokeEndAnimation.fromValue = 0
        strokeEndAnimation.toValue = 1
        strokeEndAnimation.duration = duration
        strokeEndAnimation.repeatCount = .infinity
        strokeEndAnimation.beginTime = CACurrentMediaTime()
        strokeEndAnimation.timingFunction = timingFunction
        circleLayer.add(strokeEndAnimation, forKey: "strokeEnd")

        let strokeStartAnimation = CABasicAnimation(keyPath: "strokeStart")
        strokeStartAnimation.fromValue = 0
        strokeStartAnimation.toValue = 1
        strokeStartAnimation.duration = duration
        strokeStartAnimation.repeatCount = .infinity
        strokeStartAnimation.beginTime = CACurrentMediaTime() + delay
        strokeStartAnimation.timingFunction = timingFunction
        circleLayer.add(strokeStartAnimation, forKey: "strokeStart")
    }

    private func resetAnimationState() {
        pointLayer.position = initialPosition
        pointLayer.opacity = 0
        circleLayer.opacity = 0
        emitterLayer.opacity = 0
    }
}

// MARK: - KVO

extension ParticlePullToRefresh {
    private func registerObservers() {
        NotificationCenter.default.addObserver(forName: .UIDeviceOrientationDidChange, object: nil, queue: .main) { [weak self] notification in
            guard let strongSelf = self else { return }

            CATransaction.begin()
            CATransaction.setDisableActions(true)
            strongSelf.centerX = strongSelf.scrollView.bounds.width / 2
            strongSelf.centerY = strongSelf.refreshViewHeight / 2
            strongSelf.path = UIBezierPath(
                arcCenter: CGPoint(x: strongSelf.centerX, y: strongSelf.centerY),
                radius: strongSelf.radius,
                startAngle: -.pi / 2,
                endAngle: 3 * .pi / 2,
                clockwise: true
            )

            strongSelf.circleLayer.path = strongSelf.path.cgPath
            strongSelf.emitterLayer.beginTime = CACurrentMediaTime()
            strongSelf.emitterLayer.emitterPosition = CGPoint(
                x: strongSelf.centerX,
                y: strongSelf.centerY - strongSelf.radius
            )

            strongSelf.initialPosition = CGPoint(
                x: strongSelf.scrollView.bounds.width / 2 - strongSelf.pointSize / 2,
                y: strongSelf.refreshViewHeight / 2 - strongSelf.pointSize / 2
            )

            CATransaction.commit()

            if strongSelf.refreshState == .loading {
                strongSelf.emitterLayer.removeAllAnimations()
                strongSelf.circleLayer.removeAllAnimations()
                strongSelf.showAnimatedCircle()
            }
        }

        contentOffsetObserver = scrollView.observe(\.contentOffset, options: [.old, .new]) { [weak self] (scrollView, change) in
            guard let strongSelf = self else { return }
            guard let oldValue = change.oldValue else { return }
            guard let newValue = change.newValue else { return }
            guard newValue != oldValue else { return }

            let pullValue = strongSelf.defaultContentInset.top + scrollView.safeAreaInsets.top + newValue.y

            strongSelf.calculatePullToRefreshFrame(for: scrollView, pullValue: pullValue)

            strongSelf.handlePullProgress(for: scrollView, pullValue: pullValue)
        }

        contentInsetObserver = scrollView.observe(\.contentInset, options: [.old, .new]) { [weak self] (scrollView, change) in
            guard let strongSelf = self else { return }
            guard let oldValue = change.oldValue else { return }
            guard let newValue = change.newValue else { return }
            guard newValue != oldValue else { return }

            // This flag will be set to false before we set new content inset
            // This allows to react to external content inset changes anytime they occur
            if strongSelf.canUpdateScrollViewInsets && strongSelf.defaultContentInset != newValue {
                strongSelf.defaultContentInset = newValue
                strongSelf.resetAnimationState()
            }

            strongSelf.canUpdateScrollViewInsets = true
        }
    }

    private func unregisterObservers() {
        NotificationCenter.default.removeObserver(self, name: .UIDeviceOrientationDidChange, object: nil)

        contentOffsetObserver?.invalidate()
        contentInsetObserver?.invalidate()
    }
}
