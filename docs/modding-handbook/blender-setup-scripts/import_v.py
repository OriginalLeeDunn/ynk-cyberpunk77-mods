# blender-5.0.1\blender.exe --background --python import_v.py   -> C:\Modding\work\blender\V_body.blend + V_front.png / V_side.png
import bpy, os, math, mathutils
RAW = r"C:\Modding\work\vbody\raw\base\characters"
FILES = [RAW + r"\common\player_base_bodies\player_man_average\t0_000_pma_base__full.glb",
         RAW + r"\head\player_base_heads\player_man_average\h0_000_pma_c__basehead\h0_000_pma_c__basehead.glb"]
OUT = r"C:\Modding\work\blender"; os.makedirs(OUT, exist_ok=True)
for o in list(bpy.data.objects): bpy.data.objects.remove(o, do_unlink=True)
for f in FILES:
    d, n = os.path.split(f)
    r = bpy.ops.io_scene_gltf.cp77(filepath=f, directory=d + os.sep, files=[{"name": n}], image_format="png", hide_armatures=False)
    print("IMPORT", n, r)
arms = [o for o in bpy.data.objects if o.type == "ARMATURE"]; meshes = [o for o in bpy.data.objects if o.type == "MESH" and not o.name.startswith("Icosphere")]
for o in bpy.data.objects:
    if o.name.startswith("Icosphere"): bpy.data.objects.remove(o, do_unlink=True)
print("armatures:", [(a.name[:44], len(a.data.bones)) for a in arms])
for m in meshes: print("mesh", m.name[:46], "verts", len(m.data.vertices), "dims_m", [round(v, 2) for v in m.dimensions], "parent", (m.parent.name[:30] if m.parent else None), "vgroups", len(m.vertex_groups), "modifiers", [x.type for x in m.modifiers])
if arms:
    a = max(arms, key=lambda x: len(x.data.bones)); names = [b.name for b in a.data.bones]
    print("bones:", len(names)); print("first 30:", names[:30])
    key = [n for n in names if any(k in n.lower() for k in ("hips", "spine", "head", "neck", "upperarm", "thigh", "foot", "hand"))]
    print("key bones:", key[:24])
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, "V_body.blend"))
sc = bpy.context.scene; sc.render.engine = "BLENDER_WORKBENCH"; sc.render.resolution_x = 900; sc.render.resolution_y = 1100
sc.display.shading.light = "STUDIO"; sc.display.shading.color_type = "SINGLE"; sc.display.shading.single_color = (0.75, 0.78, 0.85)
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam
pts = [m.matrix_world @ mathutils.Vector(c) for m in meshes for c in m.bound_box]
mn = mathutils.Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts))); mx = mathutils.Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
ctr = (mn + mx) / 2; h = (mx - mn).length; print("overall bbox size", [round(v, 2) for v in (mx - mn)])
for name, dirv in (("front", (0, -1, 0.05)), ("side", (1, 0, 0.05))):
    cam.location = ctr + mathutils.Vector(dirv).normalized() * h * 1.5; cam.rotation_euler = (ctr - cam.location).to_track_quat("-Z", "Y").to_euler(); cam.data.lens = 50
    sc.render.filepath = os.path.join(OUT, f"V_{name}.png"); bpy.ops.render.render(write_still=True)
print("DONE")

