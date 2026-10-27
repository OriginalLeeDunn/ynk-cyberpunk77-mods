# YNK Nue Extended Magazine

Doubles the magazine of the Nue pistol, for **every variant** (requested on the Unity Extended
Magazine page):

| Variant | Vanilla | With this mod |
|---|---|---|
| Nue (all standard versions, Jackie's La Chingona Dorada, craftables) | 10 | 20 |
| Arasaka 2020 / 2077 | 8 | 16 |
| Bree's Nue | 10 | 20 |
| Maiko's Nue (burst) | 10 | 20 |

- **Version:** 1.0.0
- **Game:** Cyberpunk 2077 2.5 (Phantom Liberty not required)
- **Requires:** [TweakXL](https://github.com/psiberx/cp2077-tweak-xl) 1.12+ (and its requirement, RED4ext)

## Install
Extract the zip into your Cyberpunk 2077 folder, so you end up with
`Cyberpunk 2077\r6\tweaks\YNK\nue-extended-mag.yaml`. Vortex and MO2 install it as-is.

Weapons you already carry may keep their old stats. Any Nue you pick up, buy or craft afterwards
gets the bigger magazine. Enemies carrying a Nue get it too.

## Uninstall
Delete `r6\tweaks\YNK\nue-extended-mag.yaml`.

## How it works
The 37 Nue weapon records use four "Technical" stat groups. Each group has one stat modifier that
adds `BaseStats.MagazineCapacityBase`; the tweak doubles the `value` of all four:

| Record | Vanilla value |
|---|---|
| `Items.Base_Nue_Technical_Stats_inline2` | 10 |
| `Items.Base_Nue_Arasaka_2020_Technical_Stats_inline2` | 8 |
| `Items.Base_Nue_Bree_Technical_Stats_inline2` | 10 |
| `Items.Base_Nue_Maiko_Technical_Stats_inline6` | 10 |

Check one in the Cyber Engine Tweaks console:

    print(TweakDB:GetFlat("Items.Base_Nue_Technical_Stats_inline2.value"))

## How AI was used
Made with an AI coding assistant (Claude, through Claude Code). **AI:** extended the CET dump script
to list every Nue record and its stat groups, wrote the YAML, this README and the packaging.
**Me:** picked up the request from the Nexus comments, ran the in-game test, took the screenshots,
reviewed and released it. **Not AI:** no AI-generated art, textures, models, audio or voice.

## Changelog
- **1.0.0** Nue magazine doubled for every variant (10 -> 20, Arasaka 8 -> 16).
