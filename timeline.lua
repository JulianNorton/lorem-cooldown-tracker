local addonName, LCT = ...

-- Timeline functions
local timeline = {}
LCT.timeline = timeline

-- Function to update timeline markers
function timeline.UpdateMarkers()
    local frame = LCT.frame
    LCT:Debug("Updating timeline markers")
    
    -- Clear existing markers and texts
    if frame.markers then
        for _, marker in ipairs(frame.markers) do
            marker:Hide()
            marker:ClearAllPoints()
        end
    end
    if frame.texts then
        for _, text in ipairs(frame.texts) do
            text:Hide()
            text:ClearAllPoints()
        end
    end
    frame.markers = {}
    frame.texts = {}
    
    --[[ MARKER POSITIONING:
        Should match cooldown positioning assumptions:
        - Left edge (0s): x = iconSize/2
        - Right edge (300s): x = width - iconSize/2
        - Markers should align with where cooldowns will be at those times
        
        Position calculation:
        xPos = (timeRemaining / maxTime) * (width - iconSize) + (iconSize/2)
    --]]
    
    local width = frame:GetWidth()
    local iconSize = LCT.iconSize
    
    -- Function to calculate marker position
    local function GetMarkerPosition(timeRemaining)
        return (timeRemaining / LCT.maxTime) * (width - iconSize) + (iconSize/2)
    end
    
    -- Create 0-second marker (left)
    local startMarker = frame:CreateTexture(nil, "ARTWORK")
    startMarker:SetSize(1, frame:GetHeight() * 0.5)
    startMarker:SetColorTexture(1, 1, 1, 0.3)
    startMarker:SetPoint("TOP", frame, "TOPLEFT", GetMarkerPosition(0), 0)
    table.insert(frame.markers, startMarker)
    
    -- Create 10-second marker
    local tenSecMarker = frame:CreateTexture(nil, "ARTWORK")
    tenSecMarker:SetSize(1, frame:GetHeight() * 0.3)
    tenSecMarker:SetColorTexture(1, 1, 1, 0.2)
    tenSecMarker:SetPoint("TOP", frame, "TOPLEFT", GetMarkerPosition(10), 0)
    table.insert(frame.markers, tenSecMarker)
    
    -- Create 30-second marker
    local halfMinMarker = frame:CreateTexture(nil, "ARTWORK")
    halfMinMarker:SetSize(1, frame:GetHeight() * 0.4)
    halfMinMarker:SetColorTexture(1, 1, 1, 0.25)
    halfMinMarker:SetPoint("TOP", frame, "TOPLEFT", GetMarkerPosition(30), 0)
    table.insert(frame.markers, halfMinMarker)
    
    -- Create 1-minute marker
    local minuteMarker = frame:CreateTexture(nil, "ARTWORK")
    minuteMarker:SetSize(1, frame:GetHeight() * 0.5)
    minuteMarker:SetColorTexture(1, 1, 1, 0.3)
    minuteMarker:SetPoint("TOP", frame, "TOPLEFT", GetMarkerPosition(60), 0)
    table.insert(frame.markers, minuteMarker)
    
    -- Add 1m text
    local minuteText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    minuteText:SetText("1m")
    minuteText:SetPoint("BOTTOM", minuteMarker, "TOP", 0, 1)
    minuteText:SetTextColor(1, 1, 1, 0.3)
    table.insert(frame.texts, minuteText)
    
    -- Create 5-minute marker (right)
    local endMarker = frame:CreateTexture(nil, "ARTWORK")
    endMarker:SetSize(1, frame:GetHeight() * 0.5)
    endMarker:SetColorTexture(1, 1, 1, 0.3)
    endMarker:SetPoint("TOP", frame, "TOPLEFT", GetMarkerPosition(LCT.maxTime), 0)
    table.insert(frame.markers, endMarker)
    
    -- Add 5m text
    local endText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    endText:SetText("5m")
    endText:SetPoint("BOTTOM", endMarker, "TOP", 0, 1)
    endText:SetTextColor(1, 1, 1, 0.3)
    table.insert(frame.texts, endText)
    
    LCT:Debug("Created", #frame.markers, "timeline markers")
end

-- Initialize timeline
function timeline.Initialize()
    LCT:Debug("Initializing timeline module")
    -- Set up resize handler
    LCT.frame:SetScript("OnSizeChanged", timeline.UpdateMarkers)
    
    -- Create initial markers
    timeline.UpdateMarkers()
end

-- Return the module
return timeline 