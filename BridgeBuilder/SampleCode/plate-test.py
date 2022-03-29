'''
Dependencies:
    pygmsh
    nusa
    scipy
    matplotlib

    nusa
    scipy
    matplotlib
    pygmsh
    numpy (installed by pygmsh)

    - Create a virtual environment on project folder:
    python3 -m venv myVirtualEnvironment
    #
    - To activate virtual environment via terminal:
    source myVirtualEnvironment/bin/activate
    - To deactivate via terminal
    deactivate
    #
    - On VSCode Go to Terminal > New Terminal
    - Then install project dependencies:
    pip3 install scipy numpy matplotlib tabulate gmsh nusa
    pip3 install -Iv meshio==3.3.1
'''

from nusa import *
import nusa.mesh as nmsh

import pygmsh

#md = nmsh.Modeler()

# # Com With
# with pygmsh.occ.Geometry() as geom:
#     rect = geom.add_rectangle([0.0, 0.0, 0.0], 1.0, 1.0)
#     msh = geom.generate_mesh()
#     print(msh)

# #Sem With
# geom2 = pygmsh.occ.Geometry()
# geom2.__enter__()
# rect = geom2.add_rectangle([0.0, 0.0, 0.0], 1.0, 1.0)
# msh = geom2.generate_mesh()
# print(msh)
# geom2.__exit__()

with pygmsh.occ.Geometry() as geom:

    geom.characteristic_length_min = 0.1
    geom.characteristic_length_max = 0.1
    rect = geom.add_rectangle([0.0, 0.0, 0.0], 1.0, 1.0)
    circ = geom.add_disk([0.3,0.4,0.0], 0.2)
    trapez = geom.add_polygon([[0.1,0.1,0.0], [0.4,0.1,0.0], [0.3, 0.3, 0.0], [0.2,0.3,0.0]])

    toRemove = geom.boolean_union([circ, trapez])

    geom.boolean_difference(rect, toRemove)

    msh = geom.generate_mesh()

for cell in msh.cells:
    if cell.type == "triangle":
        triangle_cells = cell.data
    # elif  cell.type == "tetra":
        # tetra_cells = cell.data

#print(mesh)
nc = msh.points
ec = triangle_cells

'''
geom = pygmsh.occ.Geometry()
print(geom)

geom.characteristic_length_min = 0.1
geom.characteristic_length_max = 0.1
rec = geom.add_rectangle([0.0, 0.0, 0.0], 1.0, 1.0)

mesh = geom.generate_mesh()
nc = mesh.points
ec = mesh.cells
print(mesh)
'''

#nc, ec = md.generate_mesh()
#print(nc)
x,y = nc[:,0], nc[:,1]

print(x)

nodos = []
elementos = []

for k,nd in enumerate(nc):
    cn = Node((x[k],y[k]))
    nodos.append(cn)

for k,elm in enumerate(ec):
    i,j,m = int(elm[0]),int(elm[1]),int(elm[2])
    ni,nj,nm = nodos[i],nodos[j],nodos[m]
    ce = LinearTriangle((ni,nj,nm),200e9,0.3,0.1)
    elementos.append(ce)

m = LinearTriangleModel()
for node in nodos: m.add_node(node)
for elm in elementos: m.add_element(elm)

# Boundary conditions and loads
minx, maxx = min(x), max(x)
miny, maxy = min(y), max(y)

for node in nodos:

    if node.x == minx:
        m.add_constraint(node, ux=0, uy=0)
    if node.x == maxx:
        m.add_force(node, (10e3,0))

m.plot_model()
m.solve()
solvedNodes = m.get_nodes()
for node in solvedNodes:
    print(node.seqv)

m.plot_nsol("seqv")
plt.show()
