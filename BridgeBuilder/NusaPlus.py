# This file modifies some of Nusa's functions. New functionality is added, like
# plotting models showing stresses and proportions between areas and forces.

from nusa import *
import matplotlib.cm as cm
import matplotlib.markers as markers
import math
import sys

#from .core import Element, Node, Model

# Plots deformed shape of a truss model and colors the elements according to
# their stresses. A color bar scale still needs to be added.
def plot_deformed_shape(truss_model, deform_factor=1.0, is_proportional=True, shows_stresses=False, maximum_stress=0, fixed_frame=[]):
    import matplotlib.pyplot as plt
    fig = plt.figure()
    ax = fig.add_subplot(111)

    df = deform_factor*truss_model._calculate_deformed_factor()
    #cmap = cm.get_cmap('jet') #'RdBu', 'coolwarm' is diverging with 0 on color value 0.5
    cmap = cm.get_cmap('cool') #'plasma', 'cool'
    #cmap = cm.get_cmap('viridis')

    def get_abs_stress(element):
        return abs(element.s)
    if maximum_stress != 0:
        maxStress = maximum_stress
    else:
        stresses = list(map(get_abs_stress,truss_model.get_elements()))
        maxStress = max(stresses)

    def get_area(element: Truss):
        return element.A
    crossAreas = list(map(get_area,truss_model.get_elements()))
    minArea = min(crossAreas)

    #set this for best visuals.
    thinnestLine = 1.5
    norm = mpl.colors.Normalize(vmin=-maxStress, vmax=maxStress)
    #colorbar = fig.colorbar(cm.ScalarMappable(norm=norm, cmap=cmap), ax=ax, orientation="vertical", shrink=0.713)
    #colorbar.ax.set_ylabel("Streess")
    colorbar = fig.colorbar(cm.ScalarMappable(norm=norm, cmap=cmap), ax=ax, orientation="horizontal", shrink=0.782)
    colorbar.ax.set_xlabel("Stress (Pa)")

    # Add lines out of sight for the legend.

    ax.plot([9999999,9999999],[9999999,9999999],'-', color='gray', label='Original', linewidth=1.5)
    ax.plot([9999999,9999999],[9999999,9999999],'--', color=cmap(0.5), label='Deformed', linewidth=1.5)
    ax.legend(loc='upper left')
    
    for elm in truss_model.get_elements():

        #sqrt because we display thickness, which is proportional to sqrt of area.
        #it would be ok to drop sqrt in order to exagerate the visual difference.
        widthMultiplier = 1
        if is_proportional:
            widthMultiplier = math.sqrt(elm.A/minArea)
        lineWidth = thinnestLine * widthMultiplier

        ni,nj = elm.get_nodes()
        x, y = [ni.x,nj.x], [ni.y,nj.y]
        xx = [ni.x+ni.ux*df, nj.x+nj.ux*df]
        yy = [ni.y+ni.uy*df, nj.y+nj.uy*df]

        ##maxStress -> color 1 or -1; 0 stress -> color 0.5
        #colorValue = elm.s * 0.5 / maxStress

        ##maxStress -> color 1; 0 stress -> color 0

        color = 'red'
        markerColor = 'red'
        if shows_stresses:
            colorValue = elm.s / (2*maxStress) + 0.5
            color = cmap(colorValue)
            markerColor = 'blue'

        #ax.plot(x, y, 'o', color='gray', zorder=10)
        ax.plot(xx, yy, 'bo', markerfacecolor = markerColor, markeredgecolor=markerColor, zorder=11)
        ax.plot(x,y,'-', color='gray', linewidth=lineWidth, zorder=1)
        ax.plot(xx,yy,'--', color=color, linewidth=lineWidth, zorder=2)

        for nd in (ni,nj):
            if nd.ux == 0 and nd.uy == 0:
                # Plots two triangles instead of a single marker for double
                # constraint using.
                #_draw_constraint(truss_model, ax,nd.x,nd.y)
                _draw_xconstraint(truss_model, ax,nd.x,nd.y)
                _draw_yconstraint(truss_model, ax,nd.x,nd.y)
            else:
                if nd.ux == 0: _draw_xconstraint(truss_model, ax,nd.x,nd.y)
                if nd.uy == 0: _draw_yconstraint(truss_model, ax,nd.x,nd.y)

    if fixed_frame:
        plt.xlim((fixed_frame[0], fixed_frame[1]))
        plt.ylim((fixed_frame[2], fixed_frame[3]))
        plt.gca().set_aspect('equal', adjustable='box')
    else:
        x0,x1,y0,y1 = truss_model.rect_region()
        plt.xlim((x0,x1))
        plt.ylim((y0,y1))
        plt.axis('equal')

    return fig

# Plots truss model with proportional thicknessess and proportial forces arrows.
def plot_model(truss_model, is_proportional=True, fixed_frame=[]):
    import matplotlib.pyplot as plt
    plt.tight_layout(pad=1.3)
    fig = plt.figure()
    ax = fig.add_subplot(111)

    def get_force(node: Node):
        return (node.fx, node.fy)
    forces = list(map(get_force,truss_model.get_nodes()))
    forces = [component for force in forces for component in force]

    #removes zeros from list
    forces = [i for i in forces if i != 0]
    minForce = abs(min(forces, default=1, key=abs))

    def get_area(element: Truss):
        return element.A
    crossAreas = list(map(get_area,truss_model.get_elements()))
    minArea = min(crossAreas, default=1)

    #set this for best visuals.
    thinnestLine = 1.5

    for elm in truss_model.get_elements():
        ni, nj = elm.get_nodes()

        #sqrt because we display thickness, which is proportional to sqrt of area.
        #it is ok to drop sqrt in order to exagerate the visual difference.
        widthMultiplier = 1
        if is_proportional:
            widthMultiplier = math.sqrt(elm.A/minArea)
        lineWidth = thinnestLine * widthMultiplier

        ax.plot([ni.x,nj.x],[ni.y,nj.y], 'bo', zorder=10)
        ax.plot([ni.x,nj.x],[ni.y,nj.y],"b-", linewidth=lineWidth, zorder=1)

        for nd in (ni,nj):
            fxMultiplier = 1
            if nd.fx == 0: fxMultiplier = 0
            if nd.fx < 0: fxMultiplier = -1
            fyMultiplier = 1
            if nd.fy == 0: fyMultiplier = 0
            if nd.fy < 0: fyMultiplier = -1

            if is_proportional:
                fxMultiplier = nd.fx/minForce
                fyMultiplier = nd.fy/minForce
            if nd.fx != 0 or nd.fy != 0: _draw_force(truss_model,ax,nd.x,nd.y,fxMultiplier,fyMultiplier)

            if nd.ux == 0 and nd.uy == 0:
                # Plots two triangles instead of a single marker for double
                # constraint using.
                #_draw_constraint(truss_model, ax,nd.x,nd.y)
                _draw_xconstraint(truss_model, ax,nd.x,nd.y)
                _draw_yconstraint(truss_model, ax,nd.x,nd.y)
            else:
                if nd.ux == 0: _draw_xconstraint(truss_model, ax,nd.x,nd.y)
                if nd.uy == 0: _draw_yconstraint(truss_model, ax,nd.x,nd.y)

    if fixed_frame:
        plt.xlim((fixed_frame[0], fixed_frame[1]))
        plt.ylim((fixed_frame[2], fixed_frame[3]))
        plt.gca().set_aspect('equal', adjustable='box')
    else:
        x0,x1,y0,y1 = truss_model.rect_region()
        plt.xlim((x0,x1))
        plt.ylim((y0,y1))
        plt.axis('equal')

    return fig

'''
# Plots deformed shape of a truss model and colors the elements according to
# their stresses. A color bar scale still needs to be added.
def plot_deformed_shape_stress(truss_model,dfactor=1.0):
    import matplotlib.pyplot as plt
    fig = plt.figure()
    ax = fig.add_subplot(111)

    df = dfactor*truss_model._calculate_deformed_factor()
    cmap = cm.get_cmap('jet') #'RdBu' is diverging with 0 on color value 0.5

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
'''

'''
# Plots truss model with proportional thicknessess.
def plot_proportional_area_model(truss_model: TrussModel):
    import matplotlib.pyplot as plt

    fig = plt.figure()
    ax = fig.add_subplot(111)

    def get_area(element: Truss):
        return element.A
    crossAreas = list(map(get_area,truss_model.get_elements()))
    minArea = min(crossAreas)

    #set this for best visuals.
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
'''

def _draw_force(truss_model,axes,x,y,fxMultiplier,fyMultiplier):
    minArrowSize = _calculate_arrow_size(truss_model)
    HW = minArrowSize/5.0
    HL = minArrowSize/3.0
    arrow_props = dict(head_width=HW, head_length=HL, fc='r', ec='r', zorder=5)
    axes.arrow(x, y, fxMultiplier*minArrowSize, fyMultiplier*minArrowSize, **arrow_props)

def _draw_xconstraint(truss_model,axes,x,y):
    if x<=0:
        axes.plot(x, y, marker = markers.CARETRIGHT, color = "green", markersize=10, alpha=0.6, zorder=20)
    else :
        axes.plot(x, y, marker = markers.CARETLEFT, color = "green", markersize=10, alpha=0.6, zorder=20)

def _draw_yconstraint(truss_model,axes,x,y):
    if y<=0:
        axes.plot(x, y, marker = markers.CARETUP, color = "green", markersize=10, alpha=0.6, zorder=20)
    else:
        axes.plot(x, y, marker = markers.CARETDOWN, color = "green", markersize=10, alpha=0.6, zorder=20)

def _draw_constraint(truss_model,axes,x,y):
    marker = "X" # Books sometimes use: markers.CARETUP
    axes.plot(x, y, marker = marker, color = "green", markersize=10, alpha=0.6)

def _calculate_arrow_size(truss_model):
    x0,x1,y0,y1 = truss_model.rect_region(factor=10)
    sf = 5e-2
    kfx = sf*(x1-x0)
    kfy = sf*(y1-y0)
    return np.mean([kfx,kfy])

# Detects is an input truss model is solvable by checking if the K2S (stiffness
# matrix has a non-huge or non-infinite condition number. If the condition number
# is not huge or infinite, then the structure is well behaved. The matrix has
# non-zero determinant and its inverse can be computed.
#
# If the condition number of the matrix is a huge number or infinite, then the
# matrix is ill-behaved. The matrix is non-reversable, its determinant is zero and
# it's called singular. In this case, it is not solvable because the truss is
# probably not stable/rigid.
#
# -- From: Basics of Finite Element Method — Direct Stiffness Method Part 1 --
# "The attribute that stiffness matrix is symmetric comes from the Maxwell’s
# Reciprocal Theorem which states that for any linear elastic body, displacement
# produced at any point A due to certain load applied at point B should be equal
# to displacement produced at point B when same load is applied at Point A.
#
# Since we have assumed the truss member to be linear elastic, the Maxwell’s
# Reciprocal Theorem applies here and hence the stiffness matrix is symmetric.
# This, however, is not always true! The stiffness matric tends to get
# un-symmetric when material behaves in-elastically or has local instability,
# for example in problems involving damage and failure."
# -- End of quote.
#
# The code for this function is extracted from the beginning of the _experimental.py
# solve() function. There, la.solve(self.K2S,self.F2S) can throw an error if the first
# parameter is a singular or non square matrix.
def isModelSolvable(trussModel):
    trussModel.VU = [node[key] for node in trussModel.U.values() for key in ("ux","uy")]
    trussModel.VF = [node[key] for node in trussModel.F.values() for key in ("fx","fy")]
    knw = [pos for pos,value in enumerate(trussModel.VU) if not value is np.nan]
    trussModel.K2S = np.delete(np.delete(trussModel.KG,knw,0),knw,1)

    if la.cond(trussModel.K2S) < 1/sys.float_info.epsilon:
        return True
    else:
        return False
