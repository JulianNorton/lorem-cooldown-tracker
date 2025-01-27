local addonName, LCT = ...

-- Initialize animations namespace
LCT.animations = {}

-- Animation settings
local ANIMATION_DURATION = 0.15
local FINISH_ANIMATION_DURATION = 0.2
local FINAL_SECONDS_SCALE = 2.0
local FINAL_SECONDS_THRESHOLD = 10

-- Table to store active animations
local activeAnimations = {}
local finishAnimations = {}

-- Create animation frame
LCT.animations.updateFrame = CreateFrame("Frame")

-- Set up the OnUpdate script
LCT.animations.updateFrame:SetScript("OnUpdate", function(self, elapsed)
    local now = GetTime()
    local hasActiveAnimations = false
    
    -- Update position animations
    for icon, anim in pairs(activeAnimations) do
        if icon:IsVisible() then
            local elapsed = now - anim.startTime
            local duration = anim.duration
            
            if elapsed >= duration then
                -- Animation complete
                icon:ClearAllPoints()
                icon:SetPoint("CENTER", LCT.frame, "LEFT", anim.targetX, 0)
                activeAnimations[icon] = nil
            else
                -- Linear movement for timeline consistency
                local progress = elapsed / duration
                local currentX = anim.startX + ((anim.targetX - anim.startX) * progress)
                
                -- Only update position if it changed significantly
                if not anim.lastX or math.abs(currentX - anim.lastX) > 0.1 then
                    icon:ClearAllPoints()
                    icon:SetPoint("CENTER", LCT.frame, "LEFT", currentX, 0)
                    anim.lastX = currentX
                end
                
                -- Handle scaling less frequently
                if anim.remaining and anim.remaining <= FINAL_SECONDS_THRESHOLD then
                    local newScale = 1 + (FINAL_SECONDS_SCALE - 1) * (1 - anim.remaining / FINAL_SECONDS_THRESHOLD)
                    -- Only update scale if it changed significantly
                    if not anim.lastScale or math.abs(newScale - anim.lastScale) > 0.05 then
                        icon:SetScale(newScale)
                        anim.lastScale = newScale
                    end
                end
                
                hasActiveAnimations = true
            end
        else
            activeAnimations[icon] = nil
        end
    end
    
    -- Update finish animations
    for icon, anim in pairs(finishAnimations) do
        local elapsed = now - anim.startTime
        
        if elapsed >= FINISH_ANIMATION_DURATION then
            -- Animation complete
            icon:Hide()
            icon:SetScale(1)
            icon:SetAlpha(1)
            finishAnimations[icon] = nil
        else
            -- Fade out with less frequent updates
            local progress = elapsed / FINISH_ANIMATION_DURATION
            local newAlpha = 1 - progress
            
            -- Only update alpha if it changed significantly
            if not anim.lastAlpha or math.abs(newAlpha - anim.lastAlpha) > 0.05 then
                icon:SetAlpha(newAlpha)
                anim.lastAlpha = newAlpha
            end
            
            hasActiveAnimations = true
        end
    end
    
    if not hasActiveAnimations then
        self:SetScript("OnUpdate", nil)
    end
end)

-- Function to start position animation
function LCT.animations.StartPositionAnimation(frame, targetX, remaining)
    if not frame or not frame:IsObjectType("Frame") then return end
    
    -- Ensure frame has a valid point
    local point, relativeTo, relativePoint, x, y = frame:GetPoint()
    if not point then
        -- If no point exists, set a default one
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", LCT.frame, "LEFT", 0, 0)
        x = 0
    end
    
    activeAnimations[frame] = {
        startTime = GetTime(),
        duration = ANIMATION_DURATION,
        startX = x or 0,
        targetX = targetX,
        remaining = remaining
    }
    
    LCT.animations.updateFrame:SetScript("OnUpdate", LCT.animations.updateFrame:GetScript("OnUpdate"))
end

-- Function to start freeze-fade animation
function LCT.animations.StartFinishAnimation(icon)
    if not icon then return end
    
    finishAnimations[icon] = {
        startTime = GetTime()
    }
    
    LCT.animations.updateFrame:SetScript("OnUpdate", LCT.animations.updateFrame:GetScript("OnUpdate"))
end

-- Function to cancel animation
function LCT.animations.CancelAnimation(icon)
    if not icon then return end
    
    activeAnimations[icon] = nil
    finishAnimations[icon] = nil
    icon:SetScale(1)
    icon:SetAlpha(1)
end 