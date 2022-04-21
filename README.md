# Documentation

## Overview
This project was created as part of my final university thesis project and it 
is an application for the optimization of **truss bridges** structures using
evolutionary algorithms.

## Language Approach
The project uses the Swift programming language with Python libraries through 
PythonKit package.

PythonKit: allows Python interoperability with Swift.
(https://github.com/pvieito/PythonKit)
This package is Based on Python module from Swift for Tensorflow:
(https://www.tensorflow.org/swift/tutorials/python_interoperability)

## Dependencies
Python 3. 
> brew install python3

-pygmsh - Python Gmsh: used for creating geometries and meshes.
(https://github.com/nschloe/pygmsh)

- nusa (Numeric Structural Analysis): used for simulating structures and get
their performance plots and data. The Von Mises Stress (or seqv sigma equivalent
stress) seems to be a good metric.
(https://github.com/JorgeDeLosSantos/nusa)

- scipy (required by nusa)
- matplotlib (required by nusa)
- tabulate (required by nusa for showing truss reports)
- numpy (required by nusa, but installs with pygmsh)

To install everything, just run:
> pip3 install pygmsh nusa scipy matplotlib tabulate

## Fitness
Fitness metrics are use of material (weight), elements stresses
and supported load. It is possible to fix 2 of these metrics while keeping the
third one variable to reach a best value.

Fitness :
- Goal -> Max load before breakage
- Fixed max material
- Fixed max allowed stress

- Fixed load
- Goal -> Minimum material
- Fixed max allowed stress

- Fixed load
- Fixed max material
- Goal -> Minimum max element stress

Trusses examples include bridges, towers and cantilevers.

In the future, maybe the **plates** with various shapes cutouts could be added.
(2D laser cut structures). But that's slightly different problem with a different
model (maybe easier).


## Other

### Convert PythonObject to Swift array
let nc: [[Float]] = Array(msh.points)!
More on Swift for Tensorflow documentation:
(https://www.tensorflow.org/swift/tutorials/python_interoperability) 

### Getting rid of Python's "with" statement 
// With "with"
with pygmsh.occ.Geometry() as geom:
    rect = geom.add_rectangle([0.0, 0.0, 0.0], 1.0, 1.0)
    msh = geom.generate_mesh()
    print(msh)

//Sem With
geom2 = pygmsh.occ.Geometry()
geom2.__enter__() //__
rect = geom2.add_rectangle([0.0, 0.0, 0.0], 1.0, 1.0)
msh = geom2.generate_mesh()
print(msh)
geom2.__exit__() //__

### To import any file with PythonKit
import PythonKit
let Sys = Python.import("sys") 
/*
//sys.path.append("/Users/hugo/Projects/GeneticCutter/GeneticCutter")
let currentFile = URL(fileURLWithPath: #file)
let projectRoot = currentFile
  .deletingLastPathComponent()
  .deletingLastPathComponent()
  .path
let folderPath = projectRoot + "/GeneticBuilder"
Sys.path.append(folderPath)

let MyFile = Python.import("MyFile")
*/

### Python Virtual Environment (doesn't work with PythonKit)
- Create a virtual environment on project folder:
> python3 -m venv myVirtualEnvironment
- To activate virtual environment via terminal:
> source myVirtualEnvironment/bin/activate
- To deactivate via terminal
> deactivate

### Python Library and Hardened Runtime
Remove hardened runtime on Monterey so Python library (libpython) can be loaded
https://www.tensorflow.org/swift/tutorials/python_interoperability
Find python library (libpython)
https://pypi.org/project/find-libpython/



