# Run with:  blender-5.0.1\blender.exe --background --python install_addon.py
# Installs the Cyberpunk IO Suite into the PORTABLE Blender 5.0.1 and enables it. Safe to re-run.
import bpy, os, sys, zipfile, shutil, addon_utils
ZIP = r"C:\Modding\downloads\Cyberpunk-Blender-Add-On-2.0.0.zip"
MOD = "i_scene_cp77_gltf"
scripts = bpy.utils.user_resource('SCRIPTS', create=True)
addons = os.path.join(scripts, "addons"); os.makedirs(addons, exist_ok=True)
print("user scripts dir:", scripts)
target = os.path.join(addons, MOD)
if os.path.isdir(target): shutil.rmtree(target)
with zipfile.ZipFile(ZIP) as z: z.extractall(addons)
print("extracted to", target, "exists:", os.path.isdir(target))
addon_utils.modules_refresh()
try:
    mod = addon_utils.enable(MOD, default_set=True, persistent=True)
    print("enabled:", bool(mod), "version:", getattr(mod, "bl_info", {}).get("version") if mod else None)
except Exception as e:
    print("ENABLE FAILED:", repr(e))
bpy.ops.wm.save_userpref()
print("loaded addons:", [m for m in bpy.context.preferences.addons.keys() if "cp77" in m or "cyber" in m.lower()])
print("import ops:", [o for o in dir(bpy.ops.import_scene) if "cp77" in o.lower() or "cyber" in o.lower()])
print("export ops:", [o for o in dir(bpy.ops.export_scene) if "cp77" in o.lower() or "cyber" in o.lower()])
