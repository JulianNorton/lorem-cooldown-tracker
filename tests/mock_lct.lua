-- Mock LCT addon environment
local LCT = {
    maxTime = 300,  -- 5 minutes in seconds
    defaults = {
        updateFrequency = 0.1
    },
    animations = {
        active = {},
        OnFinish = function() end,
        
        CalculatePosition = function(remaining, duration, width, iconSize, isReversed)
            if not remaining or remaining < 0 then
                if LCT.animations.OnFinish then
                    LCT.animations.OnFinish()
                end
                return isReversed and iconSize/2 or width - iconSize/2
            end
            
            -- Calculate progress (0 to 1)
            local progress = 1 - (remaining / duration)
            
            -- Calculate position
            local usableWidth = width - iconSize
            local basePosition = progress * usableWidth
            
            -- Add half icon size to center the icon
            local position = basePosition + iconSize/2
            
            -- Reverse if needed
            if isReversed then
                position = width - position
            end
            
            return position
        end,
        
        StartAnimation = function(frame, duration, isReversed)
            local anim = {
                frame = frame,
                startTime = GetTime(),
                duration = duration,
                isReversed = isReversed,
                Update = function(self)
                    local currentTime = GetTime()
                    local elapsed = currentTime - self.startTime
                    local remaining = self.duration - elapsed
                    
                    local position = LCT.animations.CalculatePosition(
                        remaining,
                        self.duration,
                        frame:GetParent():GetWidth(),
                        LCT.iconSize,
                        self.isReversed
                    )
                    
                    if position then
                        frame:ClearAllPoints()
                        frame:SetPoint("CENTER", frame:GetParent(), "LEFT", position, 0)
                    end
                    
                    return remaining > 0
                end
            }
            
            LCT.animations.active[frame] = anim
            return anim
        end,
        
        StopAnimation = function(frame)
            LCT.animations.active[frame] = nil
        end,
        
        UpdateAll = function()
            for frame, anim in pairs(LCT.animations.active) do
                if not anim:Update() then
                    LCT.animations.active[frame] = nil
                end
            end
        end
    },
    frame = CreateFrame("Frame"),
    iconSize = 32,
    Debug = function(...) end,
    cooldowns = {
        trackedItems = {},
        trackedSpells = {},
        activeCooldowns = {},
        itemSlots = {},  -- Map of slot IDs to item IDs
        pvpTrinkets = {
            [18854] = true,  -- Alliance Insignia
            [18864] = true,  -- Horde Insignia
        },
        RegisterItem = function(slot)
            if type(slot) == "number" then
                local itemID = GetInventoryItemID("player", slot)
                if itemID then
                    -- Always track PvP trinkets
                    if LCT.cooldowns.pvpTrinkets[itemID] then
                        LCT.cooldowns.trackedItems[slot] = true
                        LCT.cooldowns.itemSlots[slot] = itemID
                        return
                    end
                    
                    -- Check if other items have a usable effect
                    local start, duration, enabled = GetInventoryItemCooldown("player", slot)
                    if enabled == 1 then  -- Only track items that can have cooldowns
                        LCT.cooldowns.trackedItems[slot] = true
                        LCT.cooldowns.itemSlots[slot] = itemID
                    end
                end
            end
        end,
        RegisterSpell = function(spellID)
            LCT.cooldowns.trackedSpells[spellID] = true
        end,
        UnregisterItem = function(slot)
            LCT.cooldowns.trackedItems[slot] = nil
            LCT.cooldowns.activeCooldowns[slot] = nil
            LCT.cooldowns.itemSlots[slot] = nil
        end,
        UnregisterSpell = function(spellID)
            LCT.cooldowns.trackedSpells[spellID] = nil
            LCT.cooldowns.activeCooldowns[spellID] = nil
        end,
        Initialize = function()
            LCT:Debug("Initializing cooldown tracking")
        end,
        UpdateAll = function()
            -- Update all tracked items
            for slot in pairs(LCT.cooldowns.trackedItems) do
                local remaining = LCT.cooldowns.UpdateCooldown(slot, true)
                if remaining then
                    LCT.cooldowns.activeCooldowns[slot] = remaining
                else
                    LCT.cooldowns.activeCooldowns[slot] = nil
                end
            end
            -- Update all tracked spells
            for spellID in pairs(LCT.cooldowns.trackedSpells) do
                local remaining = LCT.cooldowns.UpdateCooldown(spellID, false)
                if remaining then
                    LCT.cooldowns.activeCooldowns[spellID] = remaining
                else
                    LCT.cooldowns.activeCooldowns[spellID] = nil
                end
            end
        end,
        UpdateCooldown = function(id, isItem)
            if isItem then
                local itemID = LCT.cooldowns.itemSlots[id]
                if not itemID then
                    return nil
                end
                
                -- Special handling for PvP trinkets
                if LCT.cooldowns.pvpTrinkets[itemID] then
                    local start, duration, enabled = GetInventoryItemCooldown("player", id)
                    if not start then return nil end
                    
                    if start > 0 and duration > 0 then
                        local currentTime = GetTime()
                        local remaining = (start + duration) - currentTime
                        if remaining <= 0 then
                            return nil
                        end
                        return remaining
                    end
                    return nil
                end
                
                -- Normal trinket handling
                local start, duration, enabled = GetInventoryItemCooldown("player", id)
                if not start or enabled == 0 then 
                    return nil
                end
                
                local icon = GetCooldownIcon(itemID)
                if not icon then 
                    return nil
                end
                
                if start > 0 and duration > 0 then
                    local currentTime = GetTime()
                    local remaining = (start + duration) - currentTime
                    if remaining <= 0 then
                        return nil
                    end
                    return remaining
                end
            end
            return nil
        end
    },
    items = {
        Initialize = function()
            LCT.items.UpdateEquippedTrinkets()
        end,
        UpdateEquippedTrinkets = function()
            -- First unregister all trinkets
            LCT.cooldowns.UnregisterItem(13)
            LCT.cooldowns.UnregisterItem(14)
            -- Then register currently equipped ones
            for _, slot in ipairs({13, 14}) do
                local itemID = GetInventoryItemID("player", slot)
                if itemID then
                    LCT.cooldowns.RegisterItem(slot)
                end
            end
        end
    }
}

-- Set up frame methods
LCT.frame.GetWidth = function() return 300 end
LCT.frame.GetHeight = function() return 32 end

return LCT 