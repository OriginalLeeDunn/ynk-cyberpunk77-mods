# Used by `red blender check`. Prints lines starting with "HC " so the terminal can show them.
import bpy, os
print("HC Blender", bpy.app.version_string)
loaded = list(bpy.context.preferences.addons.keys())
for mod in ("i_scene_cp77_gltf", "mcp_for_blender"):
    print("HC add-on", mod, "ENABLED" if mod in loaded else "NOT ENABLED")
print("HC CP77 importer (io_scene_gltf.cp77):", hasattr(bpy.ops.io_scene_gltf, "cp77"))
print("HC CP77 exporters:", [o for o in dir(bpy.ops.export_scene) if "cp77" in o])
print("HC rig file V_rig_clean.blend:", os.path.exists(r"C:\Modding\work\blender\V_rig_clean.blend"))
