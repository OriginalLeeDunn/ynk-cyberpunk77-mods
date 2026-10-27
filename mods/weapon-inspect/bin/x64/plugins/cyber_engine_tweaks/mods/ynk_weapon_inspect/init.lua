-- YNK Weapon Inspect
-- Press a key to inspect the weapon in your hands. It plays the game's own "idle break" animation,
-- the one V does on their own after standing still for about 20 seconds, so every weapon uses its
-- own vanilla animation and nothing new is added to the game. Needs the redscript half
-- (r6\scripts\YNK\WeaponInspect.reds), which hands the request to the weapon state machine.
--
-- Bind the key in the Cyber Engine Tweaks overlay: Bindings > YNK Weapon Inspect > Inspect weapon.

local Inspect = {
    version = "0.1.0",
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

local function inspect()
    local now = os.clock()
    if now - Inspect.lastPress < Inspect.cooldown then return end

    local player = Game.GetPlayer()
    if not player then return end
    if Game.GetPhotoModeSystem():IsPhotoModeActive() then return end
    if not heldWeapon(player) then return end

    Inspect.lastPress = now
    -- Added by r6\scripts\YNK\WeaponInspect.reds: the weapon state machine sends IdleBreak on its next
    -- tick. Pushing the event from here directly doesn't play the animation.
    player:YnkRequestInspect()
end

registerHotkey("ynk_inspect_weapon", "Inspect weapon", function()
    local ok, err = pcall(inspect)
    if not ok then print("[YNK Weapon Inspect] " .. tostring(err)) end
end)

registerForEvent("onInit", function()
    print("[YNK Weapon Inspect] " .. Inspect.version .. " loaded: bind 'Inspect weapon' in CET Bindings")
end)

return Inspect
