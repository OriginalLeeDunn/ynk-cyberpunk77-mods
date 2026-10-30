import bpy, os
p = r"C:\Modding\work\vbody\raw\base\characters\common\player_base_bodies\player_man_average\t0_000_pma_base__full.glb"
for o in list(bpy.data.objects): bpy.data.objects.remove(o, do_unlink=True)
d, n = os.path.split(p); bpy.ops.io_scene_gltf.cp77(filepath=p, directory=d + os.sep, files=[{"name": n}], image_format="png", hide_armatures=False)
a = next(o for o in bpy.data.objects if o.type == "ARMATURE"); bs = a.data.bones
roots = [b.name for b in bs if b.parent is None]; print("ROOTS", roots)
def tree(b, depth=0, out=[]):
    if depth <= 6 and not b.name.startswith(("l_J_", "r_J_", "mid_J_")) and "Twist" not in b.name and "JNT" not in b.name: out.append("  " * depth + b.name)
    for c in b.children: tree(c, depth + 1, out)
    return out
for r in roots: print("\n".join(tree(bs[r])[:70]))
print("ALLNAMES", [b.name for b in bs if not b.name.startswith(("l_J_", "r_J_"))][:60])
