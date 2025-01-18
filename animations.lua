local addonName, LCT = ...

-- Initialize animations namespace
LCT.animations = {}

-- Animation settings
local ANIMATION_DURATION = 0.15 -- Duration in seconds

-- Table to store active animations
local activeAnimations = {}

-- Function to start a position animation
function LCT.animations.StartPositionAnimation(icon, targetX)
    if not icon then return end
    
    -- Get current position
    local currentX = targetX
    if icon:GetPoint() then
        local _, _, _, x = icon:GetPoint()
        if x then currentX = x end
    end
    
    -- Create or update animation data
    activeAnimations[icon] = {
        startX = currentX,
        targetX = targetX,
        startTime = GetTime(),
        duration = ANIMATION_DURATION
    }
    
    -- Create animation frame if it doesn't exist
    if not LCT.animations.updateFrame then
        LCT.animations.updateFrame = CreateFrame("Frame")
    end
    
    -- Set up the OnUpdate script
    LCT.animations.updateFrame:SetScript("OnUpdate", function(self)
        local now = GetTime()
        local hasActiveAnimations = false
        
        for icon, anim in pairs(activeAnimations) do
            if icon:IsVisible() then
                local elapsed = now - anim.startTime
                local duration = anim.duration
                
                if elapsed >= duration then
                    -- Animation complete
                    icon:ClearAllPoints()
                    icon:SetPoint("LEFT", LCT.frame, "LEFT", anim.targetX, 0)
                    activeAnimations[icon] = nil
                else
                    -- Linear movement for timeline consistency
                    local progress = elapsed / duration
                    local currentX = anim.startX + ((anim.targetX - anim.startX) * progress)
                    
                    icon:ClearAllPoints()
                    icon:SetPoint("LEFT", LCT.frame, "LEFT", currentX, 0)
                    hasActiveAnimations = true
                end
            else
                activeAnimations[icon] = nil
            end
        end
        
        if not hasActiveAnimations then
            self:SetScript("OnUpdate", nil)
        end
    end)
end

-- Function to cancel animations for an icon
function LCT.animations.CancelAnimation(icon)
    if activeAnimations[icon] then
        local anim = activeAnimations[icon]
        icon:ClearAllPoints()
        icon:SetPoint("LEFT", LCT.frame, "LEFT", anim.targetX, 0)
        activeAnimations[icon] = nil
    end
end

-- Function to cancel all animations
function LCT.animations.CancelAllAnimations()
    for icon, anim in pairs(activeAnimations) do
        icon:ClearAllPoints()
        icon:SetPoint("LEFT", LCT.frame, "LEFT", anim.targetX, 0)
    end
    wipe(activeAnimations)
    if LCT.animations.updateFrame then
        LCT.animations.updateFrame:SetScript("OnUpdate", nil)
    end
end 