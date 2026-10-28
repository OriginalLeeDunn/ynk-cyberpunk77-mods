# YNK Cyberpunk 2077 Mods

Cyberpunk 2077 mods by **YooNeqK**, from small TweakXL edits up to Lua, redscript and asset mods.
Each mod lives in its own folder under [`mods/`](mods/) and is released on GitHub and Nexus Mods.

| Mod | What it does | Type | Requires | Latest | Nexus |
|---|---|---|---|---|---|
| [Unity Extended Magazine](mods/unity-extended-magazine/) | Unity pistol magazine doubled for every variant (12 -> 24, Agent 10 -> 20) | TweakXL | TweakXL 1.12+ | 1.0.1 | [36134](https://www.nexusmods.com/cyberpunk2077/mods/36134) |
| [Weapon Inspector](mods/weapon-inspector/) | Live stats of the held weapon in a CET window, plus temporary test changes | CET Lua | CET 1.38+ | 0.1.1 | [36138](https://www.nexusmods.com/cyberpunk2077/mods/36138) |
| [Combat Tracker](mods/combat-tracker/) | Kills, headshots and top weapon per fight, shown on the HUD when combat ends | redscript | redscript 0.5.32+ | 0.1.0 | [36147](https://www.nexusmods.com/cyberpunk2077/mods/36147) |
| [Nue Extended Magazine](mods/nue-extended-magazine/) | Nue pistol magazine doubled for every variant (10 -> 20, Arasaka 8 -> 16) | TweakXL | TweakXL 1.12+ | 1.0.0 | [36149](https://www.nexusmods.com/cyberpunk2077/mods/36149) |
| [Lexington Extended Magazine](mods/lexington-extended-magazine/) | Lexington pistol magazine doubled for every variant (20 -> 40, Rook 30 -> 60) | TweakXL | TweakXL 1.12+ | 1.0.0 | [36232](https://www.nexusmods.com/cyberpunk2077/mods/36232) |
| [Unity Edition](mods/ynk-unity-finish/) | Two Unity pistols in the YooNeqK colorway: black, rust orange and neon green | ArchiveXL + TweakXL | ArchiveXL 1.28+, TweakXL 1.12+, CET | 1.0.0 | [36220](https://www.nexusmods.com/cyberpunk2077/mods/36220) |
| [Weapon Inspect](mods/weapon-inspect/) | Inspect or lower the weapon in your hands with the game's own animations; keyboard and controller | CET Lua + redscript | CET 1.38+, redscript 0.5.32+ | 0.2.0 | [36225](https://www.nexusmods.com/cyberpunk2077/mods/36225) |

Game version: **Cyberpunk 2077 2.5**.

## Installing a mod
Download the zip from the mod's GitHub release or Nexus page and extract it into your
`Cyberpunk 2077` folder. Vortex and MO2 install them as-is. Each mod's README lists its requirements.

## Questions, bugs, ideas
- Questions and ideas: [Discussions](https://github.com/OriginalLeeDunn/ynk-cyberpunk77-mods/discussions) (Q&A category)
- Bugs: [open an issue](https://github.com/OriginalLeeDunn/ynk-cyberpunk77-mods/issues/new/choose) with your game version, mod version and the relevant log

## Repo layout
```
mods/<mod-name>/          one folder per mod; everything except README.md mirrors the game folder
  README.md               what it does, requirements, install, changelog
  r6/, archive/, bin/ ... the files that go into Cyberpunk 2077\
mods/ynk-unity-finish/    asset mods are WolvenKit projects instead: build/ scripts generate
                          source/archive from game files and stage the release zip
tools/deploy.ps1          copy a mod into the local mod-lab game for testing
tools/package.ps1         build the release zip for a mod
```

## How AI is used
I make these mods together with an AI coding assistant (Claude, through Claude Code). The AI helps
research game data, write code and docs, and package releases. I choose what each mod does, test
everything in game, take the screenshots and decide what gets released. No AI-generated art, textures,
models, audio or voice are used unless a mod's README says otherwise. Each mod's README states exactly
what was AI-assisted.

## License
[MIT](LICENSE). Credit is appreciated if you build on these mods.
