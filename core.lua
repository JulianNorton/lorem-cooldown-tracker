-- Create addon namespace
local addonName, LCT = ...
LCT.version = "0.1.0-alpha"

-- Main frame
local frame = CreateFrame("Frame", "LoremCTFrame", UIParent)
LCT.frame = frame  -- Make frame accessible to settings.lua

-- Set frame properties
frame:SetSize(300, 30)  -- Width: 300, Height: 30
frame:SetPoint("CENTER") -- Position in center of screen
frame:SetMovable(true)
frame:EnableMouse(true)

-- Add frame locking property
frame.locked = false

-- Modify dragging behavior to respect lock
frame:SetScript("OnMouseDown", function(self, button)
    if not self.locked and button == "LeftButton" then
        self:StartMoving()
    end
end)
frame:SetScript("OnMouseUp", function(self)
    self:StopMovingOrSizing()
end)

-- Create timeline background
frame.bg = frame:CreateTexture(nil, "BACKGROUND")
frame.bg:SetAllPoints()
frame.bg:SetColorTexture(0, 0, 0, 0.5)

-- Table to store active cooldowns
local activeCooldowns = {}
LCT.activeCooldowns = activeCooldowns  -- Make accessible to settings.lua
local trackedSpells = {}

-- Set default icon size
LCT.iconSize = 24
LCT.showTimeText = true
LCT.showIcons = true

-- Function to create or get cooldown icon
local function GetCooldownIcon(spellID)
    if not activeCooldowns[spellID] then
        local icon = CreateFrame("Frame", nil, frame)
        icon:SetSize(LCT.iconSize, LCT.iconSize)
        
        icon.texture = icon:CreateTexture(nil, "OVERLAY")
        icon.texture:SetAllPoints()
        icon.texture:SetTexture(GetSpellTexture(spellID))
        
        -- Add spell name tooltip
        icon:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetSpellByID(spellID)
            GameTooltip:Show()
        end)
        icon:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        
        icon.timeText = icon:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        icon.timeText:SetPoint("BOTTOM", icon, "BOTTOM", 0, -2)
        icon.timeText:SetShown(LCT.showTimeText)
        
        icon:SetShown(LCT.showIcons)
        activeCooldowns[spellID] = icon
    end
    return activeCooldowns[spellID]
end

-- Basic cooldown tracking function
local function UpdateCooldown(spellID)
    local start, duration, enabled = GetSpellCooldown(spellID)
    if enabled == 0 then return end
    
    local icon = GetCooldownIcon(spellID)
    
    if start > 0 and duration > 0 then
        local remaining = start + duration - GetTime()
        
        -- Skip very short cooldowns (< 5s)
        if duration < 5 then
            LCT.animations.CancelAnimation(icon)
            icon:Hide()
            return
        end
        
        if remaining > 0 then
            -- Handle long cooldowns (> 10 minutes)
            if remaining > 600 then
                -- Position at far right until 10 minutes remain
                icon:ClearAllPoints()
                icon:SetPoint("LEFT", frame, "LEFT", frame:GetWidth() - icon:GetWidth(), 0)
                icon:Show()
                icon.timeText:SetText(string.format("%.0fm", remaining/60))
                return
            end
            
            -- Calculate position based on absolute remaining time
            -- 0s = left edge, 600s (10min) = right edge
            local width = frame:GetWidth() - icon:GetWidth()
            local xPos = (remaining / 600) * width
            
            -- Start position animation
            LCT.animations.StartPositionAnimation(icon, xPos)
            
            -- Update time text
            if remaining > 60 then
                icon.timeText:SetText(string.format("%.0fm", remaining/60))
            else
                icon.timeText:SetText(string.format("%.1f", remaining))
            end
            
            -- Show icon if hidden
            if not icon:IsVisible() then
                icon:Show()
                icon:ClearAllPoints()
                icon:SetPoint("LEFT", frame, "LEFT", xPos, 0)
            end
        else
            LCT.animations.CancelAnimation(icon)
            icon:Hide()
        end
    else
        LCT.animations.CancelAnimation(icon)
        icon:Hide()
    end
end

-- Function to scan spellbook and build list of trackable spells
local function ScanSpellBook()
    local _, playerClass = UnitClass("player")
    trackedSpells = {}
    
    -- Scan all spellbook tabs
    for tabIndex = 1, GetNumSpellTabs() do
        local _, _, offset, numSpells = GetSpellTabInfo(tabIndex)
        
        -- Scan all spells in current tab
        for spellIndex = offset + 1, offset + numSpells do
            local spellType, spellID = GetSpellBookItemInfo(spellIndex, "player")
            if spellType == "SPELL" and spellID then
                local cooldown = GetSpellBaseCooldown(spellID)
                -- Only track spells with cooldowns between 5s and GCD
                if cooldown and cooldown > 5000 then
                    trackedSpells[spellID] = true
                end
            end
        end
    end
end

-- Update all tracked cooldowns
local function UpdateAllCooldowns()
    for spellID in pairs(trackedSpells) do
        UpdateCooldown(spellID)
    end
end

-- Register all necessary events
frame:RegisterEvent("SPELLS_CHANGED")
frame:RegisterEvent("LEARNED_SPELL_IN_TAB")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")

-- Update event handler
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" or event == "SPELLS_CHANGED" or event == "LEARNED_SPELL_IN_TAB" then
        ScanSpellBook()
    end
    
    if event == "PLAYER_LOGIN" then
        ScanSpellBook()
        UpdateAllCooldowns()
    elseif event == "SPELL_UPDATE_COOLDOWN" then
        UpdateAllCooldowns()
    end
end)

-- Update OnUpdate script
local updateElapsed = 0
local UPDATE_FREQUENCY = 0.1 -- Update cooldowns every 100ms
frame:SetScript("OnUpdate", function(self, elapsed)
    updateElapsed = updateElapsed + elapsed
    if updateElapsed >= UPDATE_FREQUENCY then
        UpdateAllCooldowns()
        updateElapsed = 0
    end
end)

-- Modify slash command to include visibility toggle
SLASH_LCT1 = "/lct"
SlashCmdList["LCT"] = function(msg)
    if msg == "scan" then
        ScanSpellBook()
        print("LoremCT: Rescanned spellbook")
    elseif msg == "lock" then
        frame.locked = not frame.locked
        frame:EnableMouse(not frame.locked)
        print("LoremCT: Frame " .. (frame.locked and "locked" or "unlocked"))
    elseif msg == "toggle" then
        if frame:IsVisible() then
            frame:Hide()
            print("LoremCT: Frame hidden")
        else
            frame:Show()
            print("LoremCT: Frame shown")
        end
    else
        if LCT.settingsFrame:IsShown() then
            LCT.settingsFrame:Hide()
        else
            LCT.settingsFrame:Show()
        end
    end
end 