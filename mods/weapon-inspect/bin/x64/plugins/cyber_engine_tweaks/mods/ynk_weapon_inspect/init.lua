-- YNK Weapon Inspect
-- Press a key to inspect the weapon in your hands. It plays the game's own "idle break" animation,
-- the one V does on their own after standing still for about 20 seconds, so every weapon uses its
-- own vanilla animation and nothing new is added to the game. A second key lowers the weapon into
-- the game's "safe" stance; pressing it again (or the inspect key) raises it and inspects. An
-- optional auto-lower lowers it by itself after a few idle seconds. Needs the redscript half
-- (r6\scripts\YNK\WeaponInspect.reds), which talks to the weapon state machine and also handles the
-- controller (double-tap D-pad Down).
--
-- Bind the keys in the Cyber Engine Tweaks overlay: Bindings > YNK Weapon Inspect.

local Inspect = {
    version = "0.3.1",
    cooldown = 1.5,   -- seconds between presses, so mashing the key doesn't restart the animation
    lastPress = -100,
    autoLower = false,   -- saved in settings.json next to this file
    sinceSync = 0,
}

local SETTINGS = "settings.json"

local function loadSettings()
    local f = io.open(SETTINGS, "r")
    if not f then return end
    local ok, data = pcall(json.decode, f:read("*a"))
    f:close()
    if ok and type(data) == "table" then Inspect.autoLower = data.autoLower == true end
end

local function saveSettings()
    local f = io.open(SETTINGS, "w")
    if not f then return end
    f:write(json.encode({ autoLower = Inspect.autoLower }))
    f:close()
end

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

local function notify(text)
    pcall(function()
        local msg = SimpleScreenMessage.new()
        msg.message = text
        msg.isShown = true
        msg.duration = 2.0
        msg.type = SimpleMessageType.Neutral
        local bb = Game.GetBlackboardSystem():Get(GetAllBlackboardDefs().UI_Notifications)
        bb:SetVariant(GetAllBlackboardDefs().UI_Notifications.OnscreenMessage, ToVariant(msg), true)
    end)
end

-- Added by WeaponInspect.reds: the weapon state machine sends IdleBreak once the weapon is ready.
-- Pushing the event from here directly doesn't play the animation.
registerHotkey("ynk_inspect_weapon", "Inspect weapon", hotkey(function()
    local player = ready()
    if player then player:YnkRequestInspect() end
end))

-- First press lowers the weapon, second press raises it and inspects
registerHotkey("ynk_lower_inspect", "Lower weapon / inspect", hotkey(function()
    local player = ready()
    if player then player:YnkCycle() end
end))

registerHotkey("ynk_toggle_auto_lower", "Toggle auto-lower", hotkey(function()
    Inspect.autoLower = not Inspect.autoLower
    saveSettings()
    local player = Game.GetPlayer()
    if player then player:YnkSetAutoLower(Inspect.autoLower) end
    notify(Inspect.autoLower and "Auto-lower weapon: ON" or "Auto-lower weapon: OFF")
end))

-- The player object (and its auto-lower field) is recreated on every load, so keep it in sync
registerForEvent("onUpdate", function(delta)
    Inspect.sinceSync = Inspect.sinceSync + delta
    if Inspect.sinceSync < 2 then return end
    Inspect.sinceSync = 0
    local player = Game.GetPlayer()
    if player and player.ynkAutoLower ~= Inspect.autoLower then
        pcall(function() player:YnkSetAutoLower(Inspect.autoLower) end)
    end
end)

registerForEvent("onInit", function()
    loadSettings()
    print("[YNK Weapon Inspect] " .. Inspect.version .. " loaded (auto-lower " .. (Inspect.autoLower and "on" or "off")
        .. "): bind keys in CET Bindings; controller: double-tap D-pad Down")
end)

return Inspect
