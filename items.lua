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

-- Function to check if an item is a PvP trinket
local function IsPvPTrinket(itemID)
    return PVP_TRINKETS[itemID] or false
end

-- Function to check trinket slots and register them for tracking
local function UpdateEquippedTrinkets()
    -- Check trinket slots
    for _, slot in ipairs(TRINKET_SLOTS) do
        local itemID = GetInventoryItemID("player", slot)
        if itemID and (IsPvPTrinket(itemID) or not IsPvPTrinket(itemID)) then
            LCT.cooldowns.RegisterItem(slot)
        end
    end
end

-- Initialize item tracking
function items.Initialize()
    -- Create initialization frame with unique name to avoid conflicts
    local initFrame = CreateFrame("Frame", nil, UIParent)
    initFrame:RegisterEvent("PLAYER_LOGIN")
    initFrame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_LOGIN" then
            -- Register equipment change events
            local eventFrame = CreateFrame("Frame", nil, UIParent)
            eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
            eventFrame:SetScript("OnEvent", function(_, event, slot)
                if slot == 13 or slot == 14 then
                    UpdateEquippedTrinkets()
                end
            end)
            
            -- Initial trinket check
            UpdateEquippedTrinkets()
            
            -- Cleanup
            self:UnregisterEvent("PLAYER_LOGIN")
        end
    end)
end

-- Return the module
return items 