# YNK Canto Blueprint

Gives you the **crafting spec for the Militech Canto Mk.6** cyberdeck if you never got it. The game
hands it out as a Phantom Liberty quest reward and it is easy to miss: siding with Songbird in
*Firestarter* locks the blueprint away. This adds the same recipe item the quest would have given, once,
and you still craft the deck yourself with the usual materials.

- **Version:** 1.0.0
- **Game:** Cyberpunk 2077 2.5 with **Phantom Liberty** (the deck doesn't exist without it)
- **Requires:** [redscript](https://github.com/jac3km4/redscript) 0.5.32+
- **Console / mod.io edition:** [YNK Canto Mk.6 Blueprint on mod.io](https://mod.io/g/cyberpunk-2077/m/ynk-canto-mk6-blueprint) (pending CDPR approval). Use one edition, not both.

## What it does
About 8 seconds after you start a new game or load a save, it checks once and adds the recipe to
your inventory with the message *"Militech Canto Mk.6 crafting spec added (Rare/Epic/Legendary)"*.
- **Tier** follows the game's own rule for this reward: Rare below level 30, Epic at 30-39, Legendary at 40+.
- **Once per save.** A quest fact remembers it, so it never repeats.
- It does **nothing** if the quest already gave you the recipe, if you already own the deck, or if
  Phantom Liberty isn't installed (then it simply tries again next load).
- It only adds the **spec**. You craft the deck at the crafting station and need the components for it.

## What you need to craft the deck
The spec is only the blueprint. For the **Rare** deck (the game's crafting menu shows the exact amounts):
- 1 **decoded Cerberus core**: you pick it up from the Cerberus wreck in *Somewhat Damaged* and Yoko decodes
  it in *This Corrosion*. The Erebus SMG uses the same core, so you can build one or the other.
- 50 Rare Components and 30 Rare Quickhack Components.

Epic and Legendary recipes use more and higher-tier parts. Crafting it gives the **Militech Canto Mk.6**,
which unlocks the **Blackwall Gateway** quickhack.

## Install
Extract the zip into your Cyberpunk 2077 folder so you end up with
`r6\scripts\YNK\CantoBlueprint.reds`. Vortex and MO2 install it as-is.

## Uninstall
Delete `r6\scripts\YNK\CantoBlueprint.reds`. A recipe it already gave you stays in your inventory.

## Compatibility
Every added name is prefixed `YnkCanto`, and the mod only wraps `PlayerPuppet.OnGameAttached` (the
original is called as a statement, so it also works next to mods that wrap it without a return type).

## How AI is used
Made with an AI coding assistant (Claude, through Claude Code), which helped read the game data, write
the script and package it. I chose what it does and tested it in game.

## Changelog
- **1.0.0**: first release. Tested in game: the recipe is added and shows in the crafting menu.
