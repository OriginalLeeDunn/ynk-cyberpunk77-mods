# blender-5.0.1\blender.exe --background --python build_v_rig.py
# Builds ONE working rig of V (male): body + arms on the 167-bone body skeleton, face rig parented to the Head bone.
# Saves C:\Modding\work\blender\V_rig.blend and renders a rest pose and a test pose to prove the skinning follows the bones.
import bpy, os, math, mathutils
RAW = r"C:\Modding\work\vbody\raw\base\characters"
BODY = RAW + r"\common\player_base_bodies\player_man_average\t0_000_pma_base__full.glb"
ARMS = RAW + r"\common\player_base_bodies\player_man_average\arms_hq\a0_001_pma_base_hq__full.glb"
HEAD = RAW + r"\head\player_base_heads\player_man_average\h0_000_pma_c__basehead\h0_000_pma_c__basehead.glb"
OUT = r"C:\Modding\work\blender"; os.makedirs(OUT, exist_ok=True)
for o in list(bpy.data.objects): bpy.data.objects.remove(o, do_unlink=True)
def load(path):
    before = set(bpy.data.objects); d, n = os.path.split(path)
    bpy.ops.io_scene_gltf.cp77(filepath=path, directory=d + os.sep, files=[{"name": n}], image_format="png", hide_armatures=False)
    new = [o for o in bpy.data.objects if o not in before and not o.name.startswith("Icosphere")]
    for o in list(bpy.data.objects):
        if o.name.startswith("Icosphere"): bpy.data.objects.remove(o, do_unlink=True)
    return [o for o in new if o.name in bpy.data.objects]
body = load(BODY); arms = load(ARMS); head = load(HEAD)
body_arm = next(o for o in body if o.type == "ARMATURE"); body_arm.name = "V_body_rig"
# --- bind the arm meshes to the body skeleton (same bone names) and drop the duplicate armature
arm_arm = next(o for o in arms if o.type == "ARMATURE")
missing = []
for m in [o for o in arms if o.type == "MESH"]:
    for md in m.modifiers:
        if md.type == "ARMATURE": md.object = body_arm
    m.parent = body_arm; m.matrix_parent_inverse = body_arm.matrix_world.inverted()
    missing += [vg.name for vg in m.vertex_groups if vg.name not in body_arm.data.bones]
    m.name = "V_arms_" + m.name.split("_")[-3] if m.name.startswith("submesh") else m.name
bpy.data.objects.remove(arm_arm, do_unlink=True)
print("arm vertex groups missing from body skeleton:", sorted(set(missing))[:10], "(count %d)" % len(set(missing)))
# --- face rig follows the Neck bone (the body skeleton ends at Neck; the Head bone belongs to the face rig)
face_arm = next(o for o in head if o.type == "ARMATURE"); face_arm.name = "V_face_rig"
hb = body_arm.data.bones["Neck"]
mw = face_arm.matrix_world.copy()                       # Blender parents to the bone TAIL, so keep the world position explicitly
face_arm.parent = body_arm; face_arm.parent_type = "BONE"; face_arm.parent_bone = "Neck"
face_arm.matrix_parent_inverse = mathutils.Matrix.Identity(4)
bpy.context.view_layer.update()
face_arm.matrix_world = mw
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, "V_rig.blend"))
meshes = [o for o in bpy.data.objects if o.type == "MESH"]
print("meshes:", len(meshes), " body bones:", len(body_arm.data.bones), " face bones:", len(face_arm.data.bones))
# --- camera + render helpers
sc = bpy.context.scene; sc.render.engine = "BLENDER_WORKBENCH"; sc.render.resolution_x = 900; sc.render.resolution_y = 1100
sc.display.shading.light = "STUDIO"; sc.display.shading.color_type = "SINGLE"; sc.display.shading.single_color = (0.75, 0.78, 0.85)
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam; cam.data.lens = 50
def shoot(name, dirv):
    dg = bpy.context.evaluated_depsgraph_get(); pts = []
    for m in meshes:
        me = m.evaluated_get(dg); pts += [m.matrix_world @ mathutils.Vector(c) for c in me.bound_box]
    mn = mathutils.Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts))); mx = mathutils.Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    ctr = (mn + mx) / 2; h = (mx - mn).length
    cam.location = ctr + mathutils.Vector(dirv).normalized() * h * 1.4; cam.rotation_euler = (ctr - cam.location).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = os.path.join(OUT, name); bpy.ops.render.render(write_still=True)
shoot("V_rig_rest.png", (0, 1, 0.05))          # V faces +y in this export, so shoot from +y to see the front
# --- pose test: rotate some bones and prove the mesh follows
bpy.context.view_layer.objects.active = body_arm; bpy.ops.object.mode_set(mode="POSE")
pb = body_arm.pose.bones
def rot(name, euler_deg, mode="XYZ"):
    if name not in pb: print("no bone", name); return
    b = pb[name]; b.rotation_mode = mode; b.rotation_euler = [math.radians(a) for a in euler_deg]
POSE = {"LeftArm": (0, 0, -60), "RightArm": (0, 0, 60), "LeftForeArm": (0, 0, -35), "Neck": (0, 20, 0), "LeftUpLeg": (-35, 0, 0), "Spine1": (0, 10, 0)}
for n, e in POSE.items(): rot(n, e)
bpy.ops.object.mode_set(mode="OBJECT")
shoot("V_rig_posed.png", (0, 1, 0.05)); shoot("V_rig_posed_side.png", (1, 0, 0.05))
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, "V_rig_posed_test.blend"))
print("DONE")

