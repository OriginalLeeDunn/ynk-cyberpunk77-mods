-- YNK Weapon Inspector
-- Shows the live stats of the weapon in your hands in a Cyber Engine Tweaks window, and lets you
-- try temporary stat changes (they are removed with one button, and never saved).
--
-- Every game call is wrapped in pcall: a failing call shows up as "n/a" or in the error line at the
-- bottom of the window instead of breaking the mod.

local Inspector = {
    version = "0.1.0",
    overlayOpen = false,
    pinned = false,          -- keep the window visible when the CET overlay is closed
    refreshEvery = 0.25,     -- seconds between stat reads (reading every frame is wasteful)
    sinceRefresh = 0,
    weapon = nil,            -- snapshot of the held weapon, rebuilt every refresh
    testMods = {},           -- stat modifiers we added, so we can remove exactly those
    lastError = nil,
}

-- Stats shown in the window, in order. Names are gamedataStatType values, checked against the
-- game's own TweakDB (BaseStats.<name>) for 2.5.
local STATS = {
    { "EffectiveDPS",            "DPS",                "%.1f" },
    { "EffectiveDamagePerHit",   "Damage per hit",     "%.1f" },
    { "AttacksPerSecond",        "Attacks per second", "%.2f" },
    { "MagazineCapacity",        "Magazine",           "%.0f" },
    { "ReloadTime",              "Reload (s)",         "%.2f" },
    { "EmptyReloadTime",         "Empty reload (s)",   "%.2f" },
    { "CritChance",              "Crit chance (%)",    "%.1f" },
    { "CritDamage",              "Crit damage (%)",    "%.0f" },
    { "HeadshotDamageMultiplier","Headshot multiplier","%.2f" },
    { "EffectiveRange",          "Effective range (m)","%.1f" },
    { "MaximumRange",            "Max range (m)",      "%.1f" },
    { "RecoilKickMax",           "Recoil kick (max)",  "%.2f" },
    { "SpreadMaxX",              "Spread (max)",       "%.2f" },
}

local function try(fn, ...)
    local ok, result = pcall(fn, ...)
    if ok then return result end
    Inspector.lastError = tostring(result)
    return nil
end

local function getHeldWeapon()
    local player = Game.GetPlayer()
    if not player then return nil end
    -- PlayerPuppet:GetActiveWeapon() is the direct route; the right-hand weapon slot is the fallback.
    local weapon = try(function() return player:GetActiveWeapon() end)
    if weapon then return weapon end
    return try(function()
        return Game.GetTransactionSystem():GetItemInSlot(player, TweakDBID.new("AttachmentSlots.WeaponRight"))
    end)
end

local function readStat(weapon, statName)
    return try(function()
        return Game.GetStatsSystem():GetStatValue(weapon:GetEntityID(), gamedataStatType[statName])
    end)
end

local function snapshot()
    local weapon = getHeldWeapon()
    if not weapon then return nil end
    local itemID = try(function() return weapon:GetItemID() end)
    local snap = { object = weapon, stats = {} }
    if itemID then
        snap.recordID = try(function() return TDBID.ToStringDEBUG(itemID.id) end)
        snap.name = try(function()
            return Game.GetLocalizedTextByKey(TweakDBInterface.GetItemRecord(itemID.id):DisplayName())
        end)
    end
    snap.ammo = try(function() return WeaponObject.GetMagazineAmmoCount(weapon) end)
    for _, s in ipairs(STATS) do snap.stats[s[1]] = readStat(weapon, s[1]) end
    return snap
end

-- Temporary test changes: a stat modifier on the weapon's stats object, kept in testMods.
local function addTestModifier(statName, modifierType, value)
    local w = Inspector.weapon
    if not w then return end
    try(function()
        local mod = RPGManager.CreateStatModifier(gamedataStatType[statName], modifierType, value)
        Game.GetStatsSystem():AddModifier(w.object:GetEntityID(), mod)
        table.insert(Inspector.testMods, { entity = w.object:GetEntityID(), mod = mod })
    end)
end

local function removeTestModifiers()
    for _, t in ipairs(Inspector.testMods) do
        try(function() Game.GetStatsSystem():RemoveModifier(t.entity, t.mod) end)
    end
    Inspector.testMods = {}
end

local function fmt(value, pattern)
    if value == nil then return "n/a" end
    return string.format(pattern, value)
end

registerForEvent("onInit", function()
    print("[YNK Weapon Inspector] " .. Inspector.version .. " loaded. Open the CET overlay to see the window.")
end)

registerForEvent("onOverlayOpen", function() Inspector.overlayOpen = true end)
registerForEvent("onOverlayClose", function() Inspector.overlayOpen = false end)

registerForEvent("onUpdate", function(delta)
    Inspector.sinceRefresh = Inspector.sinceRefresh + delta
    if Inspector.sinceRefresh < Inspector.refreshEvery then return end
    Inspector.sinceRefresh = 0
    if Inspector.overlayOpen or Inspector.pinned then
        Inspector.weapon = snapshot()
    end
end)

registerForEvent("onDraw", function()
    if not (Inspector.overlayOpen or Inspector.pinned) then return end
    if not ImGui.Begin("YNK Weapon Inspector", ImGuiWindowFlags.AlwaysAutoResize) then
        ImGui.End()
        return
    end

    local w = Inspector.weapon
    if not w then
        ImGui.Text("No weapon in hand. Draw a weapon to inspect it.")
    else
        ImGui.Text(w.name or "Unknown weapon")
        ImGui.TextDisabled(w.recordID or "record n/a")
        if w.recordID and ImGui.SmallButton("Copy record ID") then ImGui.SetClipboardText(w.recordID) end
        ImGui.Separator()
        ImGui.Text("Ammo in magazine: " .. fmt(w.ammo, "%.0f") .. " / " .. fmt(w.stats.MagazineCapacity, "%.0f"))
        ImGui.Separator()
        for _, s in ipairs(STATS) do
            ImGui.Text(string.format("%-20s %s", s[2], fmt(w.stats[s[1]], s[3])))
        end
        ImGui.Separator()
        ImGui.Text("Try a change (temporary, not saved):")
        if ImGui.Button("Magazine x2") then addTestModifier("MagazineCapacity", gameStatModifierType.Multiplier, 2.0) end
        ImGui.SameLine()
        if ImGui.Button("Fire rate +50%") then addTestModifier("AttacksPerSecond", gameStatModifierType.Multiplier, 1.5) end
        ImGui.SameLine()
        if ImGui.Button("Reload -50%") then addTestModifier("ReloadTime", gameStatModifierType.Multiplier, 0.5) end
        if #Inspector.testMods > 0 then
            if ImGui.Button("Remove test changes (" .. #Inspector.testMods .. ")") then removeTestModifiers() end
        end
    end

    ImGui.Separator()
    Inspector.pinned = ImGui.Checkbox("Keep visible when the overlay is closed", Inspector.pinned)
    if Inspector.lastError then
        ImGui.TextColored(1, 0.4, 0.4, 1, "Last error: " .. Inspector.lastError)
        if ImGui.SmallButton("Clear error") then Inspector.lastError = nil end
    end
    ImGui.End()
end)

registerForEvent("onShutdown", function() removeTestModifiers() end)

return Inspector
