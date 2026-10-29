# YNK REDmod 2.5 Deploy Fix

Since Cyberpunk 2077 patch 2.5, every REDmod deploy that includes scripts fails at
`Stage 2/5 - Script Compilation`:

```
ScriptCompiler: ERROR: Imported classes (like 'ISerializable') must derive from something.
ERROR: Script compilation has failed!
```

It isn't your mods. It happens with an empty test mod too. The script sources that the REDmod DLC ships in
`tools\redmod\scripts` don't compile with REDmod's own compiler:

| File | Problem | Fix |
|---|---|---|
| `mods\codeware\callbackSystem.script` | Declares the engine's root class `ISerializable` as an imported class with no parent; the compiler only allows that for `IScriptable`. Giving it a parent compiles but the game then refuses to start (`Native class 'ISerializable' has declared base class ... that is different`). | Removes the `ISerializable` and `CResource` declarations and the two `ResourceEvent` members that return a `CResource`. |
| `cyberpunk\UI\fullscreen\tarot\tarot_main.script` | Passes a `ref< inkCompoundRef >` parameter to `inkWidgetRef.Get` (`Unable to convert from '&script_ref<inkCompoundRef>' to 'inkWidgetRef'`). | Takes the parameter by value. An `inkCompoundRef` is a handle to a widget, so the copy refers to the same widget. |
| `cyberpunk\UI\inventory\inventoryItemMode.script` | Same as above. | Same. |

The only thing REDmod scripts lose is `ResourceEvent.GetResource()` / `.resource` (`GetPath()` stays).
Nothing in the game's own scripts uses them.

**Compared with the workarounds going around:** turning off REDmod deployment, or copying the vanilla
`final.redscripts` into `r6\cache\modded`, gets the game to start, but REDmod mods' script changes don't
apply. This fixes the compile itself, so REDmod script mods work again.

## Use
1. Download `Fix-REDmod-Deploy.ps1` from the [release](https://github.com/OriginalLeeDunn/ynk-cyberpunk77-mods/releases/tag/redmod-deploy-fix-v1.0.0)
   or [Nexus Mods](https://www.nexusmods.com/cyberpunk2077/mods/36429).
2. Right-click it > **Run with PowerShell**, or from a PowerShell window:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\Fix-REDmod-Deploy.ps1
   ```
   It finds Steam, GOG and Epic installs by itself. For another folder:
   `-GamePath "D:\Games\Cyberpunk 2077"`.
3. Deploy again from the launcher or your mod manager (Vortex, MO2).

To undo: run it again with `-Undo`. It restores the original files from the `*.ynkfix-backup` copies
it keeps next to each one.

The script:
- edits the files in place and ships no CDPR files;
- backs up each file before changing it;
- is safe to run twice (already-fixed files are skipped);
- skips a file and warns if its contents don't match (for example, if CDPR fixes it in a later patch).

If you run `redMod.exe` yourself, also pass
`-rttiSchemaPath "<game>\tools\redmod\metadata.json"`: its default path is relative to the current
folder, and from the wrong folder deploy can't find the type schema.

## Tested
Cyberpunk 2077 2.5 (Steam), REDmod 2.5:
- Deploy of a REDmod script mod fails before the fix and succeeds after it.
- With mods enabled (`-modded`), the game reaches the main menu and loads a save.
- A REDmod test mod that overrides `player.script` and adds a new class runs in-game: its on-screen
  message appears after the save loads.
- `-Undo` restores files identical to the originals; running the fix twice changes nothing.

## Changelog
- **1.0.0**: first release.
