--[[
Animation Test Suite
=================
Tests for cooldown animation behavior and timeline
--]]

local suite = {
    name = "Animation"
}

function suite.run(framework)
    -- Reset mock state
    framework.mockState.time = 0
    
    -- Test 1: Basic animation setup
    local frame = CreateFrame("Frame")
    local duration = 120  -- 2 minute cooldown
    local width = 300
    local iconSize = 32
    
    local anim = LCT.animations.StartAnimation(frame, duration, false)
    framework:Assert(
        anim ~= nil,
        "Animation creation",
        "Animation should be created successfully"
    )
    
    -- Test 2: Animation position at start
    local position = LCT.animations.CalculatePosition(duration, duration, width, iconSize, false)
    framework:Assert(
        math.abs(position - iconSize/2) < 0.1,
        "Animation start position",
        string.format("Expected position %.1f, got %.1f", iconSize/2, position or 0)
    )
    
    -- Test 3: Animation position at half duration
    local remaining = duration/2
    position = LCT.animations.CalculatePosition(remaining, duration, width, iconSize, false)
    local expectedPos = (width - iconSize) * 0.5 + iconSize/2
    framework:Assert(
        math.abs(position - expectedPos) < 0.1,
        "Animation mid position",
        string.format("Expected position %.1f, got %.1f", expectedPos, position or 0)
    )
    
    -- Test 4: Animation position at end
    remaining = 0
    position = LCT.animations.CalculatePosition(remaining, duration, width, iconSize, false)
    framework:Assert(
        math.abs(position - (width - iconSize/2)) < 0.1,
        "Animation end position",
        string.format("Expected position %.1f, got %.1f", width - iconSize/2, position or 0)
    )
    
    -- Test 5: Reversed animation positions
    position = LCT.animations.CalculatePosition(duration, duration, width, iconSize, true)
    framework:Assert(
        math.abs(position - (width - iconSize/2)) < 0.1,
        "Reversed animation start position",
        string.format("Expected position %.1f, got %.1f", width - iconSize/2, position or 0)
    )
    
    -- Test 6: Smooth animation transitions
    local lastPos = nil
    local maxJump = 5  -- Maximum allowed position jump between frames
    local smoothTransition = true
    
    for i = 0, 100 do
        remaining = duration - (duration * i / 100)
        position = LCT.animations.CalculatePosition(remaining, duration, width, iconSize, false)
        
        if lastPos then
            local jump = math.abs(position - lastPos)
            if jump > maxJump then
                smoothTransition = false
                break
            end
        end
        lastPos = position
    end
    
    framework:Assert(
        smoothTransition,
        "Animation smooth transition",
        "Animation should transition smoothly over time"
    )
    
    -- Test 7: Animation finish callback
    local finishCalled = false
    LCT.animations.OnFinish = function()
        finishCalled = true
    end
    
    LCT.animations.CalculatePosition(-0.1, duration, width, iconSize, false)
    framework:Assert(
        finishCalled,
        "Animation finish callback",
        "OnFinish should be called when animation completes"
    )
    
    -- Test 8: Multiple concurrent animations
    local frame2 = CreateFrame("Frame")
    local anim1 = LCT.animations.StartAnimation(frame, 60, false)
    local anim2 = LCT.animations.StartAnimation(frame2, 120, true)
    
    framework:Assert(
        anim1 ~= nil and anim2 ~= nil and anim1 ~= anim2,
        "Multiple animations",
        "Should be able to create multiple distinct animations"
    )
    
    return true
end

return suite 