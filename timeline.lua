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
        if LCT.reverseTimeline then
            -- Reversed: high time on left, low time on right
            return ((LCT.maxTime - timeRemaining) / LCT.maxTime) * (width - iconSize) + (iconSize/2)
        else
            -- Normal: low time on left, high time on right
            return (timeRemaining / LCT.maxTime) * (width - iconSize) + (iconSize/2)
        end
    end
    
    -- Create markers in the correct order based on direction
    local markerTimes = {0, 10, 30, 60, LCT.maxTime}
    local markerHeights = {0.5, 0.3, 0.4, 0.5, 0.5}  -- Relative heights for each marker
    local markerLabels = {"", "", "", "1m", "5m"}
    
    for i, timeValue in ipairs(markerTimes) do
        -- Create marker
        local marker = frame:CreateTexture(nil, "ARTWORK")
        marker:SetSize(1, frame:GetHeight() * markerHeights[i])
        marker:SetColorTexture(1, 1, 1, 0.3)
        marker:SetPoint("TOP", frame, "TOPLEFT", GetMarkerPosition(timeValue), 0)
        table.insert(frame.markers, marker)
        
        -- Add label if it exists
        if markerLabels[i] ~= "" then
            local text = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
            text:SetText(markerLabels[i])
            text:SetPoint("BOTTOM", marker, "TOP", 0, 1)
            text:SetTextColor(1, 1, 1, 0.3)
            table.insert(frame.texts, text)
        end
    end
    
    LCT:Debug("Created", #frame.markers, "timeline markers")
end

-- Initialize timeline
function timeline.Initialize()
    LCT:Debug("Initializing timeline module")
    
    -- Throttle resize updates
    local resizeElapsed = 0
    local isResizing = false
    local RESIZE_THROTTLE = 0.1  -- Only update every 100ms during resize
    
    -- Create resize update frame
    local resizeFrame = CreateFrame("Frame")
    resizeFrame:Hide()
    
    -- Set up throttled resize handler
    resizeFrame:SetScript("OnUpdate", function(self, elapsed)
        resizeElapsed = resizeElapsed + elapsed
        if resizeElapsed >= RESIZE_THROTTLE then
            timeline.UpdateMarkers()
            resizeElapsed = 0
            
            -- If we're not resizing anymore, hide the frame
            if not isResizing then
                self:Hide()
            end
        end
    end)
    
    -- Set up resize handler with throttling
    LCT.frame:SetScript("OnSizeChanged", function()
        if not isResizing then
            isResizing = true
            resizeFrame:Show()
            
            -- Force an immediate first update
            timeline.UpdateMarkers()
        end
        
        -- Reset resize state after a delay
        C_Timer.After(0.2, function()
            isResizing = false
        end)
    end)
    
    -- Create initial markers
    timeline.UpdateMarkers()
end

-- Return the module
return timeline 