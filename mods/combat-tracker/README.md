# YNK Combat Tracker

Counts **your kills and headshots during each fight, per weapon**, and shows a short summary on the
HUD when combat ends:

> 4 kills, 3 headshots (75%). Top weapon: Unity (3). Session: 12 kills, 7 headshots

A kill outside combat (a stealth kill, say) gets its own message straight away.

- **Version:** 0.1.0
- **Game:** Cyberpunk 2077 2.5
- **Requires:** [redscript](https://github.com/jac3km4/redscript) 0.5.32+
- **Download:** [Nexus Mods](https://www.nexusmods.com/cyberpunk2077/mods/36147) or [GitHub release](https://github.com/OriginalLeeDunn/ynk-cyberpunk77-mods/releases/tag/combat-tracker-v0.1.0)

## Install
Extract the zip into your `Cyberpunk 2077` folder so you get `r6\scripts\YNK\CombatTracker.reds`.

## Uninstall
Delete `r6\scripts\YNK\CombatTracker.reds`.

## How it works
Three `@wrapMethod` hooks, checked against the game's decompiled 2.5 scripts. Each one calls the
game's own code unchanged and only reads from it:
- `HitReactionComponent.EvaluateHit` runs for every hit an NPC takes. If V landed it, the mod notes on
  the NPC whether it was a headshot (`hitFlag.Headshot`, set earlier by
  `DamageSystem.ProcessLocalizedDamage`) and which weapon fired it.
- `NPCPuppet.OnDeath` runs when the NPC dies. If `gameDeathEvent.instigator` is V, the kill is counted.
- `PlayerPuppet.OnCombatStateChanged` runs when combat ends. The mod shows the summary with the same HUD
  warning message the game uses, then resets the fight counters.

Session totals reset when you start the game; nothing is written to your save.

## How AI was used
Made with an AI coding assistant (Claude, through Claude Code). **AI:** decompiled the game's scripts
with redscript-cli to find the functions to hook, wrote the redscript, this README and the packaging.
**Me:** chose the feature, tested it in game, took the screenshots and decided what to release.
**Not AI:** no AI-generated art, audio or voice.

## Changelog
- **0.1.0** First version: per-fight kills, headshots and top weapon, session totals.
