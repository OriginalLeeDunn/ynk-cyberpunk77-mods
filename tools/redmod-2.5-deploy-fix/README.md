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
| `mods\codeware\callbackSystem.script` | Declares the engine's root class `ISerializable` as an imported class with no parent; the compiler only allows that for `IScriptable`. | Gives it a parent so deploy succeeds. The game refuses to start with that parent, so the included RED4ext plugin clears it in the deployed scripts at every startup. |
| `cyberpunk\UI\fullscreen\tarot\tarot_main.script` | Passes a `ref< inkCompoundRef >` parameter to `inkWidgetRef.Get` (`Unable to convert from '&script_ref<inkCompoundRef>' to 'inkWidgetRef'`). | Takes the parameter by value. An `inkCompoundRef` is a handle to a widget, so the copy refers to the same widget. |
| `cyberpunk\UI\inventory\inventoryItemMode.script` | Same as above. | Same. |

Nothing is removed, so REDmod script mods and redscript mods such as Codeware work together.

**Compared with the workarounds going around:** turning off REDmod deployment, or copying the vanilla
`final.redscripts` into `r6\cache\modded`, gets the game to start, but REDmod mods' script changes don't
apply. This fixes the compile itself, so REDmod script mods work again.

## Requirements
- REDmod DLC.
- RED4ext, for the full fix. Without it you get a REDmod-only fix that isn't compatible with redscript
  mods. If you add RED4ext later, run the fix again.

## Use
1. Close the game and unpack the whole zip into a folder of its own.
2. Double-click `Run-Fix.bat`. The window stays open so you can read the result.
   It finds Steam, GOG and Epic installs by itself. For another folder, from a command prompt:
   `Run-Fix.bat -GamePath "D:\Games\Cyberpunk 2077"`.
3. Deploy again from the launcher or your mod manager (Vortex, MO2).

**Coming from 1.0.0:** do the same. 1.0.0 removed two classes that Codeware and other redscript mods need,
which caused `class 'ISerializable' not found` and `class 'CResource' not found`. This version replaces
that fix and removes the broken deployed scripts.

To undo: `Run-Fix.bat -Undo` from a command prompt. It restores the originals, removes the plugin and clears
`r6\cache\modded`.

**Don't remove the plugin on its own.** With the full fix in place, the game won't start with REDmod scripts
without it. Use `-Undo` instead.

The script:
- edits the files in place and ships no CDPR files;
- backs up each file before changing it;
- is safe to run twice (already-fixed files are skipped);
- removes `r6\cache\modded` when the fix changes, because REDmod reuses it otherwise;
- skips a file and warns if its contents don't match (for example, if CDPR fixes it in a later patch).

If you run `redMod.exe` yourself, also pass
`-rttiSchemaPath "<game>\tools\redmod\metadata.json"`: its default path is relative to the current
folder, and from the wrong folder deploy can't find the type schema.

## Manual fix (no script)
Prefer not to run a script? The fix is three small edits you can make in Notepad (or any text editor), in
`<game folder>\tools\redmod\scripts`. Copy each file somewhere safe first (that is your backup), make the
edit, save, then deploy again. Search for the text rather than going by line numbers: they can differ
slightly between REDmod versions. If a line doesn't look like the "before" text below, CDPR may have
already fixed that file and you can leave it alone.

**1. `cyberpunk\UI\inventory\inventoryItemMode.script`** (around line 696)

Find `CreateItemChooser( itemCategoryList : ref< inkCompoundRef >,` and change it to:

```
CreateItemChooser( itemCategoryList : inkCompoundRef,
```

**2. `cyberpunk\UI\fullscreen\tarot\tarot_main.script`** (around line 169)

Find `widgetRef : ref< inkCompoundRef > )` and change it to:

```
widgetRef : inkCompoundRef )
```

**3. `mods\codeware\callbackSystem.script`** (around lines 67-81)

Delete these two blocks:

```
importonly abstract class ISerializable
{
}

import abstract class CResource extends ISerializable
{
    import var cookingPlatform : ECookingPlatform;
}
```

Then, inside `ResourceEvent`, delete the two lines `import var resource : CResource;` and
`public import function GetResource() : CResource;` so that it reads:

```
import class ResourceEvent extends CallbackSystemEvent
{
    public import function GetPath() : ResRef;
}
```

To undo, copy your backups back over the edited files. (These are exactly the edits the script makes.)

## Tested
Cyberpunk 2077 2.5 (Steam), REDmod 2.5, RED4ext 1.31, redscript 0.5.32, Codeware 1.21.1, ArchiveXL, TweakXL, in the running game:
- A REDmod script mod and a redscript mod both run in the same session; 0 redscript errors; a save loads.
- Upgrade from 1.0.0, repeat launches, redeploying a changed mod, and launching without `-modded`.
- An empty, cut-off or random `final.redscripts` is left untouched and logged, and the game still runs.
- A read-only `final.redscripts` shows an explanation.
- `-Undo` restores files identical to the originals.
- REDmod-only mode deploys without RED4ext, and running again after adding RED4ext switches to the full fix.

Not tested: Epic and GOG installs, large mod lists, and `ResourceEvent.GetResource()` on a live event.

## Changelog
- **2.0.0**: fixes redscript and Codeware mods breaking after 1.0.0. Adds the `ynk_redmod_bridge` RED4ext plugin, `Run-Fix.bat`, and a pause so the window stays open.
- **1.0.0**: first release.
