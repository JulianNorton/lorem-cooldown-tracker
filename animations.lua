local addonName, LCT = ...

-- Initialize animations namespace
LCT.animations = {}

-- Animation settings
local ANIMATION_DURATION = 0.15 -- Duration in seconds
local FINISH_ANIMATION_DURATION = 0.8 -- Duration for finish animation

-- Table to store active animations
local activeAnimations = {}
local finishAnimations = {}

-- Create animation frame
LCT.animations.updateFrame = CreateFrame("Frame")

-- Set up the OnUpdate script once
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
            -- Calculate progress for grow and fade
            local progress = elapsed / FINISH_ANIMATION_DURATION
            
            -- Simple grow and fade
            local scale = 1 + (0.5 * progress) -- Grow from 1.0 to 1.5
            local alpha = 1 - progress         -- Fade out from 1 to 0
            
            icon:Show()
            icon:SetScale(scale)
            icon:SetAlpha(alpha)
            hasActiveAnimations = true
        end
    end
    
    if hasActiveAnimations then
        self:SetScript("OnUpdate", self:GetScript("OnUpdate"))
    end
end)

-- Function to start a position animation
function LCT.animations.StartPositionAnimation(icon, targetX)
    if not icon then return end
    
    -- Cancel any existing finish animation
    finishAnimations[icon] = nil
    icon:SetScale(1)
    icon:SetAlpha(1)
    
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
    
    -- Ensure OnUpdate is running
    LCT.animations.updateFrame:SetScript("OnUpdate", LCT.animations.updateFrame:GetScript("OnUpdate"))
end

-- Function to start finish animation
function LCT.animations.StartFinishAnimation(icon)
    if not icon then return end
    
    -- Cancel any existing animations
    activeAnimations[icon] = nil
    finishAnimations[icon] = nil
    
    -- Create finish animation data
    finishAnimations[icon] = {
        startTime = GetTime()
    }
    
    -- Set initial state
    icon:Show()
    icon:SetScale(1.0) -- Start at normal size
    icon:SetAlpha(1)
    
    -- Ensure OnUpdate is running
    LCT.animations.updateFrame:SetScript("OnUpdate", LCT.animations.updateFrame:GetScript("OnUpdate"))
end

-- Function to cancel animations for an icon
function LCT.animations.CancelAnimation(icon)
    if not icon then return end
    
    -- Clean up finish animation
    activeAnimations[icon] = nil
    finishAnimations[icon] = nil
    icon:SetScale(1)
    icon:SetAlpha(1)
end

-- Function to cancel all animations
function LCT.animations.CancelAllAnimations()
    for icon, anim in pairs(finishAnimations) do
        if anim.glowTexture then
            anim.glowTexture:Hide()
            anim.glowTexture = nil
        end
        icon:SetScale(1)
        icon:SetAlpha(1)
    end
    for icon in pairs(activeAnimations) do
        icon:SetScale(1)
        icon:SetAlpha(1)
    end
    wipe(activeAnimations)
    wipe(finishAnimations)
    LCT.animations.updateFrame:SetScript("OnUpdate", nil)
end 