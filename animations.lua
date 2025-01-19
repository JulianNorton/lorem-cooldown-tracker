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
                
                icon:ClearAllPoints()
                icon:SetPoint("CENTER", LCT.frame, "LEFT", currentX, 0)
                hasActiveAnimations = true
            end
            
            -- Handle scaling
            if anim.remaining and anim.remaining <= FINAL_SECONDS_THRESHOLD then
                local scale = 1 + (FINAL_SECONDS_SCALE - 1) * (1 - anim.remaining / FINAL_SECONDS_THRESHOLD)
                icon:SetScale(scale)
            else
                icon:SetScale(1)
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
            -- Fade out
            local progress = elapsed / FINISH_ANIMATION_DURATION
            local alpha = 1 - progress
            
            icon:Show()
            icon:SetAlpha(alpha)
            hasActiveAnimations = true
        end
    end
    
    if not hasActiveAnimations then
        self:SetScript("OnUpdate", nil)
    end
end)

-- Function to start position animation
function LCT.animations.StartPositionAnimation(icon, targetX, remaining)
    if not icon then return end
    
    local _, _, _, _, currentX = icon:GetPoint()
    currentX = currentX or 0
    
    activeAnimations[icon] = {
        startTime = GetTime(),
        duration = ANIMATION_DURATION,
        startX = currentX,
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