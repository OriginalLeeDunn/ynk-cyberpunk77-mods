import bpy, addon_utils
addon_utils.modules_refresh()
m = addon_utils.enable("mcp_for_blender", default_set=True, persistent=True)
print("ENABLED", bool(m), (m.bl_info.get("name"), m.bl_info.get("version")) if m else None)
bpy.ops.wm.save_userpref()
print("ADDONS", [a for a in bpy.context.preferences.addons.keys() if "mcp" in a.lower() or "cp77" in a])
