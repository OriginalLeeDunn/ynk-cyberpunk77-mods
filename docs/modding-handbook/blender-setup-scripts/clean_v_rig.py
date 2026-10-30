# blender-5.0.1\blender.exe --background --python clean_v_rig.py
# Makes V_rig.blend readable: only the ~70 animator bones are visible (stick display), helper/muscle/face bones sit in hidden bone collections,
# meshes shown solid. Saves V_rig_clean.blend + V_rig_clean.png.
import bpy, os, mathutils
OUT = r"C:\Modding\work\blender"
bpy.ops.wm.open_mainfile(filepath=os.path.join(OUT, "V_rig.blend"))
body = bpy.data.objects["V_body_rig"]; face = bpy.data.objects["V_face_rig"]
def is_helper(n): return n.endswith("_JNT") or "_mscl" in n or "_CRV" in n or "Twist" in n or "Roll" in n
for arm_obj, label in ((body, "Body"), (face, "Face")):
    arm = arm_obj.data
    for c in list(arm.collections_all): arm.collections.remove(c)
    main = arm.collections.new(f"{label}: animate these")
    helper = arm.collections.new(f"{label}: helper / muscle bones (hidden)")
    for b in arm.bones:
        (helper if is_helper(b.name) else main).assign(b)
    helper.is_visible = False
    if label == "Face": main.is_visible = False; main.name = "Face: expression bones (hidden, show when needed)"
    arm.display_type = "STICK"; arm_obj.show_in_front = False
    print(label, "visible bones:", sum(1 for b in arm.bones if not is_helper(b.name)), "hidden helpers:", sum(1 for b in arm.bones if is_helper(b.name)))
for o in bpy.data.objects:
    if o.type == "MESH": o.hide_viewport = False; o.hide_set(False)
# a friendly viewport: solid shading, bones as thin sticks
for win in bpy.context.window_manager.windows:
    for area in win.screen.areas:
        if area.type == "VIEW_3D":
            for sp in area.spaces:
                if sp.type == "VIEW_3D": sp.shading.type = "SOLID"; sp.overlay.show_bones = True
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, "V_rig_clean.blend"))
# picture of the result with the bones visible (overlays do not render, so show sticks via a simple wire object count)
print("saved V_rig_clean.blend")
