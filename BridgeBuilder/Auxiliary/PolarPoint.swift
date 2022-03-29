//
//  PolarPoint.swift
//  balloon
//
//  Created by Hugo Lispector on 14/11/19.
//  Copyright © 2019 Hugo Lispector. All rights reserved.
//

import CoreGraphics


/// A point in polar coordinates.
public class PolarPoint: Codable {

    /// Radius of the point.
    var radius: CGFloat

    /// Angle of the point, in radians.
    var angle: CGFloat

    /// The equivalent CGPoint for the polar point.
    var cgPoint: CGPoint {
        let x: CGFloat = self.radius * cos(angle)
        let y: CGFloat = self.radius * sin(angle)
        return CGPoint(x: x, y: y)
    }

    /// Creates a polar point with radius and angle, in radians.
    /// - Parameters:
    ///   - radius: Radius of the point.
    ///   - angle: Angle of the point, in radians.
    init(radius: CGFloat, angle: CGFloat) {
        self.radius = radius
        self.angle = angle
    }

}
