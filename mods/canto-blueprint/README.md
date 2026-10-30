# YNK Canto Blueprint

Gives you what you need to build the **Militech Canto Mk.6** cyberdeck if you missed it: the **crafting
spec** and, if you have none, one **decoded Cerberus core**. The game hands both out as Phantom Liberty
quest rewards and both are easy to miss: siding with Songbird in *Firestarter* locks the blueprint away,
and the core only exists on the Reed route. This adds them once, and you still craft the deck yourself
with the components it costs.

- **Version:** 1.1.0
- **Game:** Cyberpunk 2077 2.5 with **Phantom Liberty** (the deck doesn't exist without it)
- **Requires:** [redscript](https://github.com/jac3km4/redscript) 0.5.32+
- **Console / mod.io edition:** [YNK Canto Mk.6 Blueprint on mod.io](https://mod.io/g/cyberpunk-2077/m/ynk-canto-mk6-blueprint) (pending CDPR approval). Use one edition, not both.

## What it does
About 8 seconds after you start a new game or load a save, it checks once and adds what is missing, with
a short message on screen (*"Canto Mk.6 spec (Rare) + core added"*).
- **The spec** (recipe) is the same item the quest gives. **Tier** follows the game's own rule: Rare below
  level 30, Epic at 30-39, Legendary at 40+.
- **One decoded Cerberus core**, only if you hold the Canto recipe and have no core, no deck and no Erebus
  SMG. The core is shared with the Erebus SMG, so it stays one or the other: if you already chose the
  Erebus, you get no core.
- **Once each per save.** Quest facts remember them, so nothing repeats. If you used 1.0.0, you get the
  core the next time you load.
- It does **nothing** if the quest already gave you the recipe, you already own the deck, or Phantom Liberty
  isn't installed (then it simply tries again next load).

## What you need to craft the deck
The spec is only the blueprint. For the **Rare** deck (the game's crafting menu shows the exact amounts):
- 1 **decoded Cerberus core**: the mod gives you one if you never got it (the quest only gives it on the Reed\r\n  route). The Erebus SMG uses the same core, so you can build one or the other.
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
- **1.1.0**: also adds one decoded Cerberus core when you hold the recipe and have no core, deck or Erebus,\r
  so Songbird-route players can actually craft the deck. Shorter on-screen message. Tested in game: spec + core\r
  added on a Songbird-style save, nothing added with an Erebus, a deck or a core already owned, and the core\r
  added when upgrading from 1.0.0.
- **1.0.0**: first release. Tested in game: the recipe is added and shows in the crafting menu.

