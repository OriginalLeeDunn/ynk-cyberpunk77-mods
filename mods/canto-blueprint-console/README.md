# YNK Canto Mk.6 Blueprint (console edition)

The mod.io build of [YNK Canto Blueprint](../canto-blueprint/): it gives you the **crafting spec for the
Militech Canto Mk.6** cyberdeck if you never got it, for PC, PS5, Xbox Series X|S and Switch 2. The spec
is a Phantom Liberty quest reward that is easy to miss (siding with Songbird in *Firestarter* locks it
away), and consoles have no console commands to fix that. You still craft the deck yourself.

- **Version:** 1.0.0
- **Game:** Cyberpunk 2077 2.5 with **Phantom Liberty**
- **Requires:** nothing (no frameworks)
- **PC edition:** [Nexus Mods](https://www.nexusmods.com/cyberpunk2077/mods/36450) uses redscript instead. Use one edition, not both.

## What it does
About 8 seconds after you start a new game or load a save, it checks once and adds the recipe with the
message *"Militech Canto Mk.6 crafting spec added (Rare/Epic/Legendary)"*. Tier follows the game's own
rule: Rare below level 30, Epic at 30-39, Legendary at 40+. Once per save; does nothing if the quest
already gave you the recipe, you own the deck, or Phantom Liberty isn't installed.

## What you need to craft the deck
The spec is only the blueprint. For the **Rare** deck (the crafting menu shows the exact amounts):
- 1 **decoded Cerberus core**: picked up from the Cerberus wreck in *Somewhat Damaged* and decoded by Yoko
  in *This Corrosion*. The Erebus SMG uses the same core, so you can build one or the other.
- 50 Rare Components and 30 Rare Quickhack Components.

Epic and Legendary recipes use more and higher-tier parts. The deck unlocks the **Blackwall Gateway** quickhack.

## How it's made
`scripts\YNK\CantoBlueprint.script` is written in the game's native script language as accepted by
CDPR's mod.io compiler, and uses one `@postfix` and `@addMethod` only (nothing is replaced). Every added
name is prefixed `YnkCanto`: two mods adding a method with the same name would break each other.
`YnkCantoDebug()` at the top shows a message for each skipped case; it is `false` in releases.

Build and local test (needs the REDmod DLC):
```powershell
.\build.ps1 -Install    # compile like mod.io, copy to r6\c77, then launch with -LoadScriptMods
```

## Changelog
- **1.0.0**: first release. Tested in game via `-LoadScriptMods`: the recipe is added and shows in the
  crafting menu; Weapon Inspect (console edition) keeps working alongside it.
