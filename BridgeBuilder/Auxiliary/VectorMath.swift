//
//  VectorMath.swift
//  balloon
//
//  Created by Hugo Lispector on 24/08/19.
//  Copyright © 2019 Hugo Lispector. All rights reserved.
//

import Foundation

// MARK: Vectors Arithmetic
func +(left: CGVector, right: CGVector) -> CGVector {
    return CGVector(dx: left.dx + right.dx, dy: left.dy + right.dy)
}

func -(left: CGVector, right: CGVector) -> CGVector {
    return CGVector(dx: left.dx - right.dx, dy: left.dy - right.dy)
}

func *(vector: CGVector, scalar: CGFloat) -> CGVector {
    return CGVector(dx: vector.dx * scalar, dy: vector.dy * scalar)
}

func /(vector: CGVector, scalar: CGFloat) -> CGVector {
    return CGVector(dx: vector.dx / scalar, dy: vector.dy / scalar)
}

// MARK: Vectors Utilities
extension CGVector {
    var length: CGFloat {
        return sqrt(dx*dx + dy*dy)
    }

    var angle: CGFloat {
        return CGFloat(atan2(Double(dy), Double(dx)))
    }

    var point: CGPoint {
        return CGPoint(x: dx, y: dy)
    }

    func normalized() -> CGVector {
        return self / length
    }

    func changeLengthTo(_ newLength: CGFloat) -> CGVector {
        let normalizedVector = self.normalized()

        return CGVector(dx: newLength*normalizedVector.dx, dy: newLength*normalizedVector.dy)
    }
}

// MARK: Points Arithmetic
func +(left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func -(left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func *(point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func /(left: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: left.x / scalar, y: left.y / scalar)
}

// MARK: Points Utilities
extension CGPoint {
    var length: CGFloat {
        return sqrt(x*x + y*y)
    }

    var angle: CGFloat {
        return CGFloat(atan2(Double(y), Double(x)))
    }

    var vector: CGVector {
        return CGVector(dx: x, dy: y)
    }

    var polarPoint: PolarPoint {
        return PolarPoint(radius: length, angle: angle)
    }

    func normalized() -> CGPoint {
        return self / length
    }

    func distance(to point: CGPoint) -> CGFloat {
        return (self - point).length
    }
}

// MARK: Point to Line Distance
extension CGPoint {
    /// Gets intersection of normal from point to a line.
    /// https://stackoverflow.com/questions/28505344/shortest-distance-from-cgpoint-to-segment
    func normalIntersectionWithLine(of v: CGPoint, and w: CGPoint) -> CGPoint {
        let pv_dx = x - v.x
        let pv_dy = y - v.y
        let wv_dx = w.x - v.x
        let wv_dy = w.y - v.y

        let dot = pv_dx * wv_dx + pv_dy * wv_dy
        let len_sq = wv_dx * wv_dx + wv_dy * wv_dy
        let param = dot / len_sq

        //intersection of normal to vw that goes through the point
        var int_x, int_y: CGFloat

        if param < 0 || (v.x == w.x && v.y == w.y) {
            int_x = v.x
            int_y = v.y
        } else if param > 1 {
            int_x = w.x
            int_y = w.y
        } else {
            int_x = v.x + param * wv_dx
            int_y = v.y + param * wv_dy
        }

        return CGPoint(x: int_x, y: int_y)
    }

    /// Gets distance from point to line segment.
    /// https://stackoverflow.com/questions/28505344/shortest-distance-from-cgpoint-to-segment
    func distance(toLineSegmentOf v: CGPoint, and w: CGPoint) -> CGFloat {
        let intersection = normalIntersectionWithLine(of: v, and: w)
        return distance(to: intersection)
    }
}

// MARK: Other

/// Calculates the closes average between two angles, in radians.
/// - Parameters:
///   - a: Angle A.
///   - b: Angle B.
/// - Returns: The closest average angle, in radians.
func closestAverageAngle(a: CGFloat, b: CGFloat)-> CGFloat {
    let x = cos(a) + cos(b)
    let y = sin(a) + sin(b)
    return atan2(y, x)
}

/// Calculates the difference between two angles
/// - Parameters:
///   - a: Angle A.
///   - b: Angle B.
/// - Returns: Defference between A and B.
func deltaAngle(a: CGFloat, b: CGFloat)-> CGFloat {
    return abs( atan2(sin(a - b), cos(a - b)) )
}

/// Creates a CGPoint with same x and y values
/// - Parameter xAndY: value for x and y.
/// - Returns: The created CGPoint.
func pointWithSame(xAndY: CGFloat) -> CGPoint{
    return CGPoint(x: xAndY, y: xAndY)
}

/// Creates a CGSize with same x and y values.
/// - Parameter widthAndHeight: value for width and height
/// - Returns: The created CGSize.
func sizeWithSame(widthAndHeight: CGFloat) -> CGSize{
    return CGSize(width: widthAndHeight, height: widthAndHeight)
}

#if !(arch(x86_64) || arch(arm64))
/// Square root function.
/// - Parameter a: Input number.
/// - Returns: Square root of the input number.
func sqrt(a: CGFloat) -> CGFloat {
    return CGFloat(sqrtf(Float(a)))
}
#endif
