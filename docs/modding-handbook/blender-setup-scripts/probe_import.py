import bpy, os
SRC = r"C:\Modding\work\unity-print\raw\base\weapons\firearms\handgun\constitutional_unity\entities\meshes\w_handgun__constitutional_unity__base1_01.glb"
for o in list(bpy.data.objects): bpy.data.objects.remove(o, do_unlink=True)
d, f = os.path.split(SRC)
try:
    r = bpy.ops.io_scene_gltf.cp77(filepath=SRC, directory=d + os.sep, files=[{"name": f}], image_format="png", hide_armatures=False)
    print("RESULT", r, "objects:", len(bpy.data.objects))
    for o in bpy.data.objects: print("  OBJ", o.name[:40], o.type, "verts", len(o.data.vertices) if o.type == "MESH" else "", "dims", [round(v, 3) for v in o.dimensions], "parent", o.parent.name[:20] if o.parent else None)
    print("materials", [m.name[:34] for m in bpy.data.materials][:6], "collections", [c.name[:30] for c in bpy.data.collections][:6])
except Exception as e: print("FAILED:", str(e)[:400].replace("\n", " | "))

