import matplotlib.markers as markers
import matplotlib.pyplot as pyplot
import matplotlib.cm as cm
from nusa import *
import math

import NusaPlus

# def plot_model_thickness(truss_model: TrussModel):
#     """
#     Plot the mesh model, including bcs
#     """
#     import matplotlib.pyplot as plt

#     fig = plt.figure()
#     ax = fig.add_subplot(111)

#     def get_area(element: Truss):
#         return element.A
#     crossAreas = list(map(get_area,truss_model.get_elements()))
#     minArea = min(crossAreas)
#     maxArea = max(crossAreas)

#     #set these for best visuals
#     thinnestLine = 1
#     boldestLine = 4

#     if maxArea != minArea:
#         slope = (boldestLine-thinnestLine)/(maxArea-minArea)
#         shift = (boldestLine*minArea - thinnestLine*maxArea)/(minArea-maxArea)
#     else:
#         slope = 0
#         shift = boldestLine

#     for elm in truss_model.get_elements():
#         ni, nj = elm.get_nodes()
#         lineWidth = elm.A * slope + shift
#         ax.plot([ni.x,nj.x],[ni.y,nj.y],"o-", color='blue', linewidth=lineWidth, markersize=lineWidth)
#         for nd in (ni,nj):
#             if nd.fx > 0: truss_model._draw_xforce(ax,nd.x,nd.y,1)
#             if nd.fx < 0: truss_model._draw_xforce(ax,nd.x,nd.y,-1)
#             if nd.fy > 0: truss_model._draw_yforce(ax,nd.x,nd.y,1)
#             if nd.fy < 0: truss_model._draw_yforce(ax,nd.x,nd.y,-1)
#             if nd.ux == 0: truss_model._draw_xconstraint(ax,nd.x,nd.y)
#             if nd.uy == 0: truss_model._draw_yconstraint(ax,nd.x,nd.y)

#     x0,x1,y0,y1 = truss_model.rect_region()
#     plt.axis('equal')
#     ax.set_xlim(x0,x1)
#     ax.set_ylim(y0,y1)

# Plots truss model with proportional thicknessess.
def plot_proportional_area_model(truss_model: TrussModel):
    import matplotlib.pyplot as plt

    fig = plt.figure()
    ax = fig.add_subplot(111)

    def get_area(element: Truss):
        return element.A
    crossAreas = list(map(get_area,truss_model.get_elements()))
    minArea = min(crossAreas)
    #maxArea = max(crossAreas)

    #set these for best visuals
    thinnestLine = 1.5

    for elm in truss_model.get_elements():
        ni, nj = elm.get_nodes()

        #sqrt because we display thickness, which is proportional to sqrt of area.
        #it is ok to drop sqrt in order to exagerate the visual difference.
        widthMultiplier = math.sqrt(elm.A/minArea)
        lineWidth = thinnestLine * widthMultiplier
        ax.plot([ni.x,nj.x],[ni.y,nj.y],"o-", color='blue', linewidth=lineWidth, markersize=lineWidth)
        for nd in (ni,nj):
            if nd.fx > 0: truss_model._draw_xforce(ax,nd.x,nd.y,1)
            if nd.fx < 0: truss_model._draw_xforce(ax,nd.x,nd.y,-1)
            if nd.fy > 0: truss_model._draw_yforce(ax,nd.x,nd.y,1)
            if nd.fy < 0: truss_model._draw_yforce(ax,nd.x,nd.y,-1)
            if nd.ux == 0: _draw_xconstraint(truss_model, ax,nd.x,nd.y)
            if nd.uy == 0: _draw_yconstraint(truss_model, ax,nd.x,nd.y)

    x0,x1,y0,y1 = truss_model.rect_region()
    plt.axis('equal')
    ax.set_xlim(x0,x1)
    ax.set_ylim(y0,y1)

# Plots truss model with proportional thicknessess and proportial forces arrows.
def plot_proportional_model(truss_model: TrussModel):
    import matplotlib.pyplot as plt

    fig = plt.figure()
    ax = fig.add_subplot(111)

    def get_force(node: Node):
        return (node.fx, node.fy)
    forces = list(map(get_force,truss_model.get_nodes()))
    forces = [component for force in forces for component in force]
    #removing zeros
    forces = [i for i in forces if i != 0]
    minForce = min(forces)
    shortestArrowLength = 5

    def get_area(element: Truss):
        return element.A
    crossAreas = list(map(get_area,truss_model.get_elements()))
    minArea = min(crossAreas)
    #maxArea = max(crossAreas)

    #set these for best visuals
    thinnestLine = 1.5

    for elm in truss_model.get_elements():
        ni, nj = elm.get_nodes()

        #sqrt because we display thickness, which is proportional to sqrt of area.
        #it is ok to drop sqrt in order to exagerate the visual difference.
        widthMultiplier = math.sqrt(elm.A/minArea)
        lineWidth = thinnestLine * widthMultiplier
        ax.plot([ni.x,nj.x],[ni.y,nj.y],"o-", color='blue', linewidth=lineWidth, markersize=lineWidth)

        for nd in (ni,nj):
            # if nd.fx > 0: truss_model._draw_xforce(ax,nd.x,nd.y,1)
            # if nd.fx < 0: truss_model._draw_xforce(ax,nd.x,nd.y,-1)
            # if nd.fy > 0: truss_model._draw_yforce(ax,nd.x,nd.y,1)
            # if nd.fy < 0: truss_model._draw_yforce(ax,nd.x,nd.y,-1)

            fxMultiplier = nd.fx/minForce
            fyMultiplier = nd.fy/minForce
            if nd.fx != 0 or nd.fy != 0: _draw_force(truss_model,ax,nd.x,nd.y,fxMultiplier, fyMultiplier)
            if nd.ux == 0: _draw_xconstraint(truss_model, ax,nd.x,nd.y)
            if nd.uy == 0: _draw_yconstraint(truss_model, ax,nd.x,nd.y)

    x0,x1,y0,y1 = truss_model.rect_region()
    plt.axis('equal')
    ax.set_xlim(x0,x1)
    ax.set_ylim(y0,y1)

def _draw_force(truss_model,axes,x,y,fxMultiplier,fyMultiplier):
    minArrowSize = _calculate_arrow_size(truss_model)
    HW = minArrowSize/5.0
    HL = minArrowSize/3.0
    arrow_props = dict(head_width=HW, head_length=HL, fc='r', ec='r')
    axes.arrow(x, y, fxMultiplier*minArrowSize, fyMultiplier*minArrowSize, **arrow_props)

def _draw_xforce(truss_model,axes,x,y,ddir=1):
    """
    Draw horizontal arrow -> Force in x-dir
    """
    dx, dy = truss_model._calculate_arrow_size(), 0
    HW = dx/5.0
    HL = dx/3.0
    arrow_props = dict(head_width=HW, head_length=HL, fc='r', ec='r')
    axes.arrow(x, y, ddir*dx, dy, **arrow_props)

def _draw_yforce(truss_model,axes,x,y,ddir=1):
    """
    Draw vertical arrow -> Force in y-dir
    """
    dx,dy = 0, truss_model._calculate_arrow_size()
    HW = dy/5.0
    HL = dy/3.0
    arrow_props = dict(head_width=HW, head_length=HL, fc='r', ec='r')
    axes.arrow(x, y, dx, ddir*dy, **arrow_props)

def _draw_xconstraint(truss_model,axes,x,y):
    if x<=0:
        axes.plot(x, y, marker = markers.CARETRIGHT, color = "green", markersize=10, alpha=0.6)
    else :
        axes.plot(x, y, marker = markers.CARETLEFT, color = "green", markersize=10, alpha=0.6)

def _draw_yconstraint(truss_model,axes,x,y):
    if y<=0:
        axes.plot(x, y, marker = markers.CARETUP, color = "green", markersize=10, alpha=0.6)
    else:
        axes.plot(x, y, marker = markers.CARETDOWN, color = "green", markersize=10, alpha=0.6)

def _calculate_arrow_size(truss_model):
    x0,x1,y0,y1 = truss_model.rect_region(factor=10)
    sf = 5e-2
    kfx = sf*(x1-x0)
    kfy = sf*(y1-y0)
    return np.mean([kfx,kfy])

def _calculate_proportional_arrow_size(truss_model):
    def get_force(element: Truss):
        return element.f

    forces = list(map(get_force, truss_model.get_elements()))


    ###
    ###
    ###
    x0,x1,y0,y1 = truss_model.rect_region(factor=10)
    sf = 5e-2
    kfx = sf*(x1-x0)
    kfy = sf*(y1-y0)
    return np.mean([kfx,kfy])

def plot_deformed_shape_stress(truss_model,dfactor=1.0):
    import matplotlib.pyplot as plt
    fig = plt.figure()
    ax = fig.add_subplot(111)

    df = dfactor*truss_model._calculate_deformed_factor()
    cmap = cm.get_cmap('jet') #'RdBu' is divergin with 0 on color value 0.5

    def get_abs_stress(element):
        return abs(element.s)

    stresses = list(map(get_abs_stress,truss_model.get_elements()))

    maxStress = max(stresses)

    for elm in truss_model.get_elements():
        ni,nj = elm.get_nodes()
        x, y = [ni.x,nj.x], [ni.y,nj.y]
        xx = [ni.x+ni.ux*df, nj.x+nj.ux*df]
        yy = [ni.y+ni.uy*df, nj.y+nj.uy*df]

        ##maxStress -> color 1 or -1; 0 stress -> color 0.5
        #colorValue = elm.s * 0.5 / maxStress

        ##maxStress -> color 1; 0 stress -> color 0
        colorValue = abs(elm.s) / maxStress
        color = cmap(colorValue)

        ax.plot(x,y,'bo-')
        ax.plot(xx,yy,'ro--', color=color, markerfacecolor = 'gray', markeredgecolor = 'gray')

    x0,x1,y0,y1 = truss_model.rect_region()
    plt.axis('equal')
    ax.set_xlim(x0,x1)
    ax.set_ylim(y0,y1)


## Example 1
# '''
E,A = 210e9, 3.1416*(10e-3)**2
# E = 210e9
# A1 = (10e-3)*3.1416**2
# A2 = (20e-3)*3.1416**2
# A3 = (30e-3)*3.1416**2
n1 = Node((0,0))
n2 = Node((2,0))
n3 = Node((0,2))
e1 = Truss((n1,n2),E,2*A)
e2 = Truss((n1,n3),E,A)
e3 = Truss((n2,n3),E,A)
m = TrussModel()
for n in (n1,n2,n3): m.add_node(n)
for e in (e1,e2,e3): m.add_element(e)
m.add_constraint(n1, ux=0, uy=0)
m.add_constraint(n2, uy=0)
m.add_force(n3, (500,0))
#m.add_force(n2, (1000,800))
#m.add_force(n1, (0,0))
m.plot_model()
NusaPlus.plot_proportional_model(m)
NusaPlus.plot_proportional_area_model(m)
m.solve()

# for node in m.get_nodes():
    ## displacements
    #print(node.ux)
    #print(node.uy)

    ## forces
    #print(node.fx)
    #print(node.fy)

for element in m.get_elements():
    ## force

    # Force in this element, given by
    #         f = \frac{EA}{L}\begin{bmatrix} C & S & -C & -S \end{bmatrix}\left\{u\right\}
    #     where:
    #         * E - Elastic modulus
    #         * A - Cross-section
    #         * L - Length
    #         * C - :math:`\cos(\theta)`
    #         * S - :math:`\sin(\theta)`
    #         * u - Four-element vector of nodal displacements -> :math:`\left\{ ux_i; uy_i; ux_j; uy_j \right\}`

    # print(element.f)

    ## stress
    """
    Stress in this element, given by:
        s = f/A
    where:
        * f = Force
        * A = Cross-section area
    """
    #print(element.s)

m.plot_deformed_shape()
NusaPlus.plot_deformed_shape_stress(m)
m.simple_report()
pyplot.show()
# '''

## Example 2
'''
E,A = 200e9, 0.01
n1 = Node((0,0))
n2 = Node((6,0))
n3 = Node((6,4))
n4 = Node((3,4))
e1 = Truss((n1,n2),E,A)
e2 = Truss((n2,n3),E,A)
e3 = Truss((n4,n3),E,A)
e4 = Truss((n1,n4),E,A)
e5 = Truss((n2,n4),E,A)
m = TrussModel()
for n in (n1,n2,n3,n4): m.add_node(n)
for e in (e1,e2,e3,e4,e5): m.add_element(e)
m.add_constraint(n1, uy=0)
m.add_constraint(n3, ux=0, uy=0)
m.add_force(n2, (600,0))
m.add_force(n4, (0,-400))
m.plot_model()
m.solve()
m.plot_deformed_shape()
plot_deformed_shapeX(m)
m.simple_report()
pyplot.show()
'''

## Example 3
'''
E,A = 29e6, 0.1
n1 = Node((0,0)) # A
n2 = Node((8*12,6*12)) # B
n3 = Node((8*12,0)) # C
n4 = Node((16*12,8*12+4)) # D
n5 = Node((16*12,0)) # E
n6 = Node((24*12,6*12)) # F
n7 = Node((24*12,0)) # G
n8 = Node((32*12,0)) # H

e1 = Truss((n1,n2),E,A)
e2 = Truss((n1,n3),E,A)
e3 = Truss((n2,n3),E,A)
e4 = Truss((n2,n4),E,A)
e5 = Truss((n2,n5),E,A)
e6 = Truss((n3,n5),E,A)
e7 = Truss((n5,n4),E,A)
e8 = Truss((n4,n6),E,A)
e9 = Truss((n5,n6),E,A)
e10 = Truss((n5,n7),E,A)
e11 = Truss((n6,n7),E,A)
e12 = Truss((n6,n8),E,A)
e13 = Truss((n7,n8),E,A)

m = TrussModel("Gambrel Roof")
for n in (n1,n2,n3,n4,n5,n6,n7,n8): m.add_node(n)
for e in (e1,e2,e3,e4,e5,e6,e7,e8,e9,e10,e11,e12,e13): m.add_element(e)

m.add_constraint(n1, uy=0)
m.add_constraint(n8, ux=0, uy=0)
m.add_force(n2, (0,-600))
m.add_force(n4, (0,-600))
m.add_force(n6, (0,-600))
m.add_force(n8, (0,-300))
m.add_force(n1, (0,-300))
m.plot_model()
plot_model_thickness(m)
m.solve()
m.plot_deformed_shape()
plot_deformed_shape_stress(m)
m.simple_report()
pyplot.show()
'''
