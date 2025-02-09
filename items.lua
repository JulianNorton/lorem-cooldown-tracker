local addonName, LCT = ...

-- Item tracking module
local items = {}
LCT.items = items

-- Constants
local TRINKET_SLOTS = {13, 14}  -- First and second trinket slots
local PVP_TRINKETS = {
    -- Alliance PvP Trinkets
    [18854] = true, -- Insignia of the Alliance
    [18856] = true, -- Insignia of the Alliance (Warrior)
    [18857] = true, -- Insignia of the Alliance (Paladin)
    [18858] = true, -- Insignia of the Alliance (Hunter)
    [18859] = true, -- Insignia of the Alliance (Rogue)
    [18860] = true, -- Insignia of the Alliance (Priest)
    [18862] = true, -- Insignia of the Alliance (Mage)
    [18863] = true, -- Insignia of the Alliance (Warlock)
    [18864] = true, -- Insignia of the Alliance (Druid)
    
    -- Horde PvP Trinkets
    [18834] = true, -- Insignia of the Horde
    [18845] = true, -- Insignia of the Horde (Warrior)
    [18846] = true, -- Insignia of the Horde (Paladin)
    [18847] = true, -- Insignia of the Horde (Hunter)
    [18848] = true, -- Insignia of the Horde (Rogue)
    [18849] = true, -- Insignia of the Horde (Priest)
    [18850] = true, -- Insignia of the Horde (Shaman)
    [18851] = true, -- Insignia of the Horde (Mage)
    [18852] = true, -- Insignia of the Horde (Warlock)
    [18853] = true, -- Insignia of the Horde (Druid)
}

-- Function to clean up unequipped trinkets
local function CleanupTrinkets()
    -- Ensure cooldowns module and trackedItems exist
    if not LCT.cooldowns or not LCT.cooldowns.trackedItems then
        LCT:Debug("ERROR - Cannot cleanup trinkets, cooldowns module or trackedItems not initialized")
        return
    end

    -- Only unregister non-PvP trinkets that aren't in slots 13 or 14
    for slotID in pairs(LCT.cooldowns.trackedItems) do
        if slotID ~= 13 and slotID ~= 14 then
            LCT.cooldowns.UnregisterItem(slotID)
        end
    end
end

-- Function to check trinket slots and register them for tracking
local function UpdateEquippedTrinkets()
    -- Ensure cooldowns module exists
    if not LCT.cooldowns or not LCT.cooldowns.RegisterItem then
        LCT:Debug("ERROR - Cannot update trinkets, cooldowns module not initialized")
        return
    end

    -- Check trinket slots
    for _, slot in ipairs(TRINKET_SLOTS) do
        local itemID = GetInventoryItemID("player", slot)
        if itemID then
            -- Register the slot number for cooldown tracking
            LCT.cooldowns.RegisterItem(slot)
            local itemName = GetItemInfo(itemID)
            LCT:Debug("Registered equipped trinket in slot", slot, ":", itemName, "(ID:", itemID, ")")
        end
    end
end

-- Initialize item tracking
function items.Initialize()
    LCT:Debug("Initializing item tracking")
    
    -- Ensure cooldowns module is initialized
    if not LCT.cooldowns or not LCT.cooldowns.RegisterItem then
        LCT:Debug("ERROR - Cannot initialize items module, cooldowns module not ready")
        return
    end
    
    -- Create a separate frame for item events
    local eventFrame = CreateFrame("Frame")
    
    -- Register equipment change events
    eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    
    -- Set up event handler
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_EQUIPMENT_CHANGED" then
            local slot = ...
            -- Only update for trinket slots
            if slot == 13 or slot == 14 then
                LCT:Debug("Trinket slot changed:", slot)
                UpdateEquippedTrinkets()
            end
        elseif event == "UNIT_INVENTORY_CHANGED" then
            local unit = ...
            if unit == "player" then
                LCT:Debug("Player inventory changed")
                UpdateEquippedTrinkets()
            end
        elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
            LCT:Debug("Player entered world/logged in")
            -- Delay the check slightly to ensure all systems are ready
            C_Timer.After(0.5, function()
                UpdateEquippedTrinkets()
            end)
        end
    end)
    
    -- Do initial trinket check with a longer delay
    C_Timer.After(2, function()
        LCT:Debug("Performing initial trinket check")
        UpdateEquippedTrinkets()
    end)
end

-- Return the module
return items 