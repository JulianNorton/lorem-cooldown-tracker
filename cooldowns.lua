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

-- Function to get item cooldown using inventory API
local function GetItemCooldown(id)
    if not id then return 0, 0, 1 end -- Safe default if id is nil
    -- For equipped items, we can use the inventory cooldown API
    return GetInventoryItemCooldown("player", id)
end

-- Function to format time text
local function FormatTimeText(remaining)
    if not remaining or type(remaining) ~= "number" then return "0.0" end
    if remaining >= 300 then  -- 300 seconds = 5 minutes
        return "5m+"
    elseif remaining > 60 then
        return string.format("%.0fm", remaining/60)
    elseif remaining > 10 then
        return string.format("%.0f", remaining)
    else
        return string.format("%.1f", remaining)
    end
end

-- Function to safely create or get cooldown icon
function GetCooldownIcon(id, isItem)
    -- Ensure we have a valid id and main frame
    if not id or not LCT.frame then return nil end
    
    if not LCT.cooldowns.activeCooldowns[id] then
        -- Create frame only if main frame exists and is initialized
        local success, icon = pcall(function()
            local icon = CreateFrame("Frame", nil, LCT.frame, "BackdropTemplate")
            if not icon then return nil end
            
            icon:SetSize(LCT.iconSize or 32, LCT.iconSize or 32)
            icon:SetFrameStrata("MEDIUM")
            icon:SetFrameLevel(2)  -- One level above the main frame
            icon:SetClampedToScreen(true)
            icon:EnableMouse(true)
            
            -- Set initial position (will be updated by animation)
            icon:ClearAllPoints()
            icon:SetPoint("CENTER", LCT.frame, "LEFT", (LCT.iconSize or 32)/2, 0)
            
            -- Set backdrop for icon border
            if icon.SetBackdrop then  -- Check if backdrop API is available
                icon:SetBackdrop({
                    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    tile = true,
                    tileSize = 16,
                    edgeSize = 16,
                    insets = { left = 4, right = 4, top = 4, bottom = 4 }
                })
                icon:SetBackdropColor(0, 0, 0, 0)  -- Transparent background
                icon:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
            end
            
            -- Create icon texture
            icon.texture = icon:CreateTexture(nil, "ARTWORK")
            if not icon.texture then return nil end
            icon.texture:SetAllPoints()
            
            -- Get appropriate texture
            local texture
            if isItem then
                texture = GetInventoryItemTexture("player", id) or GetItemIcon(id)
            else
                texture = GetSpellTexture(id)
            end
            
            if not texture then
                return nil
            end
            icon.texture:SetTexture(texture)
            
            -- Create time text
            icon.timeText = icon:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            if not icon.timeText then return nil end
            icon.timeText:SetPoint("BOTTOM", icon, "BOTTOM", 0, -2)
            
            -- Create tooltip handling
            icon:SetScript("OnEnter", function(self)
                if not self:IsVisible() then return end
                GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
                if isItem then
                    GameTooltip:SetInventoryItem("player", id)
                else
                    GameTooltip:SetSpellByID(id)
                end
                GameTooltip:Show()
            end)
            
            icon:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            
            -- Register for parent's events only if we can
            if icon.RegisterEvent then
                icon:RegisterEvent("PLAYER_ENTERING_WORLD")
                icon:RegisterEvent("PLAYER_LEAVING_WORLD")
                icon:SetScript("OnEvent", function(self, event)
                    if not self or not self:IsShown() then return end
                    -- Ensure proper cleanup and state management
                    if event == "PLAYER_LEAVING_WORLD" then
                        self:Hide()
                    elseif event == "PLAYER_ENTERING_WORLD" then
                        -- Re-check cooldown state
                        cooldowns.UpdateCooldown(id, isItem)
                    end
                end)
            end
            
            icon:Show()
            return icon
        end)
        
        if success and icon then
            LCT.cooldowns.activeCooldowns[id] = icon
        else
            return nil
        end
    end
    return LCT.cooldowns.activeCooldowns[id]
end

-- Function to update a cooldown
function cooldowns.UpdateCooldown(slot, isItem)
    if not isItem then
        -- Handle spell cooldowns as before
        local start, duration, enabled = GetSpellCooldown(slot)
        if not start then return end
        
        local icon = GetCooldownIcon(slot, false)
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
            
            -- Clamp remaining time to maxTime
            remaining = math.min(remaining, LCT.maxTime)
            
            -- Update frame level based on remaining time
            -- Base frame level is 50-95, with special handling for last 10 seconds
            local frameLevel
            if remaining <= 10 then
                -- Last 10 seconds get extra granular frame levels (95-195)
                -- This ensures that 0.5s is above 1s, etc.
                frameLevel = 95 + math.floor((10 - remaining) * 10)
            else
                -- Normal frame level calculation for longer cooldowns
                frameLevel = 50 + math.floor((LCT.maxTime - remaining) / LCT.maxTime * 45)
            end
            icon:SetFrameLevel(frameLevel)
            
            -- Calculate the actual position
            local xPos
            if LCT.reverseTimeline then
                -- Reversed: high time on left, low time on right
                xPos = ((LCT.maxTime - remaining) / LCT.maxTime) * (width - iconSize) + (iconSize/2)
            else
                -- Normal: low time on left, high time on right
                xPos = (remaining / LCT.maxTime) * (width - iconSize) + (iconSize/2)
            end
            
            -- Use animation system for smooth movement
            LCT.animations.StartPositionAnimation(icon, xPos, remaining)
            
            -- Update time text
            icon.timeText:SetText(FormatTimeText(remaining))
        else
            LCT.animations.CancelAnimation(icon)
            icon:Hide()
        end
    else
        -- For items, use inventory slot directly
        local start, duration, enabled = GetInventoryItemCooldown("player", slot)
        if not start or enabled == 0 then return end
        
        local icon = GetCooldownIcon(slot, true)
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
            
            -- Clamp remaining time to maxTime
            remaining = math.min(remaining, LCT.maxTime)
            
            -- Update frame level based on remaining time
            -- Base frame level is 50-95, with special handling for last 10 seconds
            local frameLevel
            if remaining <= 10 then
                -- Last 10 seconds get extra granular frame levels (95-195)
                -- This ensures that 0.5s is above 1s, etc.
                frameLevel = 95 + math.floor((10 - remaining) * 10)
            else
                -- Normal frame level calculation for longer cooldowns
                frameLevel = 50 + math.floor((LCT.maxTime - remaining) / LCT.maxTime * 45)
            end
            icon:SetFrameLevel(frameLevel)
            
            -- Calculate the actual position
            local xPos
            if LCT.reverseTimeline then
                -- Reversed: high time on left, low time on right
                xPos = ((LCT.maxTime - remaining) / LCT.maxTime) * (width - iconSize) + (iconSize/2)
            else
                -- Normal: low time on left, high time on right
                xPos = (remaining / LCT.maxTime) * (width - iconSize) + (iconSize/2)
            end
            
            -- Use animation system for smooth movement
            LCT.animations.StartPositionAnimation(icon, xPos, remaining)
            
            -- Update time text
            icon.timeText:SetText(FormatTimeText(remaining))
        else
            LCT.animations.CancelAnimation(icon)
            icon:Hide()
        end
    end
end

-- Function to update all cooldowns
function cooldowns.UpdateAll()
    -- Update spells
    for spellID in pairs(trackedSpells) do
        cooldowns.UpdateCooldown(spellID, false)
    end
    -- Update trinket slots
    cooldowns.UpdateCooldown(13, true)
    cooldowns.UpdateCooldown(14, true)
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
    
    -- Create a frame for initialization events
    local initFrame = CreateFrame("Frame")
    initFrame:RegisterEvent("PLAYER_LOGIN")
    initFrame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_LOGIN" then
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
                    local start, duration = GetItemCooldown(itemID)
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
            
            -- Cleanup
            self:UnregisterEvent("PLAYER_LOGIN")
        end
    end)
end

-- Return the module
return cooldowns 