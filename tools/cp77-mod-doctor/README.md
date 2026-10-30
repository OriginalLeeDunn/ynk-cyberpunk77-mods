# YNK Cyberpunk 2077 Mod Doctor

A read-only PowerShell tool that works out **why a modded Cyberpunk 2077 won't start or is broken**, and tells
you which mod or file to look at. It is meant for the case where the game closes or won't launch and you can't
tell why, and for the first thing to run after a patch.

It never changes, moves or deletes anything in your game folder. With `-Compile` it recompiles your redscript
mods in a temp folder (on a copy), and the game files are byte-for-byte the same afterwards (tested).

## Use it
1. Close the game.
2. Download `Doctor.ps1`, right-click it, *Run with PowerShell*. Or from PowerShell:
   ```powershell
   .\Doctor.ps1                                   # finds the Steam / GOG / Epic install
   .\Doctor.ps1 -GamePath "D:\Games\Cyberpunk 2077"
   .\Doctor.ps1 -Compile                          # also recompile every redscript mod (about 20 s)
   .\Doctor.ps1 -Compile -ReportPath "$env:USERPROFILE\Desktop\doctor.txt"   # save a report to paste for help
   ```
   If PowerShell refuses to run it: `powershell -ExecutionPolicy Bypass -File .\Doctor.ps1`.

The result is a list ranked `FAIL` (stops the game or a mod), `WARN` (likely a problem) and `INFO`, each with
what it means and what to do.

## What it checks
| Check | Catches |
|---|---|
| Frameworks | RED4ext / redscript / TweakXL / ArchiveXL / Codeware / CET present; RED4ext's loader (`winmm.dll`) missing |
| RED4ext log | RED4ext never ran (no log), the game stopped **while loading a named plugin**, plugin errors/warnings, stopped before the script compiler finished, no normal shutdown |
| redscript log | every compile error grouped by mod with file and line; errors from mods you already removed are shown as old |
| Crash evidence (no log needed) | `CrashInfo.json` (crash patch, time, how long into the session), Windows "Application Error" events (faulting module) |
| Install problems | graphics hooks (`dxgi.dll`, ReShade, OptiScaler) next to the exe, leftover `cybercmd`, mod files in the game root, archives left in `r6\scripts` |
| Two mods, same method | the same `@addMethod` name on the same class in two mods (the compiler then rejects **all** redscript mods) |
| `-Compile` | recompiles everything against **this** game version and names the mod and line, even when the game's own log doesn't show it yet |

## What it can't do
- It can't see a failure that leaves no trace anywhere. If it reports nothing and the game still won't start,
  the cause is outside mods: verify game files, update GPU drivers, check antivirus quarantine.
- It doesn't check ArchiveXL asset conflicts, TweakXL record clashes, or Cyber Engine Tweaks Lua errors yet.
- It doesn't know which mods have a newer version on Nexus; it tells you which one is the problem.
- PC only. Console has no logs to read; see the [handbook](../../docs/modding-handbook/) for what breaks there.

## Why a broken script mod is not a "silent" failure
In testing on 2.5, a mod that doesn't compile does **not** make the game silently exit. It shows a
"REDScript compilation has failed" box that names the mod, writes the line to `r6\logs\redscript_rCURRENT.log`,
and the game then starts with **no script mods working**. A game that closes with no box and no log fails
earlier, in the RED4ext / plugin / graphics-hook stage, which is what the log-ending and crash-evidence checks
are for.

## Tests
`Test-Doctor.ps1` builds fake game folders in `%TEMP%` for each failure above and checks the report.

## Changelog
- **0.1.0**: first version.
