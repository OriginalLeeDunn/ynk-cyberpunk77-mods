# Contributing

Bug reports, ideas and pull requests are welcome.

## Before you open something
- **Question or idea?** Use [Discussions](https://github.com/OriginalLeeDunn/ynk-cyberpunk77-mods/discussions) (Q&A).
- **Bug?** Open an issue with the bug template. Include your game version, the mod version, your
  framework versions (RED4ext, TweakXL, ...) and the relevant log lines.

## Pull requests
1. Branch from `main` (`fix/...`, `feat/...`, `mod/<mod-name>`).
2. Keep each PR to one mod or one tool change.
3. Test in game and say how in the PR (what you did, what you saw).
4. Update the mod's README changelog and version when behaviour changes.

## Mod folder rules
- `mods/<mod-name>/` holds one mod. Everything except `README.md` mirrors the game folder
  (`r6/tweaks/...`, `archive/pc/mod/...`, `bin/x64/plugins/cyber_engine_tweaks/mods/...`).
- Put files under a `YNK` subfolder or a `ynk_` prefix so they don't collide with other mods.
- Find game data names in the real data (CET console, WolvenKit Tweak Browser), never guess them.

## Releases
`tools/package.ps1 -Mod <mod-name> -Version <x.y.z>` builds the zip. Releases are tagged
`<mod-name>-v<x.y.z>`.
