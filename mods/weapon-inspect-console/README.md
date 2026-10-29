# YNK Weapon Inspect (console edition)

The controller-only version of [YNK Weapon Inspect](../weapon-inspect/), built for **mod.io**, so it
runs on PS5, Xbox Series X|S and Switch 2 as well as PC. Same features: inspect the weapon in your
hands with the game's own idle-break animation, lower it into the game's "safe" stance, and an
optional auto-lower.

- **Version:** 1.0.0
- **Game:** Cyberpunk 2077 2.5 (Phantom Liberty not required)
- **Requires:** nothing. No Cyber Engine Tweaks, redscript or other frameworks (consoles don't allow them).
- **Platforms:** PC, PS5, Xbox Series X|S, Switch 2, through the game's mod.io browser

## Controls
Double-tap **D-pad Down** (a single tap still cycles the tracked objective, as usual):
- **Weapon drawn:** lowers the weapon. If it's lowered (by this mod, or by the game in a public area),
  double-tap again to raise it and play the inspect animation. Aiming, shooting or combat raises it
  immediately.
- **No weapon drawn:** turns **auto-lower** on or off (an on-screen message confirms). With it on,
  the weapon lowers by itself after about 3 seconds without aiming or shooting, out of combat. The
  setting is saved with your game.

The mod starts listening to the D-pad the first time you draw a weapon after loading a save.

## PC players
Use **one** edition, not both: the [PC edition](../weapon-inspect/) (Nexus) has keyboard hotkeys
and Always First Equip support; this one is controller-only and needs no frameworks.

## How it's made
`scripts\YNK\WeaponInspectConsole.script` is written in the game's own script language as accepted
by CDPR's mod.io compiler (`function`, `var x : T`, `'Name'` literals). It hooks the weapon state
machine with `@wrapMethod` and `@postfix` only, so no vanilla code is copied and other mods can hook
the same methods. Inside a `@wrapMethod` the original is called by its own name (not `wrappedMethod()`
as in redscript). The D-pad is read by a small listener object rather than by hooking `PlayerPuppet`.

Build and local test (needs the REDmod DLC):
```powershell
.\build.ps1 -Install    # compile like mod.io, copy to r6\c77, then launch the game with -LoadScriptMods
```
REDmod 2.5 quirks it works around: `validate-mod-scripts` only compiles scripts under
`<mod>\r6\scripts`, and fails with "No Base Game blobs found" when the game path contains spaces.
A local test install needs `r6\c77\<ModFolder>\about.json` next to `scripts\final.redscripts(.h64)`;
without `about.json` the game ignores the patch.

## Changelog
- **1.0.0**: first release. Tested in game via `-LoadScriptMods`: lower, raise + inspect,
  auto-lower and its toggle on a controller.
