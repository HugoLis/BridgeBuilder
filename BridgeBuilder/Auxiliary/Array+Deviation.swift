//
//  Array+Deviation.swift
//  GeneticBuilder
//
//  Created by Hugo on 13/03/22.
//

import Foundation

extension Array where Element: FloatingPoint {

    func sum() -> Element {
        return self.reduce(0, +)
    }

    func average() -> Element {
        return self.sum() / Element(self.count)
    }

    func standardDeviation() -> Element {
        let mean = self.average()
        let v = self.reduce(0, { $0 + ($1-mean)*($1-mean) })
        return sqrt(v / Element(self.count))
        //return sqrt(v / (Element(self.count) - 1))
    }

}
