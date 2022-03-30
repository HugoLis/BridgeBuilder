//
//  CGFloat+Python.swift
//  GeneticBuilder
//
//  Created by Hugo Lispector on 13/01/22.
//

import Foundation
import CoreGraphics

import PythonKit

// Makes CGFloat convertible to python, by converting it to Double, which
// already conforms to PythonConvertible because of PythonKit.
extension CGFloat: PythonConvertible {
    public var pythonObject: PythonObject {
        return PythonObject(Double(self))
    }
}
