//
//  Evolvable.swift
//  GeneticBuilder
//
//  Created by Hugo Lispector on 22/02/22.
//

import Foundation
import CoreGraphics

/// Protocol to be adopted by Gene classes so they can their fitness evaluated.
protocol Evolvable where Self: Gene {

    /// Stores the last calculated fitness. Should be initialized at minus infinity.
    var calculatedFitness: CGFloat { get set }

    // Stores the last calculated max stress. Should be initialized at infinity.
    var calculatedMaxStress: CGFloat { get set }

    /// Fitness function to be used by our genetic algorithm. Stores the output in `calculatedFitness`
    /// before returning it.
    ///
    /// - Returns: A fitness number. Higher values means better performances.
    func fitness() -> CGFloat

    /// Creates a copy by value of the Gene.
    /// - Returns: A copy by value of the Gene.
    func copy() -> Evolvable
}
