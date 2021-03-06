import json
import bpy
import numpy as np
from mathutils import Matrix, Vector
import sys

colors =[[0.19154,      0.78665,      0.56299],
          [ 1.0147,      0.31997,      0.20648],
          [0.24929,       0.4175,      0.87439],
          [0.18907,      0.61792,      0.73418],
          [0.19126,      0.50687,      0.84305],
          [0.20127,      0.55259,      0.78732],
          [0.35756,      0.34505,      0.83857],
          [0.22557,      0.28247,       1.0331],
          [0.13424,       1.0904,      0.31652],
          [0.66463,      0.19804,      0.67851],
          [0.19239,      0.44728,       0.9015],
          [0.95037,      0.20389,      0.38692],
          [0.77345,      0.61533,       0.1524],
          [0.30151,      0.34759,      0.89208],
          [0.99527,      0.17835,      0.36756],
          [0.27262,      0.94403,      0.32453],
          [0.18825,       0.3112,       1.0417],
          [0.75407,      0.21028,      0.57682],
          [0.95666,      0.21458,      0.36994],
          [0.70021,      0.64825,      0.19272],
          [0.83042,      0.24671,      0.46405],
          [0.15455,      0.70476,      0.68187],
          [0.88803,      0.13745,       0.5157],
          [0.84613,      0.33478,      0.36026],
          [0.21983,      0.75253,      0.56881],
          [  1.075,       0.2306,       0.2356],
          [0.80296,      0.20942,       0.5288],
          [0.58862,      0.75509,      0.19747],
          [0.35962,      0.32453,      0.85702],
          [0.83715,      0.45574,      0.24829],
          [0.31095,      0.40509,      0.82514],
          [0.16349,      0.99597,      0.38172],
          [0.49841,      0.90317,       0.1396],
          [0.18493,      0.42813,      0.92811],
          [ 1.0122,      0.33381,      0.19519],
          [ 1.0059,      0.27752,      0.25775],
          [0.78035,      0.24489,      0.51593],
          [ 0.1856,      0.43055,      0.92503],
          [0.59614,      0.81037,      0.13467],
          [0.19053,      0.37403,      0.97662],
          [0.49686,      0.84013,      0.20419],
          [0.23716,      0.82479,      0.47923],
          [0.25245,       1.0529,      0.23583],
          [0.81172,      0.57119,      0.15826],
          [0.27386,      0.43549,      0.83183],
          [0.56457,      0.20022,      0.77639],
          [0.61072,       0.1609,      0.76956],
          [0.67359,      0.19018,       0.6774],
          [0.84936,      0.31897,      0.37285],
          [0.23694,      0.98922,      0.31501],
          [0.59195,      0.75386,      0.19537],
          [0.74114,      0.17774,       0.6223],
          [0.16803,      0.18377,       1.1894],
          [0.27192,      0.93854,      0.33071],
          [0.91044,      0.46916,      0.16157],
          [0.23296,      0.96293,      0.34528],
          [0.25584,      0.31958,      0.96576],
          [0.83593,       0.5283,      0.17695],
          [0.44946,      0.21624,      0.87548],
          [0.32639,      0.22925,      0.98554],
          [0.67966,      0.70074,      0.16078],
          [0.82396,      0.55465,      0.16257],
          [0.68395,      0.65521,      0.20202],
          [0.80606,      0.46624,      0.26888],
          [ 1.0694,      0.23468,      0.23705],
          [0.94236,      0.24463,      0.35418],
          [ 0.6536,      0.20572,      0.68186],
          [0.22248,      0.74823,      0.57047],
          [ 0.3312,      0.89567,      0.31431],
          [ 0.4163,      0.19902,      0.92586],
          [0.94484,      0.35995,      0.23639],
          [0.19372,      0.93571,      0.41174],
          [0.85456,      0.45436,      0.23225],
          [0.40107,      0.15027,      0.98984],
          [0.76182,      0.16243,      0.61693],
          [0.41406,      0.26888,      0.85823],
          [0.67045,       0.2004,      0.67033],
          [0.51716,      0.19579,      0.82822],
          [ 0.4055,       0.1577,      0.97798],
          [0.58041,      0.77744,      0.18332],
          [0.56521,      0.80512,      0.17084],
          [0.54313,      0.77533,      0.22271],
          [0.19466,       1.1209,       0.2256],
          [0.22089,      0.50544,      0.81485],
          [0.83003,      0.48547,      0.22568],
          [0.51948,      0.84102,      0.18068],
          [0.73399,      0.60549,      0.20169],
          [0.23874,       1.0746,      0.22787],
          [0.16525,       1.1952,      0.18075],
          [ 0.1728,      0.58864,      0.77974],
          [0.20619,        1.026,      0.30902],
          [0.19089,      0.96096,      0.38932],
          [0.89927,      0.22296,      0.41894],
          [0.84827,      0.53326,      0.15964],
          [0.83217,      0.42953,      0.27948],
          [ 0.3344,      0.24005,      0.96673],
          [0.20283,      0.70141,      0.63694],
          [  0.901,      0.34352,      0.29666],
          [0.14355,      0.83488,      0.56275],
          [0.19705,      0.19373,       1.1504]]

def assign_mesh_color(agent_mesh, agent_json):
    i = int(agent_json["id"])
    color = colors[i]
    mat = bpy.data.materials.new('agent_material'+str(i))
    agent_mesh.data.materials.append(mat)
    agent_mesh.active_material = mat
    mat.use_nodes = True
    tree = mat.node_tree
    # set principled BSDF
    tree.nodes["Principled BSDF"].inputs['Base Color'].default_value = (color[0], color[1], color[2], 1)


def origin_to_bottom(ob, meshFU, matrix=Matrix()):
    me = ob.data
    mw = ob.matrix_world
    local_verts = [matrix @ Vector(v[:]) for v in ob.bound_box]
    o = sum(local_verts, Vector()) / 8
    if meshFU[0]=='X' or meshFU[0]=='-X':
      print("HERE HERE HERE")
      o.x = min(v.x for v in local_verts)
    elif meshFU[0]=='Y' or meshFU[0]=='-Y':
      print("HERE2 HERE2 HERE2")
      o.y = min(v.y for v in local_verts)
    else:
      print("HERE3 HERE3 HERE3")
      o.z = min(v.z for v in local_verts)
    o = matrix.inverted() @ o
    me.transform(Matrix.Translation(-o))
    mw.translation = mw @ o

def make_path_curve(name, coords_list):
    # make a new curve
    crv = bpy.data.curves.new('crv', 'CURVE')
    crv.dimensions = '3D'

    # make a new spline in that curve
    spline = crv.splines.new(type='POLY')

    # a spline point for each point
    spline.points.add(len(coords_list)-1) # theres already one point by default

    # assign the point coordinates to the spline points
    for p, new_co in zip(spline.points, coords_list):
        p.co = (new_co[0], new_co[1], new_co[2], 1) # (add nurbs weight)

    # make a new object with the curve
    obj = bpy.data.objects.new(name, crv)
    bpy.context.collection.objects.link(obj)
    return obj

def make_rod_curve(name, coords_list, r):
    # make a new curve
    crv = bpy.data.curves.new('crv', 'CURVE')
    crv.dimensions = '3D'

    # make a new spline in that curve
    spline = crv.splines.new(type='POLY')

    # a spline point for each point
    spline.points.add(len(coords_list)-1) # theres already one point by default

    # assign the point coordinates to the spline points
    for p, new_co in zip(spline.points, coords_list):
        p.co = (new_co[0], new_co[1], new_co[2], 1) # (add nurbs weight)

    # make a new object with the curve
    obj = bpy.data.objects.new(name, crv)
    bpy.context.collection.objects.link(obj)

    #extrude to cylinder
    bpy.ops.mesh.primitive_circle_add(radius=r, enter_editmode=False, align='WORLD', location=(0, 0, -20), scale=(1, 1, 1))
    bpy.context.object.select_set(True)
    # bpy.context.object.hide_viewport = True
    bpy.context.object.name = "circle-"+name;
    bpy.ops.object.convert(target='CURVE')
    obj.data.bevel_mode = "OBJECT"
    obj.data.bevel_object = bpy.data.objects["circle-"+name]
    # obj.hide_viewport = True
    return obj



# #------------------------
# # clear all
# bpy.ops.wm.read_factory_settings(use_empty=True)
# #------------------------

print(sys.argv)
render_rods = False
run_folder = "scaling_tests/10_agents/"#"eight_agents/agent_circle/"
project_folder = "/Users/vismay/recode/crowds/"
blend_materials_folder = project_folder+"Scenes/blend_material/"
scene_folder = project_folder + "Scenes/output_results/" + run_folder

bpy.ops.wm.open_mainfile(filepath=blend_materials_folder + "scene_bases/scaling_test_base.blend")

f = open(scene_folder+"agents.json", "r")
scene = json.loads(f.read())
f1 = open(blend_materials_folder + "agent_models/agent_list.json", "r")
agent_obj_list = json.loads(f1.read())

#load agents curves
for a in scene["agents"]:
    v = np.array(a["v"])
    
    x = np.around(v[:,0], decimals=2)
    y = np.around(v[:,1], decimals=2) 
    t = np.around(v[:,2], decimals=2)

    make_path_curve("Path-"+str(a["id"]), np.array([x, y, y*0], order='F').transpose())

#load agents rods
for a in scene["agents"]:
    v = np.array(a["v"])
    
    x = np.around(v[:,0], decimals=2)
    y = np.around(v[:,1], decimals=2) 
    t = np.around(v[:,2], decimals=2)

    r = float(a["radius"])
    rod = make_rod_curve("Rod-"+str(a["id"]), np.array([x, y, t], order='F').transpose(), r)
    assign_mesh_color(rod, a)

#load agents objects
for a in scene["agents"]:
    v = np.array(a["v"])
    
    x = np.around(v[:,0], decimals=2)
    y = np.around(v[:,1], decimals=2) 
    t = np.around(v[:,2], decimals=2)

    r = float(a["radius"])

    meshFU=["-Y", "Z"]
    if a["animation_cycles"]:
        print("use walk cycle")
         # Manually do this after keyframing
        # 1. Go into each walk cycle animation, disable the z-location 
        # 2. Rotate the agents to face the correct direction
        # 3. update walk cycle speed to match ground velocity
        bpy.ops.import_scene.fbx( filepath = "/Users/vismay/Downloads/Walking.fbx")
        obj_object = bpy.context.selected_objects[0]
    elif a["mesh"]:
        model = a["mesh"]
        #bpy.ops.import_scene.obj(filepath=blend_materials_folder+"agent_models/"+agent_obj_list[model]["file"])
        bpy.ops.import_scene.fbx( filepath = blend_materials_folder+"agent_models/"+agent_obj_list[model]["file"])
        meshFU = agent_obj_list[model]["orientation_forward_up"]
    else:
        print("use default unit cube")
        bpy.ops.mesh.primitive_cube_add(size=2, enter_editmode=False, align='WORLD', location=(0, 0, 0), scale=(1, 1, 1))

    obj_object = bpy.context.selected_objects[0] ####<--Fix
    for c in obj_object.children:
      assign_mesh_color(c, a)
    bpy.context.view_layer.objects.active = obj_object
    #origin_to_bottom(obj_object, meshFU, matrix=obj_object.matrix_world)
    # Keyframe the walk cycle along the path curve
    for k in range(len(t)):
        # print(int(100*x[k]),int(100*y[k]), int(100*t[k]))
        cur_frame = bpy.context.scene.frame_current
        if k < len(t)-1:
            direction_vector = Vector((x[k+1] - x[k], y[k+1] - y[k], 0))
            next_rot_euler = direction_vector.to_track_quat(meshFU[0], meshFU[1]).to_euler()
            curr_rot = obj_object.rotation_euler
            dx = next_rot_euler.x - curr_rot.x
            dy = next_rot_euler.y - curr_rot.y
            dz = next_rot_euler.z - curr_rot.z 
            
            if abs(dx) > 3.14159:
                print("go the other way")
                next_rot_euler.x += 1*(dx/dx)*(2*3.14159)
            if abs(dy) > 3.14159:
                print("go the other way")
                next_rot_euler.y += 1*(dy/dy)*(2*3.14159)
            if abs(dz) > 3.14159:
                print("go the other way")
                next_rot_euler.z += 1*(dz/dz)*(2*3.14159)

            obj_object.rotation_euler = (next_rot_euler.x, next_rot_euler.y, next_rot_euler.z)

            obj_object.keyframe_insert(data_path="rotation_euler", frame=int(10*t[k]))

        bpy.data.objects[obj_object.name].location = (x[k],y[k],0)
        obj_object.keyframe_insert(data_path="location", frame=int(10*t[k]))



#    #add cube to act as pseudo car to animate along path
#    # Import FBX

if(render_rods):
  bpy.ops.wm.save_mainfile(filepath=project_folder + "Scenes/Blends/" + run_folder + "with_rods.blend")
else:
  bpy.ops.wm.save_mainfile(filepath=project_folder + "Scenes/Blends/" + run_folder + "no_rods.blend")

exit()


    

