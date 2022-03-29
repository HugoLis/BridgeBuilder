//
//  Random.swift
//  GeneticBuilder
//
//  Created by Hugo Lispector on 06/02/22.
//

import GameplayKit

/// Class with functions for generating random CGFloat numbers with different
/// distributions.
class RandomCGFloat {

    /// Generates a random CGFloat within the given interval using a normal
    /// (gaussian) distribution.
    ///
    /// This distribution looks like a mountain. Numbers at the middle of the
    /// interval are more likelly to be created.
    /// - Parameter range: Range of possible output numbers.
    /// - Returns: A random number within the given interval, following a normal distribution.
    static func normal(in range: ClosedRange<CGFloat>) -> CGFloat {
        // Generates a random number between 0 and 1.
        let random = CGFloat(GKGaussianDistribution(lowestValue: 0, highestValue: 10000).nextUniform())
        // Converts the number to the desired interval using a line. y = ax + b
        // slope (a) = max-min; y constant at zero (b) = min; x = random number.
        return (range.upperBound - range.lowerBound) * random + range.lowerBound
    }

    /// Generates a random CGFloat within the given interval using a half-normal
    /// distribution.
    ///
    /// This distribution looks like half of a mountain. Numbers closer to the
    /// minimum possible number are more likelly to be created.
    /// - Parameter range: Range of possible output numbers.
    /// - Returns: A random number within the given interval, following a half-normal distribution.
    static func halfNormal(in range: ClosedRange<CGFloat>) -> CGFloat {
        // Generates a random number between -1 and 1 and takes it's absolute value.
        let random = CGFloat(abs(GKGaussianDistribution(lowestValue: -5000, highestValue: 5000).nextUniform()))

        // Converts the number to the desired interval using a line. y = ax + b
        // slope (a) = max-min; y constant at zero (b) = min; x = random number.
        return (range.upperBound - range.lowerBound) * random + range.lowerBound
    }

    /// Generates a random CGFloat within the given interval using an reversed
    /// half-normal distribution.
    ///
    /// This distribution looks like the half normal distribution on a mirror.
    /// Numbers closer to the maximum possible number are more likelly to be created.
    /// - Parameter range: Range of possible output numbers.
    /// - Returns: A random number within the given interval, following a reversed
    ///   half-normal distribution.
    static func reversedHalfNormal(in range: ClosedRange<CGFloat>) -> CGFloat {
        return range.upperBound - halfNormal(in: range) + range.lowerBound
    }

    /// Generates a random CGFloat within the given interval using a product
    /// distribution.
    ///
    /// A first random variable with uniform distribution is multiplied by another
    /// standard random value between 0 and 1. The distribution looks like a water
    /// slide, in which numbers closer to the minimum possible value are more
    /// likelly to be created.
    /// - Parameter range: Range of possible output numbers.
    /// - Returns: A random number within the given interval, following a product
    ///   distribution.
    static func product(in range: ClosedRange<CGFloat>) -> CGFloat {
        return CGFloat.random(in: range) * CGFloat.random(in: 0...1)
    }
}

/// Class with functions for generating random integers with different
/// distributions.
class RandomInt {

    /// Generates a random integer within the given interval using a normal
    /// (gaussian) distribution.
    ///
    /// This distribution looks like a mountain. Numbers at the middle of the
    /// interval are more likelly to be created.
    /// - Parameter range: Range of possible output numbers.
    /// - Returns: A random number within the given interval, following a normal distribution.
    static func normal(in range: ClosedRange<Int>) -> Int {
        return GKGaussianDistribution(lowestValue: range.lowerBound, highestValue: range.upperBound).nextInt()
    }

    /// Generates a random integer within the given interval using a half-normal
    /// distribution.
    ///
    /// This distribution looks like half of a mountain. Numbers closer to the
    /// minimum possible number are more likelly to be created.
    /// - Parameter range: Range of possible output numbers.
    /// - Returns: A random number within the given interval, following a half-normal distribution.
    static func halfNormal(in range: ClosedRange<Int>) -> Int {
        // Generates a random number between min-max and max values, then
        // if the value is below the min value, mirror it to the given range
        // by making value = 2*min - random. One is removed from the lowest value
        // and from the output so the min range value gets mirrored as well.
        var random = GKGaussianDistribution(lowestValue: (2*range.lowerBound - range.upperBound - 1), highestValue: range.upperBound).nextInt()
        print(random)
        if random < range.lowerBound { random = 2*range.lowerBound - random - 1 }
        if !range.contains(random) {
            print("oh no")
        }
        return random
    }

    /// Generates a random number within the given interval using an reversed
    /// half-normal distribution.
    ///
    /// This distribution looks like the half normal distribution on a mirror.
    /// Numbers closer to the maximum possible number are more likelly to be created.
    /// - Parameter range: Range of possible output numbers.
    /// - Returns: A random number within the given interval, following a reversed
    ///   half-normal distribution.
    static func reversedHalfNormal(in range: ClosedRange<Int>) -> Int {
        return range.upperBound - halfNormal(in: range) + range.lowerBound
    }
}
