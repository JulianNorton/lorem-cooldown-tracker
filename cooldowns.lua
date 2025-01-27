local addonName, LCT = ...

-- Cooldown tracking module
local cooldowns = {}
LCT.cooldowns = cooldowns

-- Tables to store active cooldowns
local activeCooldowns = {}
local trackedSpells = {}
local trackedItems = {}

-- Make tables accessible to other modules
LCT.activeCooldowns = activeCooldowns

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
        
        icon.texture = icon:CreateTexture(nil, "OVERLAY")
        icon.texture:SetAllPoints()
        
        local texture = isItem and GetItemIcon(id) or GetSpellTexture(id)
        if not texture then
            LCT:Debug("No texture found for", isItem and "item" or "spell", id)
            return nil
        end
        icon.texture:SetTexture(texture)
        
        icon.timeText = icon:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        icon.timeText:SetPoint("BOTTOM", icon, "BOTTOM", 0, -2)
        icon.timeText:SetShown(LCT.showTimeText)
        
        icon.isExistingCooldown = false
        icon:SetShown(LCT.showIcons)
        activeCooldowns[id] = icon
        LCT:Debug("Created new icon for", isItem and "item" or "spell", id)
    end
    return activeCooldowns[id]
end

-- Function to update a cooldown
function cooldowns.UpdateCooldown(id, isItem)
    if not id then return end
    
    local start, duration, enabled
    if isItem then
        start, duration, enabled = C_Container.GetItemCooldown(id)
        if not start then return end
    else
        start, duration, enabled = GetSpellCooldown(id)
    end
    
    if enabled == 0 then return end
    
    local icon = GetCooldownIcon(id, isItem)
    if not icon then return end
    
    if start > 0 and duration > 0 then
        local currentTime = GetTime()
        local remaining = (start + duration) - currentTime
        
        -- Skip very short cooldowns
        if duration < 5 then
            LCT.animations.CancelAnimation(icon)
            icon:Hide()
            return
        end
        
        -- Start freeze-fade animation when cooldown ends
        if remaining <= 0 then
            if icon:IsVisible() then
                LCT.animations.StartFinishAnimation(icon)
            end
            return
        end
        
        -- Calculate position
        local width = LCT.frame:GetWidth()
        local iconSize = LCT.iconSize
        
        -- Clamp remaining time to maxTime (default 300s = 5min)
        remaining = math.min(remaining, LCT.maxTime)
        
        -- Calculate the actual position
        local xPos = (remaining / LCT.maxTime) * (width - iconSize) + (iconSize/2)
        
        -- Only update if position changed significantly or icon is not visible
        if not icon:IsVisible() then
            icon:ClearAllPoints()
            icon:SetPoint("CENTER", LCT.frame, "LEFT", xPos, 0)
            icon:Show()
        else
            local _, _, _, oldX = icon:GetPoint()
            if not oldX or math.abs(oldX - xPos) > 0.5 then
                icon:ClearAllPoints()
                icon:SetPoint("CENTER", LCT.frame, "LEFT", xPos, 0)
            end
        end
        
        -- Update time text only if it changed
        local timeText = FormatTimeText(remaining)
        if icon.timeText:GetText() ~= timeText then
            icon.timeText:SetText(timeText)
        end
    else
        LCT.animations.CancelAnimation(icon)
        icon:Hide()
    end
end

-- Function to update all cooldowns
function cooldowns.UpdateAll()
    -- Use a throttle to prevent too frequent updates
    local now = GetTime()
    if cooldowns.lastUpdate and (now - cooldowns.lastUpdate) < 0.1 then
        return
    end
    cooldowns.lastUpdate = now
    
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
    
    -- Check for existing cooldowns on tracked spells/items
    local function CheckExistingCooldowns()
        -- Check spells
        for spellID in pairs(trackedSpells) do
            local start, duration = GetSpellCooldown(spellID)
            if start and start > 0 and duration > 0 then
                local currentTime = GetTime()
                local remaining = (start + duration) - currentTime
                if remaining > 0 then
                    cooldowns.UpdateCooldown(spellID, false)
                end
            end
        end
        
        -- Check items
        for itemID in pairs(trackedItems) do
            local start, duration = C_Container.GetItemCooldown(itemID)
            if start and start > 0 and duration > 0 then
                local currentTime = GetTime()
                local remaining = (start + duration) - currentTime
                if remaining > 0 then
                    cooldowns.UpdateCooldown(itemID, true)
                end
            end
        end
    end
    
    -- Set up OnUpdate script with fixed update frequency (10 updates per second)
    local updateElapsed = 0
    local UPDATE_FREQUENCY = 0.1  -- 100ms = 10 updates per second
    
    LCT.frame:SetScript("OnUpdate", function(self, elapsed)
        updateElapsed = updateElapsed + elapsed
        
        -- Skip update if not enough time has passed
        if updateElapsed < UPDATE_FREQUENCY then
            return
        end
        
        -- Update all cooldowns
        cooldowns.UpdateAll()
        
        -- Reset elapsed time
        updateElapsed = 0
    end)
    
    -- Initial check after a short delay to ensure everything is loaded
    C_Timer.After(0.5, CheckExistingCooldowns)
end

-- Return the module
return cooldowns 