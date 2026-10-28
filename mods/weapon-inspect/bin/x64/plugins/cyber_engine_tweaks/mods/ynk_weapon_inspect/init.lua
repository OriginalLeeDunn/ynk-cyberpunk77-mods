-- YNK Weapon Inspect
-- Press a key to inspect the weapon in your hands. It plays the game's own "idle break" animation,
-- the one V does on their own after standing still for about 20 seconds, so every weapon uses its
-- own vanilla animation and nothing new is added to the game. A second key lowers the weapon into
-- the game's "safe" stance first; pressing it again inspects and raises it. Needs the redscript half
-- (r6\scripts\YNK\WeaponInspect.reds), which talks to the weapon state machine and also handles the
-- controller (hold D-pad Down).
--
-- Bind the keys in the Cyber Engine Tweaks overlay: Bindings > YNK Weapon Inspect.

local Inspect = {
    version = "0.2.0",
    cooldown = 1.5,   -- seconds between presses, so mashing the key doesn't restart the animation
    lastPress = -100,
}

local function heldWeapon(player)
    local ok, item = pcall(function()
        return Game.GetTransactionSystem():GetItemInSlot(player, TweakDBID.new("AttachmentSlots.WeaponRight"))
    end)
    if ok then return item end
    return nil
end

-- Returns the player when a key press should act, nil otherwise
local function ready()
    local now = os.clock()
    if now - Inspect.lastPress < Inspect.cooldown then return nil end

    local player = Game.GetPlayer()
    if not player then return nil end
    if Game.GetPhotoModeSystem():IsPhotoModeActive() then return nil end
    if not heldWeapon(player) then return nil end

    Inspect.lastPress = now
    return player
end

local function hotkey(fn)
    return function()
        local ok, err = pcall(fn)
        if not ok then print("[YNK Weapon Inspect] " .. tostring(err)) end
    end
end

-- Added by WeaponInspect.reds: the weapon state machine sends IdleBreak on its next tick.
-- Pushing the event from here directly doesn't play the animation.
registerHotkey("ynk_inspect_weapon", "Inspect weapon", hotkey(function()
    local player = ready()
    if player then player:YnkRequestInspect() end
end))

-- First press lowers the weapon, second press inspects and raises it
registerHotkey("ynk_lower_inspect", "Lower weapon / inspect", hotkey(function()
    local player = ready()
    if player then player:YnkCycle() end
end))

registerForEvent("onInit", function()
    print("[YNK Weapon Inspect] " .. Inspect.version .. " loaded: bind keys in CET Bindings; controller: hold D-pad Down")
end)

return Inspect
