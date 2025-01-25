local addonName, LCT = ...

-- Initialize animations namespace
LCT.animations = {}

-- Animation settings
local ANIMATION_DURATION = 0.15
local FINISH_ANIMATION_DURATION = 0.2
local FINAL_SECONDS_SCALE = 2.0
local FINAL_SECONDS_THRESHOLD = 10

-- Function to start position animation
function LCT.animations.StartPositionAnimation(icon, targetX, remaining)
    if not icon then return end
    
    -- Get current position
    local _, _, _, _, currentX = icon:GetPoint()
    
    -- If no current position, set initial position
    if not currentX then
        icon:ClearAllPoints()
        icon:SetPoint("CENTER", LCT.frame, "LEFT", targetX, 0)
        icon:Show()
        return
    end
    
    -- Don't animate if the change is very small
    if math.abs(targetX - currentX) < 0.1 then
        return
    end
    
    -- Stop any existing animation
    if icon.positionGroup then
        icon.positionGroup:Stop()
        local _, _, _, _, preservedX = icon:GetPoint()
        icon:ClearAllPoints()
        icon:SetPoint("CENTER", LCT.frame, "LEFT", preservedX, 0)
    end
    
    -- Create animation group if it doesn't exist
    if not icon.positionGroup then
        icon.positionGroup = icon:CreateAnimationGroup()
        icon.positionAnim = icon.positionGroup:CreateAnimation("Translation")
        icon.positionGroup:SetScript("OnFinished", function()
            icon:ClearAllPoints()
            icon:SetPoint("CENTER", LCT.frame, "LEFT", targetX, 0)
        end)
    end
    
    -- Calculate duration based on distance
    local width = LCT.frame:GetWidth()
    local xOffset = targetX - currentX
    local duration = math.abs(xOffset) > width * 0.8 and 0.3 or 0.15  -- Longer duration for direction toggles
    
    -- Set up animation
    icon.positionAnim:SetOffset(xOffset, 0)
    icon.positionAnim:SetDuration(duration)
    icon.positionAnim:SetSmoothing("IN_OUT")
    
    -- Show the icon before starting animation
    icon:Show()
    
    -- Start the animation
    icon.positionGroup:Play()
    
    -- Handle scaling for final seconds
    if remaining and remaining <= FINAL_SECONDS_THRESHOLD then
        local scale = 1 + (FINAL_SECONDS_SCALE - 1) * (1 - remaining / FINAL_SECONDS_THRESHOLD)
        icon:SetScale(scale)
    else
        icon:SetScale(1)
    end
end

-- Function to start freeze-fade animation
function LCT.animations.StartFinishAnimation(icon)
    if not icon then return end
    
    -- Stop any existing animations
    if icon.fadeGroup then
        icon.fadeGroup:Stop()
    end
    if icon.positionGroup then
        icon.positionGroup:Stop()
    end
    
    -- Create animation group if it doesn't exist
    if not icon.fadeGroup then
        icon.fadeGroup = icon:CreateAnimationGroup()
        icon.fadeAnim = icon.fadeGroup:CreateAnimation("Alpha")
        icon.fadeAnim:SetSmoothing("OUT")
        
        -- Set up finish handler
        icon.fadeGroup:SetScript("OnFinished", function()
            icon:Hide()
            icon:SetAlpha(1)
            icon:SetScale(1)
        end)
    end
    
    -- Set up animation
    icon.fadeAnim:SetFromAlpha(1)
    icon.fadeAnim:SetToAlpha(0)
    icon.fadeAnim:SetDuration(FINISH_ANIMATION_DURATION)
    
    -- Start the animation
    icon.fadeGroup:Play()
end

-- Function to cancel animation
function LCT.animations.CancelAnimation(icon)
    if not icon then return end
    
    if icon.positionGroup then
        icon.positionGroup:Stop()
    end
    if icon.fadeGroup then
        icon.fadeGroup:Stop()
    end
    
    icon:SetScale(1)
    icon:SetAlpha(1)
end 