# YNK Weapon Inspector

A Cyber Engine Tweaks window that shows the **live stats of the weapon in your hands**: DPS, damage
per hit, fire rate, magazine and ammo, reload times, crit, headshot multiplier, range, recoil and spread.
It also has buttons to **try temporary changes** (magazine x2, fire rate +50%, reload -50%) and remove
them again. Test changes are never saved and are removed when the game closes.

- **Version:** 0.1.1
- **Game:** Cyberpunk 2077 2.5
- **Requires:** [Cyber Engine Tweaks](https://github.com/maximegmd/CyberEngineTweaks) 1.38+
- **Download:** [Nexus Mods](https://www.nexusmods.com/cyberpunk2077/mods/36138) or [GitHub release](https://github.com/OriginalLeeDunn/ynk-cyberpunk77-mods/releases/tag/weapon-inspector-v0.1.0)

## Use
Open the CET overlay (`~` by default) with a weapon drawn. Tick "Keep visible when the overlay is
closed" to watch the numbers while you play. "Copy record ID" copies the weapon's TweakDB record, which
is what a TweakXL mod (like Unity Extended Magazine) edits.

## Install
Extract the zip into your `Cyberpunk 2077` folder so you get
`bin\x64\plugins\cyber_engine_tweaks\mods\ynk_weapon_inspector\init.lua`.

## Uninstall
Delete the `ynk_weapon_inspector` folder.

## How it works
- Finds the held weapon with `PlayerPuppet:GetActiveWeapon()` (falls back to the `AttachmentSlots.WeaponRight` slot).
- Reads each stat with `StatsSystem:GetStatValue(weapon entity, gamedataStatType.<Stat>)` four times a
  second while the window is visible. Stat names were taken from the game's own TweakDB (`BaseStats.*`).
- Test changes are stat modifiers made with `RPGManager.CreateStatModifier` and added with
  `StatsSystem:AddModifier`; the mod keeps them in a list so "Remove test changes" removes exactly those.
- Every game call is wrapped in `pcall`; failures show as "n/a" or in the window's error line.

## How AI was used
Made with an AI coding assistant (Claude, through Claude Code). **AI:** wrote the Lua, this README and the
packaging, and picked stat names from a dump of the game's data. **Me:** chose the feature set, tested it in
game, took the screenshots and decided what to release. **Not AI:** no AI-generated art, audio or voice.

## Changelog
- **0.1.1** Crit chance and crit damage now come from V (in 2.x crit lives on the character; the weapon's own value is usually 0). Stat values line up in a column.
- **0.1.0** First version: live stats window, ammo counter, record ID copy, temporary test modifiers.
