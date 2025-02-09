local addonName, LCT = ...

-- Cooldown tracking module
local cooldowns = {}
LCT.cooldowns = cooldowns

-- Tables to store active cooldowns
local activeCooldowns = {}
local trackedSpells = {}
local trackedItems = {}
local activeCooldownList = {} -- Track which cooldowns are currently active

-- Make tables accessible to other modules
LCT.activeCooldowns = activeCooldowns
LCT.cooldowns.trackedItems = trackedItems  -- Expose trackedItems table

-- Determine which item cooldown API to use based on WoW version
local GetItemCooldownFunc
if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
    -- Classic Era
    GetItemCooldownFunc = function(id)
        return GetSpellItemCooldown(id)  -- This is the correct API for Classic Era
    end
else
    -- Retail or other versions
    GetItemCooldownFunc = C_Item and C_Item.GetItemCooldown or GetItemCooldown
end

-- Function to format time text
local function FormatTimeText(remaining)
    if remaining > 60 then
        return string.format("%.0fm", remaining/60)
    elseif remaining > 10 then
        return string.format("%.0f", remaining)
    else
        return string.format("%.1f", remaining)
    end
end

-- Function to create or get cooldown icon
local function GetCooldownIcon(id, isItem)
    if not activeCooldowns[id] then
        local icon = CreateFrame("Frame", nil, LCT.frame)
        icon:SetSize(LCT.iconSize, LCT.iconSize)
        
        -- Create cooldown texture
        icon.texture = icon:CreateTexture(nil, "ARTWORK")
        icon.texture:SetAllPoints()
        
        -- Get the correct texture
        local texture
        if isItem then
            -- For equipped items, get the item texture from the inventory slot
            texture = GetInventoryItemTexture("player", id)
        else
            texture = GetSpellTexture(id)
        end
        
        if not texture then
            LCT:Debug("No texture found for", isItem and "item" or "spell", id)
            return nil
        end
        
        icon.texture:SetTexture(texture)
        
        -- Create cooldown model
        icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
        icon.cooldown:SetAllPoints()
        icon.cooldown:SetDrawEdge(true)
        icon.cooldown:SetDrawSwipe(true)
        
        -- Create time text
        icon.timeText = icon:CreateFontString(nil, "OVERLAY")
        icon.timeText:SetFontObject("GameFontNormalSmall")
        icon.timeText:SetPoint("BOTTOM", icon, "BOTTOM", 0, 2)
        icon.timeText:SetShown(LCT.showTimeText)
        
        activeCooldowns[id] = icon
        LCT:Debug("Created new icon for", isItem and "item slot" or "spell", id)
    end
    
    return activeCooldowns[id]
end

-- Function to update a cooldown
function cooldowns.UpdateCooldown(id, isItem)
    if not id then return end
    
    local start, duration, enabled
    if isItem then
        start, duration, enabled = GetInventoryItemCooldown("player", id)
        if not start or not duration then return end
        
        -- Only update if there's an actual cooldown or if we need to hide the icon
        if (start == 0 and duration == 0) or enabled == 0 then
            if activeCooldowns[id] then
                activeCooldowns[id]:Hide()
                activeCooldownList[id] = nil -- Remove from active tracking
            end
            return
        end
    else
        start, duration, enabled = GetSpellCooldown(id)
        if not start or enabled == 0 then return end
    end
    
    local icon = GetCooldownIcon(id, isItem)
    if not icon then return end
    
    if start > 0 and duration > 1.5 then -- Only track cooldowns longer than 1.5 seconds
        local currentTime = GetTime()
        local remaining = (start + duration) - currentTime
        
        if remaining <= 0 then
            if icon:IsVisible() then
                LCT.animations.StartFinishAnimation(icon)
                activeCooldownList[id] = nil -- Remove from active tracking
            end
            return
        end
        
        -- Add to active cooldown list if not already there
        if not activeCooldownList[id] then
            activeCooldownList[id] = {
                start = start,
                duration = duration,
                isItem = isItem
            }
        end
        
        -- Calculate position
        local width = LCT.frame:GetWidth()
        local iconSize = LCT.iconSize
        
        -- Clamp remaining time to maxTime (default 300s = 5min)
        remaining = math.min(remaining, LCT.maxTime)
        
        -- Calculate the actual position
        local xPos = (remaining / LCT.maxTime) * (width - iconSize) + (iconSize/2)
        
        -- Update position and show icon
        icon:ClearAllPoints()
        icon:SetPoint("CENTER", LCT.frame, "LEFT", xPos, 0)
        icon:Show()
        
        -- Update cooldown swipe
        if icon.cooldown then
            icon.cooldown:SetCooldown(start, duration)
        end
        
        -- Update time text
        icon.timeText:SetText(FormatTimeText(remaining))
    else
        LCT.animations.CancelAnimation(icon)
        icon:Hide()
        activeCooldownList[id] = nil -- Remove from active tracking
    end
end

-- Function to update all cooldowns
function cooldowns.UpdateAll()
    for spellID in pairs(trackedSpells) do
        cooldowns.UpdateCooldown(spellID, false)
    end
    for itemID in pairs(trackedItems) do
        cooldowns.UpdateCooldown(itemID, true)
    end
end

-- Function to register a spell
function cooldowns.RegisterSpell(spellID)
    if not spellID then return end
    trackedSpells[spellID] = true
    local name = GetSpellInfo(spellID)
    LCT:Debug("Registered spell:", spellID, name)
end

-- Function to unregister a spell
function cooldowns.UnregisterSpell(spellID)
    trackedSpells[spellID] = nil
    if activeCooldowns[spellID] then
        activeCooldowns[spellID]:Hide()
        activeCooldowns[spellID] = nil
    end
end

-- Function to register an item
function cooldowns.RegisterItem(itemID)
    if not itemID then return end
    trackedItems[itemID] = true
    local name = GetItemInfo(itemID)
    LCT:Debug("Registered item:", itemID, name)
end

-- Function to unregister an item
function cooldowns.UnregisterItem(itemID)
    trackedItems[itemID] = nil
    if activeCooldowns[itemID] then
        activeCooldowns[itemID]:Hide()
        activeCooldowns[itemID] = nil
    end
end

-- Initialize cooldown tracking
function cooldowns.Initialize()
    LCT:Debug("Initializing cooldown tracking")
    
    -- Create event frame for cooldown updates
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    eventFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    eventFrame:RegisterEvent("ITEM_LOCK_CHANGED")
    eventFrame:RegisterEvent("BAG_UPDATE_COOLDOWN")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    
    -- Add OnUpdate for active cooldowns
    local updateElapsed = 0
    eventFrame:SetScript("OnUpdate", function(self, elapsed)
        updateElapsed = updateElapsed + elapsed
        if updateElapsed >= 0.1 then -- Update active cooldowns every 0.1 seconds
            for id, info in pairs(activeCooldownList) do
                cooldowns.UpdateCooldown(id, info.isItem)
            end
            updateElapsed = 0
        end
    end)
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "SPELL_UPDATE_COOLDOWN" or 
           event == "ACTIONBAR_UPDATE_COOLDOWN" or
           event == "BAG_UPDATE_COOLDOWN" then
            cooldowns.UpdateAll()
        elseif event == "ITEM_LOCK_CHANGED" then
            local bagOrSlot, slot = ...
            -- If it's an equipped item (slot is nil)
            if not slot and bagOrSlot >= 13 and bagOrSlot <= 14 then
                cooldowns.UpdateCooldown(bagOrSlot, true)
            end
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            local unit, _, spellID = ...
            if unit == "player" and trackedSpells[spellID] then
                -- Force an immediate update for this spell
                cooldowns.UpdateCooldown(spellID, false)
            end
        end
    end)
    
    -- Initial check after a short delay
    C_Timer.After(0.5, cooldowns.UpdateAll)
end

-- Return the module
return cooldowns 