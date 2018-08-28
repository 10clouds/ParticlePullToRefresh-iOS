//
//  UIScrollView+ParticlePullToRefresh.swift
//  ParticlePullToRefresh-iOS
//
//  Created by Alex Demchenko on 27/08/2018.
//  Copyright © 2018 10Clouds. All rights reserved.
//

import UIKit

private var assosiationKey: UInt8 = 0

public extension UIScrollView {
    private(set) var particlePullToRefresh: ParticlePullToRefresh? {
        get {
            return objc_getAssociatedObject(self, &assosiationKey) as? ParticlePullToRefresh
        }
        set {
            objc_setAssociatedObject(self, &assosiationKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    public func addParticlePullToRefresh(color: UIColor = .gray, action: @escaping () -> Void) {
        if particlePullToRefresh != nil {
            removeParticlePullToRefresh()
        }

        particlePullToRefresh = ParticlePullToRefresh(color: color, scrollView: self)
        particlePullToRefresh?.action = action
        addSubview(particlePullToRefresh!)
    }

    public func removeParticlePullToRefresh() {
        particlePullToRefresh?.removeFromSuperview()
        particlePullToRefresh = nil
    }
}
