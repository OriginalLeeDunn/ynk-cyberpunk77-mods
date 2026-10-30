# blender-5.0.1\blender.exe --background --python roundtrip_test.py
import bpy, os, sys, time
SRC = r"C:\Modding\work\unity-print\raw\base\weapons\firearms\handgun\constitutional_unity\entities\meshes\w_handgun__constitutional_unity__base1_01.glb"
OUT = r"C:\Modding\work\blender"; os.makedirs(OUT, exist_ok=True)
ops = sorted({t.bl_rna.identifier for t in []})
cp = []
for modname in dir(bpy.ops):
    grp = getattr(bpy.ops, modname)
    for op in dir(grp):
        if "cp77" in op.lower() or "cyberpunk" in op.lower(): cp.append(f"bpy.ops.{modname}.{op}")
print("CP77 operators:", cp)
for o in list(bpy.data.objects): bpy.data.objects.remove(o, do_unlink=True)   # keep prefs/add-ons loaded
print("addon prefs loaded:", "i_scene_cp77_gltf" in bpy.context.preferences.addons, list(bpy.context.preferences.addons.keys())[:6])
t = time.time()
res = None
for name in ("import_scene.cp77", "io_scene_gltf.cp77", "import_scene.gltf"):
    grp, op = name.split(".")
    if hasattr(getattr(bpy.ops, grp, None), op):
        try:
            res = getattr(getattr(bpy.ops, grp), op)(filepath=SRC); print("import via", name, "->", res); break
        except Exception as e: print("import via", name, "failed:", repr(e)[:200])
print("import took %.1fs" % (time.time() - t))
objs = list(bpy.data.objects)
print("objects:", len(objs), [(o.name[:40], o.type) for o in objs][:8])
meshes = [o for o in objs if o.type == "MESH"]
for o in meshes[:4]:
    print("  mesh", o.name[:40], "verts", len(o.data.vertices), "polys", len(o.data.polygons), "materials", [m.name[:30] for m in o.data.materials][:3], "dims_m", [round(v, 3) for v in o.dimensions])
print("materials:", len(bpy.data.materials), " armatures:", len(bpy.data.armatures))
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, "unity_roundtrip.blend"))
# quick picture (workbench) so we can SEE it
try:
    sc = bpy.context.scene; sc.render.engine = "BLENDER_WORKBENCH"; sc.render.resolution_x = 1400; sc.render.resolution_y = 700
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam
    import mathutils
    from math import radians
    pts = [o.matrix_world @ mathutils.Vector(c) for o in bpy.data.objects if o.type == "MESH" and o.name.startswith("submesh") for c in o.bound_box]
    mn = mathutils.Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts))); mx = mathutils.Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    ctr = (mn + mx) / 2; size = (mx - mn).length
    cam.location = ctr + mathutils.Vector((0.9, -1.4, 0.5)).normalized() * size * 1.5
    cam.rotation_euler = (ctr - cam.location).to_track_quat("-Z", "Y").to_euler(); cam.data.lens = 50
    sc.display.shading.light = "STUDIO"; sc.display.shading.color_type = "OBJECT"
    sc.render.filepath = os.path.join(OUT, "unity_roundtrip.png"); bpy.ops.render.render(write_still=True); print("rendered png")
except Exception as e: print("render skipped:", repr(e)[:160])
for name in ("export_scene.cp77_glb",):
    grp, op = name.split(".")
    if hasattr(getattr(bpy.ops, grp, None), op):
        try:
            for o in bpy.data.objects: o.select_set(o.type == "MESH")
            r = getattr(getattr(bpy.ops, grp), op)(filepath=os.path.join(OUT, "unity_back.glb")); print("export via", name, "->", r)
        except Exception as e: print("export via", name, "failed:", repr(e)[:240])
print("files:", [(f, os.path.getsize(os.path.join(OUT, f))) for f in os.listdir(OUT)])
