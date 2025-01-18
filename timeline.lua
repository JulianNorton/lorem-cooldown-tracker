local addonName, LCT = ...

-- Timeline functions
local timeline = {}
LCT.timeline = timeline

-- Function to update timeline markers
function timeline.UpdateMarkers()
    local frame = LCT.frame
    
    -- Clear existing markers
    if frame.markers then
        for _, marker in ipairs(frame.markers) do
            marker:Hide()
            marker:ClearAllPoints()
        end
    end
    frame.markers = {}
    
    -- Create markers for each minute (1, 2, 3, 4, 5)
    for i = 1, 5 do
        local marker = frame:CreateTexture(nil, "ARTWORK")
        marker:SetSize(1, frame:GetHeight() * 0.5)
        marker:SetColorTexture(1, 1, 1, 0.3)
        local width = frame:GetWidth() - LCT.iconSize
        local xPos = width * ((i * 60) / LCT.maxTime)
        marker:SetPoint("TOP", frame, "TOPLEFT", xPos, 0)
        table.insert(frame.markers, marker)
        
        -- Add minute text
        local text = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        text:SetText(i .. "m")
        text:SetPoint("BOTTOM", marker, "TOP", 0, 1)
        text:SetTextColor(1, 1, 1, 0.5)
    end
    
    -- Create markers for 30-second intervals
    for i = 1, 9 do
        local marker = frame:CreateTexture(nil, "ARTWORK")
        marker:SetSize(1, frame:GetHeight() * 0.3)
        marker:SetColorTexture(1, 1, 1, 0.2)
        local width = frame:GetWidth() - LCT.iconSize
        local xPos = width * ((i * 30) / LCT.maxTime)
        marker:SetPoint("TOP", frame, "TOPLEFT", xPos, 0)
        table.insert(frame.markers, marker)
    end
end

-- Initialize timeline
function timeline.Initialize()
    -- Set up resize handler
    LCT.frame:SetScript("OnSizeChanged", timeline.UpdateMarkers)
    
    -- Create initial markers
    timeline.UpdateMarkers()
end

-- Return the module
return timeline 