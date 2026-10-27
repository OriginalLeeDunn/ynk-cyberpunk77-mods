# YNK Tweaks: Unity Extended Magazine

Doubles the magazine of the Unity pistol from **12 to 24 rounds**. It applies to every Unity
variant (Default, Military, Neon, Angelica and the craftable versions), because they all share
one base stat.

- **Version:** 1.0.0
- **Game:** Cyberpunk 2077 2.5 (Phantom Liberty not required)
- **Requires:** [TweakXL](https://github.com/psiberx/cp2077-tweak-xl) 1.12+ (and its requirement, RED4ext)

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
The repo mirrors the game folder, so a release zip is just this tree:

    r6/tweaks/YNK/*.yaml    TweakXL tweaks, loaded at game start

Test loop: `.\deploy.ps1` copies `r6/` into the mod lab (`C:\Modding\Cyberpunk 2077`), then
`cyber lab`. TweakXL logs (`red4ext\plugins\TweakXL\*.log`) report YAML errors with line numbers.

## Changelog
- **1.0.0** Unity base magazine 12 -> 24.
