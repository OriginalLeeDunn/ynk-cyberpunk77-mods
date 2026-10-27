# YNK Lexington Extended Magazine

Doubles the magazine of the Lexington pistol, for **every variant** (requested on the Nue Extended
Magazine page):

| Variant | Vanilla | With this mod |
|---|---|---|
| Lexington (all standard versions, Wilson's, silenced, craftables) | 20 | 40 |
| Krausser variants (Jago's, Jurij's, Prevention) | 20 | 40 |
| Rook (iconic) | 30 | 60 |

- **Version:** 1.0.0
- **Game:** Cyberpunk 2077 2.5 (Phantom Liberty not required)
- **Requires:** [TweakXL](https://github.com/psiberx/cp2077-tweak-xl) 1.12+ (and its requirement, RED4ext)

## Install
Extract the zip into your Cyberpunk 2077 folder, so you end up with
`Cyberpunk 2077\r6\tweaks\YNK\lexington-extended-mag.yaml`. Vortex and MO2 install it as-is.

Weapons you already carry may keep their old stats. Any Lexington you pick up, buy or craft
afterwards gets the bigger magazine. Enemies carrying a Lexington get it too.

## Uninstall
Delete `r6\tweaks\YNK\lexington-extended-mag.yaml`.

## How it works
The 48 Lexington weapon records use three "Technical" stat groups. Each group has one stat modifier
that adds `BaseStats.MagazineCapacityBase`; the tweak doubles the `value` of all three:

| Record | Vanilla value |
|---|---|
| `Items.Base_Lexington_Technical_Stats_inline2` | 20 |
| `Items.Base_Lexington_Krausser_Technical_Stats_inline2` | 20 |
| `Items.Base_Lexington_Rook_Technical_Stats_inline2` | 30 |

Check one in the Cyber Engine Tweaks console:

    print(TweakDB:GetFlat("Items.Base_Lexington_Technical_Stats_inline2.value"))

## How AI was used
Made with an AI coding assistant (Claude, through Claude Code). **AI:** listed every Lexington record
and its stat groups from the running game, wrote the YAML and this README, ran the in-game check and
did the packaging. **Me:** picked up the request from the Nexus comments, reviewed and released it.
**Not AI:** no AI-generated art, textures, models, audio or voice.

## Changelog
- **1.0.0** Lexington magazine doubled for every variant (20 -> 40, Rook 30 -> 60).
