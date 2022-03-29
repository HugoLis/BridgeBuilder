//
//  PlateTest.swift
//  GeneticCutter
//
//  Created by Hugo Lispector on 31/12/21.
//

import Foundation
import PythonKit

let Sys = Python.import("sys")
let Nusa = Python.import("nusa")
let Pygmsh = Python.import("pygmsh")
let Pyplot = Python.import("matplotlib.pyplot")

let geometry = Pygmsh.occ.Geometry()
geometry.__enter__()
//geom.characteristic_length_min = 0.1
geometry.characteristic_length_max = 0.05
let rect = geometry.add_rectangle([0.0, 0.0, 0.0], 1.0, 1.0)
let circ = geometry.add_disk([0.6,0.6,0.0], 0.2)
let trapez = geometry.add_polygon([[0.1,0.1,0.0], [0.4,0.1,0.0], [0.3, 0.3, 0.0], [0.2,0.3,0.0]])

//let shapesToRemove = geometry.boolean_union([circ, trapez])
let shapesToRemove = [circ, trapez]
geometry.boolean_difference(rect, shapesToRemove)

let mesh = geometry.generate_mesh()
print(mesh)
geometry.__exit__()

var triangleCells: PythonObject = []
for cell in mesh.cells {
    if cell.type == "triangle" { triangleCells = cell.data }
}
let cells: [[Int]] = Array(triangleCells)!  //ec cells
let points3D: [[Double]] = Array(mesh.points)! //nc points

let points2D = points3D.map { [$0[0], $0[1]] }
let x = points2D.map { $0[0] }
let y = points2D.map { $0[1] }

var nodes: [PythonObject] = []
for position in points2D {
    // Node takes a 2D float array as input (x and y), like [1.0, 0.6].
    let node = Nusa.Node(position)
    nodes.append(node)
}

var elements: [PythonObject] = []
let youngsModulus = 200e9
let poissonRatio = 0.3
let thickness = 0.1
for cell in cells {
    let nodeIndex0 = cell[0]
    let nodeIndex1 = cell[1]
    let nodeIndex2 = cell[2]
    let node0 = nodes[nodeIndex0]
    let node1 = nodes[nodeIndex1]
    let node2 = nodes[nodeIndex2]

    /*
     (class) LinearTriangle(nodes, E, nu, t)
     Linear triangle element for finite element analysis
     *nodes* : ~nusa.core.Node
         Connectivity for element
     *E* : float -> Young's modulus
     *nu* : float -> Poisson ratio
     *t* : float -> Thickness
     Example: n1 = Node((0,0)) n2 = Node((0.5,0)) n3 = Node((0.5,0.25))
              e1 = LinearTriangle((n1,n2,n3),210e9, 0.3, 0.025)
    */
    let element = Nusa.LinearTriangle(
                      nodes: [node0, node1, node2],
                      E: youngsModulus,
                      nu: poissonRatio,
                      t: thickness
                  )
    elements.append(element)
}

let simulation = Nusa.LinearTriangleModel()
for node in nodes { simulation.add_node(node) }
for element in elements { simulation.add_element(element) }

// Boundary conditions and loads
let minX = x.min()
let maxX = x.max()
let minY = y.min()
let maxY = y.max()

for node in nodes {
    //ux = 0 means fixed x. //uy = 0 means fixed y.
    if Double(node.x) == minX { simulation.add_constraint(node, ux: 0, uy: 0) }
    // init force with 2D array: [xForce, yForce]
    if Double(node.x) == maxX { simulation.add_force(node, [10e3, 0])}
}


simulation.plot_model()
simulation.solve()
//(method) plot_nsol: (var="ux", units="Pa") -> None
/*
 Possible plots and information about simulation:
 "ux": [n.ux for n in self.get_nodes()],
 "uy": [n.uy for n in self.get_nodes()],
 "usum": [np.sqrt(n.ux**2 + n.uy**2) for n in self.get_nodes()],
 "sxx": [n.sx for n in self.get_nodes()],
 "syy": [n.sy for n in self.get_nodes()],
 "sxy": [n.sxy for n in self.get_nodes()],
 "seqv": [n.seqv for n in self.get_nodes()],
 "exx": [n.ex for n in self.get_nodes()],
 "eyy": [n.ey for n in self.get_nodes()],
 "exy": [n.exy for n in self.get_nodes()]
 */

let solvedNodes = Array(simulation.get_nodes())
let stressValues = solvedNodes.map {
    return $0.seqv
    // Displacements: x, y and total
    // n.ux, n.uy, np.sqrt(n.ux**2 + n.uy**2)

    // Stresses: x, y, shear and equivalent (Von Mises).
    // n.sx, n.sy, n.sxy, n.seqv

    // Strain? x, y and shear.
    //n.ex, n.ey, n.exy
}
print(stressValues)

simulation.plot_nsol("seqv")
Pyplot.show()

/*
 #Node Class Properies
 def __init__(self,coordinates):
     self.coordinates = coordinates
     self.x = coordinates[0] # usable prop
     self.y = coordinates[1] # usable prop
     self._label = ""
     self._ux = np.nan
     self._uy = np.nan
     self._ur = np.nan
     self._fx = 0.0
     self._fy = 0.0
     self._m = 0.0
     # Nodal stresses
     self._sx = 0.0
     self._sy = 0.0
     self._sxy = 0.0
     self._seqv = 0.0
     # Elements ¿what?
     self._elements = []
 */

/*
 #Element Class properties
 def __init__(self,etype):
     self.etype = etype # element type
     self.label = "" # label (reassignment -> Model.addElement)
     self._fx = 0.0
     self._fy = 0.0
     self._sx = 0.0
     self._sy = 0.0
     self._sxy = 0.0
*/

/*
 #Linear triangle element for finite element analysis

 *nodes* : :class:`~nusa.core.Node`
     Connectivity for element

 *E* : float
     Young's modulus

 *nu* : float
     Poisson ratio

 *t* : float
     Thickness

 def __init__(self,nodes,E,nu,t):
     Element.__init__(self,etype="triangle")
     self.nodes = nodes
     self.E = E
     self.nu = nu
     self.t = t
     self._sx = 0
     self._sy = 0
     self._sxy = 0
 */
