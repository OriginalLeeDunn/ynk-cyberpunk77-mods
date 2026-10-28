# YNK Weapon Inspect

Press a key to inspect the weapon in your hands. V plays the game's own "idle break" animation, the
one they do by themselves after standing still for about 20 seconds, so every weapon uses its own
vanilla move and nothing new is added to the game. A second key lowers the weapon into the game's
own "safe" stance first, and works on controller too. Requested in the comments of
[YNK Weapon Inspector](../weapon-inspector/).

- **Version:** 0.2.0
- **Game:** Cyberpunk 2077 2.5 (Phantom Liberty not required)
- **Requires:** [Cyber Engine Tweaks](https://github.com/maximegmd/CyberEngineTweaks) 1.38+ and [redscript](https://github.com/jac3km4/redscript) 0.5.32+
- **Download:** [Nexus Mods](https://www.nexusmods.com/cyberpunk2077/mods/36225) or [GitHub release](https://github.com/OriginalLeeDunn/ynk-cyberpunk77-mods/releases/tag/weapon-inspect-v0.2.0)

## Install
Extract the zip into your Cyberpunk 2077 folder, so you end up with
`bin\x64\plugins\cyber_engine_tweaks\mods\ynk_weapon_inspect\init.lua` and `r6\scripts\YNK\WeaponInspect.reds`.
Vortex and MO2 install it as-is.

Then bind the keys: open the CET overlay, go to **Bindings > YNK Weapon Inspect** and set
**Inspect weapon** and **Lower weapon / inspect** to keys the game doesn't use, such as **Insert**,
**Delete**, **Page Down** or **-**. Don't use F5 or F9: those are the game's quick save and quick load.

## Use
- **Inspect weapon:** V inspects the weapon in hand.
- **Lower weapon / inspect:** the first press lowers the weapon (it stays in your hands), the second
  press inspects it and raises it back up. Aiming, shooting or combat raises it immediately.
- **Controller:** double-tap **D-pad Down** for lower / inspect. A single tap still cycles your
  tracked objective as usual. (Holding D-pad Down is the phone, so the mod leaves holds alone.)

Tested on pistols, assault rifles and katanas; some weapons (shotguns, for example) have a subtler
idle move. A short cooldown stops repeated presses from restarting the animation. Nothing happens
with no weapon drawn or in photo mode.

## Uninstall
Delete the `ynk_weapon_inspect` folder and `r6\scripts\YNK\WeaponInspect.reds`.

## How it works
Lowering uses the game's own "safe" stance, the one V uses when aiming at a friendly NPC: while the
toggle is on, a redscript wrap of `ShouldEnterSafe` answers true, so the weapon state machine moves
the gun to Safe with its own animation, and back to Ready when the toggle clears. The controller
double-tap is read by the player's own input listener (`OnAction`, action `CycleObjectives`).

The weapon state machine (`ReadyEvents.OnTick` in the game scripts) sends the animation event
`IdleBreak` to V after `timeBetweenIdleBreaks` (20 s) of standing still out of combat. The mod sends
the same event on demand. Pushing it from CET directly does nothing, because the animation graph only
reacts when it comes through the state machine, so the key (CET) sets a flag and a small redscript
wrap of `ReadyEvents.OnTick` sends `IdleBreak` on the next tick.

## How AI was used
Made with an AI coding assistant (Claude, through Claude Code). **AI:** found the idle-break event
in the decompiled game scripts, wrote the Lua and redscript and this README, and drove the test game.
**Me:** took the requests from the comments, did in-game tests, picked the controller gesture, and decided to release it.
**Not AI:** no AI-generated art, textures, models, animation, audio or voice; the animations are
the game's own.

## Changelog
- **0.2.0** Lower weapon / inspect key (first press lowers, second inspects and raises), controller support (double-tap D-pad Down). Requested by sdskif.
- **0.1.0** Inspect key that plays the weapon's idle-break animation.
