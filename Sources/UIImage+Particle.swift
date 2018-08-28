//
//  UIImage+Particle.swift
//  ParticlePullToRefresh-iOS
//
//  Created by Alex Demchenko on 27/08/2018.
//  Copyright © 2018 10Clouds. All rights reserved.
//

import UIKit

extension UIImage {
    static func drawParticle(size: CGFloat = 6, color: UIColor = .gray) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { (context) in
            color.setFill()
            context.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: size, height: size))
        }
    }
}
