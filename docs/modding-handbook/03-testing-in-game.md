# 3. Testing mods in game

"It compiles" is not "it works". We drive a real game from scripts so tests are repeatable.

## The lab approach
- Keep a **separate copy** of the game for testing. Our daily game (and the multiplayer RP client) must never
  get test scripts.
- A tiny Cyber Engine Tweaks mod accepts Lua commands from a file, so a script can start the game, load a
  save, run Lua (`Game.GetPlayer()`, `GetTransactionSystem()`, `GetQuestsSystem()`), and take screenshots.
- **Look at a screenshot before acting.** The "in game" flag reports true on the loading screen and on the
  "press space to continue" recap, so read the screen, not the flag.

## Tests that mislead
- **Start every run from the same clean save.** The game autosaves while you test, so items from the last
  run silently make the next one pass or fail. Restore clean saves between runs.
- `RemoveItem` / `RemoveItemByTDBID` return `true` and leave seeded items in place; don't build cleanup on them.
- Check ownership by record (see chapter 2), or your "negative" test passes for the wrong reason.
- A message that appears while a loading recap is up can be missed: capture a screenshot every few seconds
  across the whole window and scan the frames, instead of one well-timed shot.

## Testing the console (mod.io) build on a PC
The native path only loads when the game starts with `-LoadScriptMods` and the mod sits in `r6\c77\`. In a game
with RED4ext the redscript step replaces the script blob and the native mod never loads (chapter 1), so for
this test turn RED4ext's redscript step off (we park `engine\tools\scc_lib.dll`). Cyber Engine Tweaks still
loads but `Game` was nil in our Lua there (the wrappers appear to need redscript), so you drive that run with keys and screenshots only, and
check the on-screen message. Remember the mod verification dialog and the patch-notes box on first load.
