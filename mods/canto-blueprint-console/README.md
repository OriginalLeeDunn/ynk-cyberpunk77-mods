# YNK Canto Mk.6 Blueprint (console edition)

The mod.io build of [YNK Canto Blueprint](../canto-blueprint/): it gives you the **crafting spec for the
Militech Canto Mk.6** cyberdeck and, if you have none, one **decoded Cerberus core**, for PC, PS5, Xbox
Series X|S and Switch 2. Both are Phantom Liberty quest rewards that are easy to miss (siding with Songbird
in *Firestarter* locks the blueprint away, and the core only exists on the Reed route), and consoles have no
console commands to fix that. You still craft the deck yourself.

- **Version:** 1.1.0
- **Game:** Cyberpunk 2077 2.5 with **Phantom Liberty**
- **Requires:** nothing (no frameworks)
- **PC edition:** [Nexus Mods](https://www.nexusmods.com/cyberpunk2077/mods/36450) uses redscript instead. Use one edition, not both.

## What it does
About 8 seconds after you start a new game or load a save, it checks once and adds what is missing, with a
short message on screen (*"Canto Mk.6 spec (Rare) + core added"*).
- **The spec** (recipe) is the same item the quest gives. Tier follows the game's own rule: Rare below
  level 30, Epic at 30-39, Legendary at 40+.
- **One decoded Cerberus core**, only if you hold the Canto recipe and have no core, no deck and no Erebus
  SMG (the core is shared with the Erebus SMG, so it stays one or the other).
- **Once each per save.** If you used 1.0.0, you get the core the next time you load. It does nothing if the
  quest already gave you the recipe, you own the deck, or Phantom Liberty isn't installed.

## What you need to craft the deck
The spec is only the blueprint. For the **Rare** deck (the crafting menu shows the exact amounts):
- 1 **decoded Cerberus core**: the mod gives you one if you never got it (the quest only gives it on the Reed
  route). The Erebus SMG uses the same core, so you can build one or the other.
- 50 Rare Components and 30 Rare Quickhack Components.

Epic and Legendary recipes use more and higher-tier parts. The deck unlocks the **Blackwall Gateway** quickhack.

## How it's made
`scripts\YNK\CantoBlueprint.script` is written in the game's native script language as accepted by
CDPR's mod.io compiler, and uses one `@postfix` and `@addMethod` only (nothing is replaced). Every added
name is prefixed `YnkCanto`: two mods adding a method with the same name would break each other.

Build and local test (needs the REDmod DLC):
```powershell
.\build.ps1 -Install    # compile like mod.io, copy to r6\c77, then launch with -LoadScriptMods
```

## Changelog
- **1.1.0**: also adds one decoded Cerberus core (see above). Tested in game through the mod.io script path
  (`-LoadScriptMods`): the core is added on a save that has the recipe but no core.
- **1.0.0**: first release. Tested in game via `-LoadScriptMods`: the recipe is added and shows in the
  crafting menu; Weapon Inspect (console edition) keeps working alongside it.

