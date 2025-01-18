-- Create addon namespace
local addonName, LCT = ...
LCT.version = "0.1.0-alpha"

-- Set default options
LCT.defaults = {
    iconSize = 24,
    showTimeText = true,
    showIcons = true,
    maxTime = 300, -- 5 minutes
    updateFrequency = 0.1
}

-- Initialize current settings from defaults
for key, value in pairs(LCT.defaults) do
    LCT[key] = value
end

-- Main frame
local frame = CreateFrame("Frame", "LoremCTFrame", UIParent)
LCT.frame = frame  -- Make frame accessible to other modules

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

-- Basic slash command registration
SLASH_LCT1 = "/lct"
SlashCmdList["LCT"] = function(msg)
    if msg == "scan" then
        LCT.ScanSpellBook()
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
        if LCT.settingsFrame and LCT.settingsFrame:IsShown() then
            LCT.settingsFrame:Hide()
        elseif LCT.settingsFrame then
            LCT.settingsFrame:Show()
        end
    end
end 