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
        icon.texture:SetTexture(isItem and GetItemIcon(id) or GetSpellTexture(id))
        
        -- Add tooltip
        icon:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            if isItem then
                GameTooltip:SetItemByID(id)
            else
                GameTooltip:SetSpellByID(id)
            end
            GameTooltip:Show()
        end)
        icon:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        
        icon.timeText = icon:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        icon.timeText:SetPoint("BOTTOM", icon, "BOTTOM", 0, -2)
        icon.timeText:SetShown(LCT.showTimeText)
        
        icon:SetShown(LCT.showIcons)
        activeCooldowns[id] = icon
    end
    return activeCooldowns[id]
end

-- Function to update a cooldown
function cooldowns.UpdateCooldown(id, isItem)
    local start, duration, enabled
    if isItem then
        start, duration, enabled = C_Container.GetItemCooldown(id)
        if not start then return end
    else
        start, duration, enabled = GetSpellCooldown(id)
    end
    
    if enabled == 0 then return end
    
    local icon = GetCooldownIcon(id, isItem)
    
    if start > 0 and duration > 0 then
        local remaining = start + duration - GetTime()
        
        -- Skip very short cooldowns
        if duration < 5 then
            LCT.animations.CancelAnimation(icon)
            icon:Hide()
            return
        end
        
        -- Start finish animation slightly before cooldown ends
        if remaining <= 0.2 and remaining > 0 then
            if icon:IsVisible() then
                LCT.animations.StartFinishAnimation(icon)
            end
            return
        end
        
        if remaining > 0 then
            -- Handle long cooldowns
            if remaining > LCT.maxTime then
                icon:ClearAllPoints()
                icon:SetPoint("LEFT", LCT.frame, "LEFT", LCT.frame:GetWidth() - LCT.iconSize, 0)
                icon:Show()
                icon.timeText:SetText(FormatTimeText(remaining))
                return
            end
            
            -- Calculate position
            local width = LCT.frame:GetWidth() - LCT.iconSize
            local xPos = (remaining / LCT.maxTime) * width
            
            if not icon:IsVisible() then
                icon:ClearAllPoints()
                icon:SetPoint("LEFT", LCT.frame, "LEFT", xPos, 0)
                icon:Show()
            else
                LCT.animations.StartPositionAnimation(icon, xPos)
            end
            
            icon.timeText:SetText(FormatTimeText(remaining))
        else
            LCT.animations.CancelAnimation(icon)
            icon:Hide()
        end
    else
        LCT.animations.CancelAnimation(icon)
        icon:Hide()
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

-- Function to register an item
function cooldowns.RegisterItem(itemID)
    trackedItems[itemID] = true
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
    -- Set up OnUpdate script
    local updateElapsed = 0
    LCT.frame:SetScript("OnUpdate", function(self, elapsed)
        updateElapsed = updateElapsed + elapsed
        if updateElapsed >= LCT.updateFrequency then
            cooldowns.UpdateAll()
            updateElapsed = 0
        end
    end)
end

-- Return the module
return cooldowns 