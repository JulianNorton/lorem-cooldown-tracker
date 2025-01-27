local addonName, LCT = ...

-- Item tracking module
local items = {}
LCT.items = items

-- Constants
local TRINKET_SLOTS = {13, 14}  -- First and second trinket slots
local PVP_TRINKETS = {
    [18854] = true, -- Insignia of the Alliance
    [18863] = true, -- Insignia of the Alliance (Druid)
    [18864] = true  -- Insignia of the Horde
}

-- Function to clean up unequipped trinkets
local function CleanupTrinkets()
    for itemID in pairs(LCT.cooldowns.trackedItems) do
        -- Skip hardcoded items (like PvP trinkets)
        if not PVP_TRINKETS[itemID] then
            -- Check if item is still equipped
            local isEquipped = false
            for _, slot in ipairs(TRINKET_SLOTS) do
                local equippedID = GetInventoryItemID("player", slot)
                if itemID == equippedID then
                    isEquipped = true
                    break
                end
            end
            
            -- Unregister if not equipped
            if not isEquipped then
                LCT.cooldowns.UnregisterItem(itemID)
            end
        end
    end
end

-- Function to check trinket slots and register them for tracking
local function UpdateEquippedTrinkets()
    -- Check trinket slots
    for _, slot in ipairs(TRINKET_SLOTS) do
        local itemID = GetInventoryItemID("player", slot)
        if itemID then
            LCT.cooldowns.RegisterItem(itemID)
        end
    end
    
    -- Clean up any unequipped trinkets
    CleanupTrinkets()
end

-- Initialize item tracking
function items.Initialize()
    -- Register PvP trinkets
    for itemID in pairs(PVP_TRINKETS) do
        LCT.cooldowns.RegisterItem(itemID)
    end
    
    -- Register equipment change events
    LCT.frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    LCT.frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
    
    -- Set up event handler
    LCT.frame:HookScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_EQUIPMENT_CHANGED" or event == "UNIT_INVENTORY_CHANGED" then
            local unit = ...
            if not unit or unit == "player" then
                UpdateEquippedTrinkets()
            end
        elseif event == "PLAYER_LOGIN" then
            UpdateEquippedTrinkets()
        end
    end)
end

-- Return the module
return items 