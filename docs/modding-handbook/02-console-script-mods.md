# 2. Console and mod.io script mods

Since 2.5 CDPR's mod.io path runs script mods on PC, PS5, Xbox Series X|S and Switch 2. A script mod is a
folder with `about.json` and compiled scripts; you author it in the game's **native script syntax** and
compile it with REDmod's `redMod.exe`. Everything below we ran into building Weapon Inspect and Canto
Blueprint (console editions).

## Layout and build
- Source: `<mod>\r6\scripts\<Name>.script` (files **outside `r6\scripts` are silently ignored**).
- Build: `redMod.exe validate-mod-scripts -root=<game> -compile -directory=<mod>`; it writes
  `final.redscripts(.h64)`, which is what ships.
- Local test layout: `<game>\r6\c77\<ModFolder>\about.json` + `scripts\final.redscripts(.h64)`, and start the
  game with `-LoadScriptMods`.
- **The `-root` game path must contain no spaces.** With spaces the build fails ("No Base Game blobs found").
  Workaround: a junction such as `C:\cp77root` pointing at the game folder.

## Syntax differs from redscript
Native syntax: `function F() : Void`, `var x : Int32`, names as `'Name'`, `T"Items.X"` for TweakDB ids, and no
modifiers after an annotation. Supported annotations: `@addField`, `@addMethod`, `@replaceMethod`, `@wrapMethod`,
`@prefix`, `@postfix`. Inside `@wrapMethod` you call the original **by its own name** (not `wrappedMethod()`).
CDPR's `ModdingReference.script` (in REDmod's `tools\redmod\scripts`) is the reference.

## Pitfalls
- **Prefix everything you add.** Two mods adding a method with the same name break all script mods at load.
- Accessing a class field inside `@replaceMethod` crashed the compiler. Prefer `@wrapMethod` / `@postfix`.
- Our advice (not tested): prefer `@postfix` / `@wrapMethod` over replacing, since players run many mods and a replaced method can only have one owner.
- Run `redMod.exe` through the call operator in PowerShell (`& $exe ...`). `Start-Process -ArgumentList` does
  **not** quote arguments with spaces (a publish once created a mod called just "YNK").
- Never run `redMod publish` without `-root` and a stored login; without one it loops on the email prompt and
  filled its log to 1 GB.

## Publishing
`redMod.exe publish /mod /create` then `/upload -modid <id> -version x.y.z -platforms windows ps5 xsx ns2 -directory <build>`.
New mods wait for CDPR's approval before they show as live; we have not timed how updates are handled.

## Game API notes (verified on 2.5)
- Ask "does the player own this?" by **record**: `TransactionSystem.GetItemDataByTDBID(player, recordId)`.
  `HasItem(ItemID.FromTDBID(...))` never matches weapons and decks, which carry a unique seed.
- Giving quest items works with `GiveItemByTDBID`; `Game.AddToInventory` silently failed for several of them.
- Your own quest facts (`SetFact` on a name you made up) are reliable and per-save: a good once-per-save flag.
  You can't lower the game's own facts.
- Show a message with the `UI_Notifications.OnscreenMessage` blackboard; long text is clipped, keep it short.
- Check for DLC by testing a DLC record exists (`TweakDBInterface.GetItemRecord(...)` is defined).
