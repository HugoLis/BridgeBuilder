//
//  TrussTest.swift
//  GeneticBuilder
//
//  Created by Hugo Lispector on 31/12/21.
//

import Foundation
import PythonKit

//Converting truss-test from Python to Swift, to add to sample code folder.
let Nusa = Python.import("nusa")
let Pyplot = Python.import("matplotlib.pyplot")

//Elascicity = E = Youngs Modulus
let elasticity = 210e9

//Cross sectional area = A
let area = pow(3.1416*(10e-3), 2)

let node1 = Nusa.Node([0, 0])
let node2 = Nusa.Node([2, 0])
let node3 = Nusa.Node([0, 2])
let element1 = Nusa.Truss([node1, node2], elasticity, area)
let element2 = Nusa.Truss([node1, node3], elasticity, area)
let element3 = Nusa.Truss([node2, node3], elasticity, area)
let simulation = Nusa.TrussModel()

for node in [node1, node2, node3] {
    simulation.add_node(node)
}

for element in [element1, element2, element3] {
    simulation.add_element(element)
}

// add force [x=500, y=0] to node3.
simulation.add_force(node3, [500,0])

// add constrains. ux=0 means no x displacement. uy=0 means no y displacement.
simulation.add_constraint(node1, ux: 0, uy: 0)
simulation.add_constraint(node2, uy: 0)

simulation.plot_model()
simulation.solve()

let solvedNodes = Array(simulation.get_nodes())

//ux and uy
let nodalDisplacements = solvedNodes.map { [$0.ux, $0.uy] }
print(nodalDisplacements)

//fx and fy
let nodalForces = solvedNodes.map { [$0.fx, $0.fy] }

let solvedElements = Array(simulation.get_elements())

// force is used for stress calculation. Not sure I will need this
let elementForces = solvedElements.map { $0.f }
//  Force in this element, given by
//      f = \frac{EA}{L}\begin{bmatrix} C & S & -C & -S \end{bmatrix}\left\{u\right\}
//  where:
//      * E - Elastic modulus
//      * A - Cross-section
//      * L - Length
//      * C - :math:`\cos(\theta)`
//      * S - :math:`\sin(\theta)`
//      * u - Four-element vector of nodal displacements -> :math:`\left\{                  ux_i; uy_i; ux_j; uy_j \right\}`

let elementStresses = solvedElements.map { $0.s }
//  Stress in this element, given by:
//      s = f/A
//  where:
//      * f = Force
//      * A = Cross sectional area
print(elementStresses)

simulation.plot_deformed_shape()
simulation.simple_report()
Pyplot.show()
