# YNK Weapon Inspect

Press a key to inspect the weapon in your hands. V plays the game's own "idle break" animation, the
one they do by themselves after standing still for about 20 seconds, so every weapon uses its own
vanilla move and nothing new is added to the game. A second key lowers the weapon into the game's
own "safe" stance, an optional auto-lower does it for you when you're idle, and it works on
controller too. Requested in the comments of [YNK Weapon Inspector](../weapon-inspector/).

- **Version:** 0.3.1
- **Game:** Cyberpunk 2077 2.5 (Phantom Liberty not required)
- **Requires:** [Cyber Engine Tweaks](https://github.com/maximegmd/CyberEngineTweaks) 1.38+ and [redscript](https://github.com/jac3km4/redscript) 0.5.32+
- **Download:** [Nexus Mods](https://www.nexusmods.com/cyberpunk2077/mods/36225) or [GitHub release](https://github.com/OriginalLeeDunn/ynk-cyberpunk77-mods/releases/tag/weapon-inspect-v0.3.1)

## Install
Extract the zip into your Cyberpunk 2077 folder, so you end up with
`bin\x64\plugins\cyber_engine_tweaks\mods\ynk_weapon_inspect\init.lua` and `r6\scripts\YNK\WeaponInspect.reds`.
Vortex and MO2 install it as-is.

Then bind the keys: open the CET overlay, go to **Bindings > YNK Weapon Inspect** and set
**Inspect weapon**, **Lower weapon / inspect** and **Toggle auto-lower** to keys the game doesn't
use, such as **Insert**, **Delete**, **Page Down** or **-**. Don't use F5 or F9: those are the
game's quick save and quick load.

## Use
- **Inspect weapon:** V inspects the weapon in hand. If the weapon is lowered (by this mod, or by
  the game in a public area), it is raised first and then inspected.
- **Lower weapon / inspect:** lowers the weapon (it stays in your hands); pressed again, it raises
  it and inspects. Aiming, shooting or combat raises it immediately.
- **Toggle auto-lower:** off by default. When on, the weapon lowers by itself after 3 seconds
  without aiming or shooting, out of combat; your inspect key raises it and inspects. The setting
  is remembered. (In public areas the game already lowers an idle weapon after a second.)
- **Controller:** double-tap **D-pad Down** for lower / inspect. A single tap still cycles your
  tracked objective as usual. (Holding D-pad Down is the phone, so the mod leaves holds alone.)

Tested on pistols, assault rifles and katanas; some weapons (shotguns, for example) have a subtler
idle move. A short cooldown stops repeated presses from restarting the animation. Nothing happens
with no weapon drawn or in photo mode.

**With Always First Equip:** that mod also lowers and raises the weapon. When it is installed,
Weapon Inspect uses its lowered state instead of keeping a second one, so the two don't fight.
(Always First Equip also has its own inspect keys; you may not need both.)

## Uninstall
Delete the `ynk_weapon_inspect` folder and `r6\scripts\YNK\WeaponInspect.reds`.

## How it works
Lowering forces the game's own "safe" stance through a redscript wrap of
`DefaultTransition.IsSafeStateForced`. Raising has to leave the "public safe" state as well, which
the game otherwise only leaves when the area stops being a public zone, so the mod requests a
release through `PublicSafeDecisions.ToPublicSafeToReady`. While an inspect plays, a wrap of
`PublicSafeDecisions.EnterCondition` keeps the game from lowering the weapon again mid-animation.

The weapon state machine (`ReadyEvents.OnTick` in the game scripts) sends the animation event
`IdleBreak` to V after `timeBetweenIdleBreaks` (20 s) of standing still out of combat. The mod sends
the same event on demand, from the same place, once the weapon is ready. Pushing it from CET
directly does nothing, because the animation graph only reacts when it comes through the state
machine.

When Always First Equip is installed (detected at script compile time with
`@if(ModuleExists("AlwaysFirstEquip"))`), the mod drives its `SetSafeStateForced` and release flag
and leaves its safe-state hooks alone. The controller double-tap is read by the player's own input
listener (`OnAction`, action `CycleObjectives`).

## How AI was used
Made with an AI coding assistant (Claude, through Claude Code). **AI:** found the idle-break event,
the safe stances and how Always First Equip hooks them, wrote the Lua and redscript and this README,
and drove the test game.
**Me:** took the requests from the comments, did in-game tests, picked the controller gesture, and decided to release it.
**Not AI:** no AI-generated art, textures, models, animation, audio or voice; the animations are
the game's own.

## Changelog
- **0.3.1** Fixes "can't coerce 'Void' into 'Bool'" (redscript compilation failed) when another mod also
  wraps `PlayerPuppet.OnGameAttached` without a return type. Reported by 235francis.
- **0.3.0** Fixes raising the weapon in public areas (the second press now raises and inspects), the
  inspect key also raises a lowered weapon, optional auto-lower after 3 s idle, works alongside
  Always First Equip. Reported and suggested by sdskif.
- **0.2.0** Lower weapon / inspect key (first press lowers, second inspects and raises), controller support (double-tap D-pad Down). Requested by sdskif.
- **0.1.0** Inspect key that plays the weapon's idle-break animation.
