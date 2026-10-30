# 4. The dev environment (works without Claude)

Everything here is plain files, scripts and terminal commands on your own machines. The AI link (MCP) is an
optional extra on top; none of it is required.

## What is installed
| Tool | Where | Notes |
|---|---|---|
| Blender 5.0.1 (portable) | `C:\Modding\tools\blender-5.0.1` | Its own settings and add-ons live in its `portable` folder, so it never touches your Blender 5.2. The Cyberpunk add-on only vouches for 5.0. |
| Cyberpunk IO Suite 2.0.0 | inside that Blender | Imports and exports game GLB files, rigs and animations. |
| MCP for Blender 2.2.6 (add-on) | inside that Blender | Optional. Opens a socket on `127.0.0.1:9876` only. Telemetry is switched off in the Claude config. |
| WolvenKit 9.1.0 + CLI | `C:\Modding\tools\WolvenKit*` | Extracts game files. The CLI is what the `red extract` command uses. |
| The mod lab | `C:\Modding\Cyberpunk 2077` | Separate game copy for tests. Never put test files in the Steam / OPEN//77 install. |
| V's rig | `C:\Modding\work\blender\V_rig_clean.blend` | Male V body, arms, head and the 254-bone face rig (see below). |

## Terminal commands (in the Zed terminal; `ynk red` and `ynk print` show help)
```
red status                      what is installed and running
red blender v                   open V's rig in the pinned Blender
red blender check               headless health check (versions, add-ons, importer, exporters)
red bpy <script.py>             run a Blender Python script without opening a window
red link [json]                 talk to a running Blender over its local socket
red extract "<regex>" <name>    uncook game files to GLB with WolvenKit
red lab ... / red modio ...     the mod lab and the console (mod.io) lab
red doctor -c                   Mod Doctor with the compile check
print status                    printer state, progress, time left
print view <name>               open a sliced G-code preview
print models [name]             open the 3D model viewer (explode view)
print slice <stl> <name>        slice offline and make a preview (never queues a print)
```

## Safety rules
- The Blender socket executes Python inside Blender. It only listens on localhost, but treat it like a console: save first, and
  use it on lab files.
- Do not kill a program you did not start; ask first. Close only your own windows.
- Nothing in `print` starts or queues a print. Starting a print is always a manual decision in OctoPrint.
- Game-derived models (guns, the V rig) stay on your machines. The public site shows only your own and credited work.

## V's rig, what is in it
- Body skeleton: 167 bones with **Mixamo-style names** (`Hips`, `Spine`...`Spine3`, `LeftArm`, `LeftForeArm`, `LeftHand`, fingers,
  `LeftUpLeg`, `LeftLeg`, `LeftFoot`, `Neck`) plus muscle helper bones (`*_JNT`).
- Face rig: 254 bones, attached to the body's `Neck` bone. (Blender parents to a bone's tail, so parent, then restore the world matrix.)
- In `V_rig_clean.blend` only the animator bones are visible. The helper bones sit in hidden *bone collections*.
- Posing: select the rig, switch to Pose Mode, click a bone, `R` rotate, `Alt+R` reset. `I` inserts a keyframe.

## Exact steps to rebuild the rig from the game
```
red extract "player_man_average\\t0_000_pma_base__full\.mesh$" vbody
red extract "player_man_average\\arms_hq\\a0_001_pma_base_hq__full\.mesh$" vbody
red extract "h0_000_pma_c__basehead\\h0_000_pma_c__basehead\.mesh$" vbody
red bpy C:\Modding\tools\blender-setup\build_v_rig.py
red bpy C:\Modding\tools\blender-setup\clean_v_rig.py
```
