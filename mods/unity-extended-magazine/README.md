# YNK Unity Extended Magazine

Doubles the magazine of the Unity pistol from **12 to 24 rounds**. It applies to every Unity
variant (Default, Military, Neon, Angelica and the craftable versions), because they all share
one base stat.

- **Version:** 1.0.0
- **Game:** Cyberpunk 2077 2.5 (Phantom Liberty not required)
- **Requires:** [TweakXL](https://github.com/psiberx/cp2077-tweak-xl) 1.12+ (and its requirement, RED4ext)
- **Download:** [Nexus Mods](https://www.nexusmods.com/cyberpunk2077/mods/36134) or [GitHub release](https://github.com/OriginalLeeDunn/ynk-cyberpunk77-mods/releases/tag/v1.0.0)

## Install
Extract the zip into your Cyberpunk 2077 folder, so you end up with
`Cyberpunk 2077\r6\tweaks\YNK\unity-extended-mag.yaml`. Vortex and MO2 install it as-is.

Weapons you already carry may keep their old stats. Any Unity you pick up, buy or craft afterwards
gets 24 rounds.

## Uninstall
Delete `r6\tweaks\YNK\unity-extended-mag.yaml`.

## How it works
`Items.Base_Unity_Technical_Stats_inline2` is the stat modifier that adds `BaseStats.MagazineCapacityBase`
(Additive, 12) to the Unity. The tweak sets its `value` to 24. You can check it in the
Cyber Engine Tweaks console:

    print(TweakDB:GetFlat("Items.Base_Unity_Technical_Stats_inline2.value"))

## Development
This folder mirrors the game folder (`r6/tweaks/YNK/*.yaml` = TweakXL tweaks, loaded at game start).

Test loop from the repo root: `.\tools\deploy.ps1 -Mod unity-extended-magazine`, then `cyber lab`.
TweakXL logs (`red4ext\plugins\TweakXL\*.log`) report YAML errors with line numbers.
Release zip: `.\tools\package.ps1 -Mod unity-extended-magazine -Version 1.0.0`.

## How AI was used
Made with an AI coding assistant (Claude, through Claude Code). **AI:** wrote the CET script that
dumped the game's data to find the exact stat record, the YAML, this README and the packaging.
**Me:** chose the change, ran every in-game test, took the screenshots, reviewed and released it.
**Not AI:** no AI-generated art, textures, models, audio or voice; screenshots are real in-game captures.

## Changelog
- **1.0.0** Unity base magazine 12 -> 24.
