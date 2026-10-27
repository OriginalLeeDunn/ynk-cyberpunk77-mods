# YNK Unity Extended Magazine

Doubles the magazine of the Unity pistol, for **every variant**:

| Variant | Vanilla | With this mod |
|---|---|---|
| Unity (Default, Military, Neon, other skins, V's own, craftables) | 12 | 24 |
| Agent (iconic) | 10 | 20 |
| Angelica (iconic) | 12 | 24 |

- **Version:** 1.0.1
- **Game:** Cyberpunk 2077 2.5 (Phantom Liberty not required)
- **Requires:** [TweakXL](https://github.com/psiberx/cp2077-tweak-xl) 1.12+ (and its requirement, RED4ext)
- **Download:** [Nexus Mods](https://www.nexusmods.com/cyberpunk2077/mods/36134) or [GitHub release](https://github.com/OriginalLeeDunn/ynk-cyberpunk77-mods/releases/tag/unity-extended-magazine-v1.0.1)

## Install
Extract the zip into your Cyberpunk 2077 folder, so you end up with
`Cyberpunk 2077\r6\tweaks\YNK\unity-extended-mag.yaml`. Vortex and MO2 install it as-is.

Weapons you already carry may keep their old stats. Any Unity you pick up, buy or craft afterwards
gets the bigger magazine. Enemies carrying a Unity get it too.

## Uninstall
Delete `r6\tweaks\YNK\unity-extended-mag.yaml`.

## How it works
The 28 Unity weapon records use three "Technical" stat groups. Each group has one stat modifier
that adds `BaseStats.MagazineCapacityBase`; the tweak doubles the `value` of all three:

| Record | Vanilla value |
|---|---|
| `Items.Base_Unity_Technical_Stats_inline2` | 12 |
| `Items.Base_Unity_Agent_Technical_Stats_inline2` | 10 |
| `Items.Base_Unity_Angelica_Technical_Stats_inline2` | 12 |

Check one in the Cyber Engine Tweaks console:

    print(TweakDB:GetFlat("Items.Base_Unity_Technical_Stats_inline2.value"))

## Development
This folder mirrors the game folder (`r6/tweaks/YNK/*.yaml` = TweakXL tweaks, loaded at game start).

Test loop from the repo root: `.\tools\deploy.ps1 -Mod unity-extended-magazine`, then `cyber lab`.
TweakXL logs (`red4ext\plugins\TweakXL\*.log`) report YAML errors with line numbers.
Release zip: `.\tools\package.ps1 -Mod unity-extended-magazine -Version 1.0.1`.

## How AI was used
Made with an AI coding assistant (Claude, through Claude Code). **AI:** wrote the CET script that
dumped the game's data to find the exact stat record, the YAML, this README and the packaging.
**Me:** chose the change, ran every in-game test, took the screenshots, reviewed and released it.
**Not AI:** no AI-generated art, textures, models, audio or voice; screenshots are real in-game captures.

## Changelog
- **1.0.1** The iconic Agent (10 -> 20) and Angelica (12 -> 24) are now covered too. They have their own
  stat groups, so 1.0.0 didn't change them (its description wrongly said Angelica was included).
- **1.0.0** Unity base magazine 12 -> 24.
