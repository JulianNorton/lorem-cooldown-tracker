local addonName, LCT = ...

-- Initialize settings namespace
LCT.settings = {}

-- Function to save dimension settings
local function SaveDimensionSettings()
    if not LoremCTDB then LoremCTDB = {} end
    if not LoremCTDB.dimensions then LoremCTDB.dimensions = {} end
    
    -- Save current settings
    local settings = LoremCTDB.dimensions
    settings.barWidth = LCT.frame:GetWidth()
    settings.barHeight = LCT.frame:GetHeight()
    settings.iconSize = LCT.iconSize
    settings.locked = LCT.frame.locked
    settings.reverseTimeline = LCT.reverseTimeline
    
    -- Debug output
    LCT:Debug("Saved dimensions - Width:", settings.barWidth, 
              "Height:", settings.barHeight, 
              "IconSize:", settings.iconSize, 
              "Locked:", settings.locked,
              "Reverse:", settings.reverseTimeline)
end

-- Function to load dimension settings
local function LoadDimensionSettings()
    if not LoremCTDB then LoremCTDB = {} end
    if not LoremCTDB.dimensions then LoremCTDB.dimensions = {} end
    
    local settings = LoremCTDB.dimensions
    
    -- Apply settings with validation
    local width = math.max(100, math.min(1000, settings.barWidth or LCT.defaults.barWidth))
    local height = math.max(10, math.min(100, settings.barHeight or LCT.defaults.barHeight))
    local iconSize = math.max(8, math.min(64, settings.iconSize or LCT.defaults.iconSize))
    local locked = settings.locked or LCT.defaults.locked
    local reverse = settings.reverseTimeline or LCT.defaults.reverseTimeline
    
    -- Apply the settings
    LCT.frame:SetWidth(width)
    LCT.frame:SetHeight(height)
    LCT.iconSize = iconSize
    LCT.frame.locked = locked
    LCT.reverseTimeline = reverse
    LCT.frame:EnableMouse(not locked)
    
    -- Update existing cooldown icons size
    if LCT.activeCooldowns then
        for _, icon in pairs(LCT.activeCooldowns) do
            icon:SetSize(iconSize, iconSize)
        end
    end
    
    -- Update timeline markers
    if LCT.timeline and LCT.timeline.UpdateMarkers then
        LCT.timeline.UpdateMarkers()
    end
    
    -- Update UI controls
    LCT.settings.UpdateDimensionControls()
    
    -- Debug output
    LCT:Debug("Loaded dimensions - Width:", width, 
              "Height:", height, 
              "IconSize:", iconSize, 
              "Locked:", locked,
              "Reverse:", reverse)
end

-- Helper function to create input box (made accessible to visibility module)
function LCT.settings.CreateInputBox(parent, width, initialValue)
    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetSize(width, 20)
    box:SetAutoFocus(false)
    box:SetNumeric(true)
    box:SetText(initialValue)
    return box
end

-- Create settings frame
local settingsFrame = CreateFrame("Frame", "LoremCTSettings", UIParent, "BasicFrameTemplateWithInset")
settingsFrame:SetSize(400, 500)  -- Increased size for better spacing
settingsFrame:SetPoint("CENTER")
settingsFrame:SetMovable(true)
settingsFrame:EnableMouse(true)
settingsFrame:RegisterForDrag("LeftButton")
settingsFrame:SetScript("OnDragStart", settingsFrame.StartMoving)
settingsFrame:SetScript("OnDragStop", settingsFrame.StopMovingOrSizing)
settingsFrame:Hide()

-- Set title
settingsFrame.TitleText:SetText("Lorem Cooldown Tracker")

-- Create section headers
local function CreateHeader(text, parent, anchorFrame, yOffset)
    local header = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    header:SetText(text)
    if anchorFrame then
        header:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, yOffset)
    else
        header:SetPoint("TOPLEFT", 20, -40)
    end
    return header
end

-- Dimension Settings Header
local dimensionHeader = CreateHeader("Timeline Dimensions", settingsFrame)

-- Create dimension controls
local dimensionControls = {}

-- Timeline Direction Toggle
dimensionControls.reverseButton = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
dimensionControls.reverseButton:SetPoint("TOPLEFT", dimensionHeader, "BOTTOMLEFT", 0, -10)
dimensionControls.reverseButton:SetScript("OnClick", function(self)
    LCT.reverseTimeline = self:GetChecked()
    SaveDimensionSettings()
    -- Update timeline and cooldowns
    if LCT.timeline and LCT.timeline.UpdateMarkers then
        LCT.timeline.UpdateMarkers()
    end
    if LCT.cooldowns and LCT.cooldowns.UpdateAll then
        LCT.cooldowns.UpdateAll()
    end
end)
dimensionControls.reverseButton.text = dimensionControls.reverseButton:CreateFontString(nil, "ARTWORK", "GameFontNormal")
dimensionControls.reverseButton.text:SetPoint("LEFT", dimensionControls.reverseButton, "RIGHT", 0, 1)
dimensionControls.reverseButton.text:SetText("Reverse Timeline Direction")

-- Lock Frame Toggle
dimensionControls.lockButton = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
dimensionControls.lockButton:SetPoint("TOPLEFT", dimensionControls.reverseButton, "BOTTOMLEFT", 0, -10)
dimensionControls.lockButton:SetScript("OnClick", function(self)
    LCT.frame.locked = self:GetChecked()
    LCT.frame:EnableMouse(not LCT.frame.locked)
    SaveDimensionSettings()
end)
dimensionControls.lockButton.text = dimensionControls.lockButton:CreateFontString(nil, "ARTWORK", "GameFontNormal")
dimensionControls.lockButton.text:SetPoint("LEFT", dimensionControls.lockButton, "RIGHT", 0, 1)
dimensionControls.lockButton.text:SetText("Lock Frame")

-- Bar Width Controls
dimensionControls.barWidthSlider = CreateFrame("Slider", nil, settingsFrame, "OptionsSliderTemplate")
dimensionControls.barWidthSlider:SetPoint("TOPLEFT", dimensionControls.lockButton, "BOTTOMLEFT", 0, -30)
dimensionControls.barWidthSlider:SetMinMaxValues(100, 1000)
dimensionControls.barWidthSlider:SetValue(300)
dimensionControls.barWidthSlider:SetValueStep(1)
dimensionControls.barWidthSlider:SetObeyStepOnDrag(true)
dimensionControls.barWidthSlider.Low:SetText("100")
dimensionControls.barWidthSlider.High:SetText("1000")
dimensionControls.barWidthSlider.Text:SetText("Bar Width")

dimensionControls.barWidthInput = LCT.settings.CreateInputBox(settingsFrame, 50, "300")
dimensionControls.barWidthInput:SetPoint("LEFT", dimensionControls.barWidthSlider, "RIGHT", 10, 0)

dimensionControls.barWidthSlider:SetScript("OnValueChanged", function(self, value)
    LCT.frame:SetWidth(value)
    dimensionControls.barWidthInput:SetText(math.floor(value))
    SaveDimensionSettings()
end)

dimensionControls.barWidthInput:SetScript("OnEnterPressed", function(self)
    local value = tonumber(self:GetText())
    if value then
        value = math.max(100, math.min(1000, value))
        dimensionControls.barWidthSlider:SetValue(value)
        LCT.frame:SetWidth(value)
        self:SetText(value)
        SaveDimensionSettings()
    end
    self:ClearFocus()
end)

-- Bar Height Controls
dimensionControls.barHeightSlider = CreateFrame("Slider", nil, settingsFrame, "OptionsSliderTemplate")
dimensionControls.barHeightSlider:SetPoint("TOPLEFT", dimensionControls.barWidthSlider, "BOTTOMLEFT", 0, -30)
dimensionControls.barHeightSlider:SetMinMaxValues(10, 100)
dimensionControls.barHeightSlider:SetValue(30)
dimensionControls.barHeightSlider:SetValueStep(1)
dimensionControls.barHeightSlider:SetObeyStepOnDrag(true)
dimensionControls.barHeightSlider.Low:SetText("10")
dimensionControls.barHeightSlider.High:SetText("100")
dimensionControls.barHeightSlider.Text:SetText("Bar Height")

dimensionControls.barHeightInput = LCT.settings.CreateInputBox(settingsFrame, 50, "30")
dimensionControls.barHeightInput:SetPoint("LEFT", dimensionControls.barHeightSlider, "RIGHT", 10, 0)

dimensionControls.barHeightSlider:SetScript("OnValueChanged", function(self, value)
    LCT.frame:SetHeight(value)
    dimensionControls.barHeightInput:SetText(math.floor(value))
    SaveDimensionSettings()
end)

dimensionControls.barHeightInput:SetScript("OnEnterPressed", function(self)
    local value = tonumber(self:GetText())
    if value then
        value = math.max(10, math.min(100, value))
        dimensionControls.barHeightSlider:SetValue(value)
        LCT.frame:SetHeight(value)
        self:SetText(value)
        SaveDimensionSettings()
    end
    self:ClearFocus()
end)

-- Icon Size Controls
dimensionControls.iconSizeSlider = CreateFrame("Slider", nil, settingsFrame, "OptionsSliderTemplate")
dimensionControls.iconSizeSlider:SetPoint("TOPLEFT", dimensionControls.barHeightSlider, "BOTTOMLEFT", 0, -30)
dimensionControls.iconSizeSlider:SetMinMaxValues(8, 64)
dimensionControls.iconSizeSlider:SetValue(24)
dimensionControls.iconSizeSlider:SetValueStep(1)
dimensionControls.iconSizeSlider:SetObeyStepOnDrag(true)
dimensionControls.iconSizeSlider.Low:SetText("8")
dimensionControls.iconSizeSlider.High:SetText("64")
dimensionControls.iconSizeSlider.Text:SetText("Icon Size")

dimensionControls.iconSizeInput = LCT.settings.CreateInputBox(settingsFrame, 50, "24")
dimensionControls.iconSizeInput:SetPoint("LEFT", dimensionControls.iconSizeSlider, "RIGHT", 10, 0)

dimensionControls.iconSizeSlider:SetScript("OnValueChanged", function(self, value)
    LCT.iconSize = value
    dimensionControls.iconSizeInput:SetText(math.floor(value))
    -- Update existing cooldown icons
    if LCT.activeCooldowns then
        for _, icon in pairs(LCT.activeCooldowns) do
            icon:SetSize(value, value)
        end
    end
    SaveDimensionSettings()
end)

dimensionControls.iconSizeInput:SetScript("OnEnterPressed", function(self)
    local value = tonumber(self:GetText())
    if value then
        value = math.max(8, math.min(64, value))
        dimensionControls.iconSizeSlider:SetValue(value)
        LCT.iconSize = value
        self:SetText(value)
        -- Update existing cooldown icons
        if LCT.activeCooldowns then
            for _, icon in pairs(LCT.activeCooldowns) do
                icon:SetSize(value, value)
            end
        end
        SaveDimensionSettings()
    end
    self:ClearFocus()
end)

-- Create visibility controls with proper spacing
local visibilityHeader = CreateHeader("Visibility Options", settingsFrame, dimensionControls.iconSizeSlider, -30)
local visibilityControls = LCT.visibility.CreateControls(settingsFrame)
visibilityControls.showFrameButton:SetPoint("TOPLEFT", visibilityHeader, "BOTTOMLEFT", 0, -10)
visibilityControls.bgOpacitySlider:SetPoint("TOPLEFT", visibilityControls.showFrameButton, "BOTTOMLEFT", 0, -30)
visibilityControls.showTimeTextButton:SetPoint("TOPLEFT", visibilityControls.bgOpacitySlider, "BOTTOMLEFT", 0, -20)
visibilityControls.showIconsButton:SetPoint("TOPLEFT", visibilityControls.showTimeTextButton, "BOTTOMLEFT", 0, -10)

-- Add background for better readability
settingsFrame.bg = settingsFrame:CreateTexture(nil, "BACKGROUND")
settingsFrame.bg:SetAllPoints()
settingsFrame.bg:SetColorTexture(0, 0, 0, 0.8)

-- Add scroll frame for future options
local scrollFrame = CreateFrame("ScrollFrame", nil, settingsFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 4, -24)
scrollFrame:SetPoint("BOTTOMRIGHT", settingsFrame, "BOTTOMRIGHT", -28, 8)

local scrollChild = CreateFrame("Frame")
scrollFrame:SetScrollChild(scrollChild)
scrollChild:SetSize(settingsFrame:GetWidth() - 28, settingsFrame:GetHeight() * 1.5)  -- Extra height for future options

-- Function to update dimension controls
function LCT.settings.UpdateDimensionControls()
    dimensionControls.reverseButton:SetChecked(LCT.reverseTimeline)
    dimensionControls.lockButton:SetChecked(LCT.frame.locked)
    dimensionControls.barWidthSlider:SetValue(LCT.frame:GetWidth())
    dimensionControls.barWidthInput:SetText(math.floor(LCT.frame:GetWidth()))
    dimensionControls.barHeightSlider:SetValue(LCT.frame:GetHeight())
    dimensionControls.barHeightInput:SetText(math.floor(LCT.frame:GetHeight()))
    dimensionControls.iconSizeSlider:SetValue(LCT.iconSize)
    dimensionControls.iconSizeInput:SetText(math.floor(LCT.iconSize))
end

-- Function to update visibility controls
function LCT.settings.UpdateVisibilityControls()
    visibilityControls.showFrameButton:SetChecked(LCT.frame:IsShown())
    visibilityControls.bgOpacitySlider:SetValue(LCT.frame.bg:GetAlpha() * 100)
    visibilityControls.bgOpacityInput:SetText(math.floor(LCT.frame.bg:GetAlpha() * 100))
    visibilityControls.showTimeTextButton:SetChecked(LCT.visibility.showTimeText)
    visibilityControls.showIconsButton:SetChecked(LCT.visibility.showIcons)
end

-- Create minimap icon
local minimapIcon = LibStub("LibDataBroker-1.1"):NewDataObject("LoremCT", {
    type = "launcher",
    icon = "Interface\\Icons\\Achievement_BG_winAB_underXminutes",
    OnClick = function(self, button)
        if button == "LeftButton" then
            if settingsFrame:IsShown() then
                settingsFrame:Hide()
            else
                settingsFrame:Show()
            end
        end
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("Lorem Cooldown Tracker")
        tooltip:AddLine("Click to open settings", 1, 1, 1)
    end,
})

local minimapButton = LibStub("LibDBIcon-1.0")
minimapButton:Register("LoremCT", minimapIcon, {minimapPos = 45})

-- Register events for loading settings
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        LoadDimensionSettings()
        LCT.visibility.LoadSettings()
    end
end)

-- Make settings frame accessible to core
LCT.settingsFrame = settingsFrame 