# YNK Unity Edition

Two new Unity pistols in the YooNeqK colorway: blacked-out steel, rust orange trim and neon green
accents, with a neon green sight glow. Same stats as the standard Unity; only the look and the
name differ.

| Item | Accent green |
|---|---|
| Unity YNK Edition | Brightest neon (reads lime-yellow in daylight) |
| Unity YNK Edition (Green) | Truer neon green |

- **Version:** 1.0.0
- **Game:** Cyberpunk 2077 2.5 (Phantom Liberty not required)
- **Requires:** [ArchiveXL](https://github.com/psiberx/cp2077-archive-xl) 1.28+, [TweakXL](https://github.com/psiberx/cp2077-tweak-xl) 1.12+ (and their requirement, RED4ext), and [Cyber Engine Tweaks](https://github.com/maximegmd/CyberEngineTweaks) to spawn the guns
- **Download:** [Nexus Mods](https://www.nexusmods.com/cyberpunk2077/mods/36220) or [GitHub release](https://github.com/OriginalLeeDunn/ynk-cyberpunk77-mods/releases/tag/ynk-unity-finish-v1.0.0)

## Install
Extract the zip into your Cyberpunk 2077 folder, so you end up with:

    Cyberpunk 2077\archive\pc\mod\ynk_unity_finish.archive
    Cyberpunk 2077\archive\pc\mod\ynk_unity_finish.archive.xl
    Cyberpunk 2077\r6\tweaks\YNK\ynk-unity-finish.yaml

Vortex and MO2 install it as-is. Then add the guns from the Cyber Engine Tweaks console:

    Game.AddToInventory("Items.Preset_Unity_YNK", 1)
    Game.AddToInventory("Items.Preset_Unity_YNK_Green", 1)

## Uninstall
Delete the three files above. Any YNK Unity you still carry disappears from your inventory.

## How it works
Nothing from the game is replaced, so it can't conflict with other Unity mods. Everything lives
under `ynk\weapons\unity_ynk\`:

| File | Role |
|---|---|
| `ml_unity_ynk*.mlsetup` | The paint jobs: the vanilla default Unity setup, recolored from the game's own material palettes |
| `w_handgun__unity_ynk*__base1_01.mesh` | Copies of the Unity body pointing at those paints, with the sight glow tinted neon green |
| `w_handgun__unity_ynk*.app` | The vanilla default appearance, using the YNK body |
| `ynk_unity.csv` | Factory entries `Preset_YNK_Unity` / `Preset_YNK_Unity_Green` (loaded by ArchiveXL) |
| `ynk_unity_finish.en-us.json` | Item names and description (loaded by ArchiveXL) |
| `r6\tweaks\YNK\ynk-unity-finish.yaml` | TweakXL items based on `Items.Preset_Unity_Default` |

Paint layers: the Unity's paint uses 20 layers. Layers 11 and 12 are full body coats (12 on top);
this finish hides 12, paints 11 neon green, layer 6 rust, the metal layers black, and swaps the
brass and copper trim to rust orange metal.

## Rebuilding
`source\archive` is generated, not committed (it contains copies of game files). To rebuild:

1. Export the vanilla Unity files to JSON with the WolvenKit CLI (`extract` the Unity `.app`,
   `.mesh` and `.mlsetup` files, the weapon factory CSVs and `onscreens.json`, then
   `convert serialize`) into `C:\Modding\work`, the layout `build\make-ynk-unity.ps1` expects.
2. `build\make-ynk-unity.ps1` writes the CR2W files into `source\archive`.
3. `build\pack.ps1 -Version 1.0.0` packs the archive and builds the release zip in `dist\`.

## How AI was used
Made with an AI coding assistant (Claude, through Claude Code). **AI:** traced how the game picks a
Unity's paint job, wrote the build script that recolors it and wires up the new items, packed the
archive, drove the test game to check both variants in photo mode, and wrote this README.
**Me:** chose the colorway (from my logo) and both greens, reviewed the in-game results and
decided to release it. **Not AI:** no AI-generated art, textures, models, audio or voice. The colors
come from the game's own material palettes, and the screenshots are real in-game captures.

## Changelog
- **1.0.0** Unity YNK Edition and Unity YNK Edition (Green).
