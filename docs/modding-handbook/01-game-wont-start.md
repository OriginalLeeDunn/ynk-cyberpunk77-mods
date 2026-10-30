# 1. When the game won't start

The order things happen at launch decides what you see. Work from the earliest stage that failed.

| Stage | If it fails you see | Evidence |
|---|---|---|
| 0. RED4ext loader (`bin\x64\winmm.dll`) | Game starts with no mods, **no log** | no `red4ext\logs` file at all |
| 1. RED4ext loads plugins | Game closes or hangs, no box | `red4ext\logs\red4ext-*.log` ends on a `Loading plugin from ...` line with no `has been loaded` after it |
| 2. redscript compiles scripts | A box: **"REDScript compilation has failed"**, names the mod(s). Game then starts with **no script mods working** | `r6\logs\redscript_rCURRENT.log` has `[ERROR] [CODE] At <file>:<line>`; red4ext log has `scc invocation failed` |
| 3. Game runs | Crash to desktop | `CrashInfo.json` (see below), Windows Application event log |

## The healthy signature
A healthy RED4ext log has, in order: each plugin `has been loaded`, `RED4ext has been started`,
`scc invoked successfully, N source refs were registered`, `Modded scripts blob is set to ...r6\cache\final.redscripts.modded`,
and on exit `RED4ext has been shut down`. If the compiler library `engine\tools\scc_lib.dll` can't be loaded it says so
and falls back to the command-line compiler. The RED modding wiki's "scc invoked successfully" check matches what 2.5 writes.

## Where the evidence is
- RED4ext: `<game>\red4ext\logs\` (newest file)
- redscript: `<game>\r6\logs\redscript_rCURRENT.log`
- Cyber Engine Tweaks: `<game>\bin\x64\plugins\cyber_engine_tweaks\cyber_engine_tweaks.log`
- Last crash: `%LOCALAPPDATA%\CD Projekt Red\Cyberpunk 2077\CrashInfo.json` (patch, UTC time, seconds into the
  session, so a crash at 20 seconds is a startup crash, not gameplay)
- Crash with no log: Windows Event Viewer, *Windows Logs > Application*, source *Application Error*, the
  "Faulting module name" is the dll that crashed

## A broken script mod is loud, not silent
We planted a mod calling a method that doesn't exist on 2.5. Result: the compilation box above, the exact file,
line and `method 'X' not found on 'PlayerPuppet'` in the redscript log. If your game closes **with no box and
no log**, the failure is before stage 2: a plugin dll (stage 1), a graphics hook next to the exe
(`dxgi.dll` from ReShade/OptiScaler), or a missing/blocked loader (stage 0, check antivirus quarantine).

## Two mods, one method name
`@addMethod(PlayerPuppet)` with the same method name in two mods makes the compiler reject all redscript mods.
Authors: prefix every method and class you add (we use `YnkCanto...`). Users: the Mod Doctor lists such pairs.

## Redscript mods and the native mod.io path do not mix
On PC with RED4ext, redscript compiles its own script blob and the game then ignores scripts in `r6\c77\<Mod>\`
(the folder native mod.io script mods live in). We saw a native mod never load until RED4ext's redscript step was
disabled. That is why a mod published for both should be installed as **one edition, not both**.

## Run the Mod Doctor
It automates all of the above: [tools/cp77-mod-doctor](../../tools/cp77-mod-doctor/).
