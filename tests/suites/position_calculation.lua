--[[
Position Calculation Test Suite
===========================
Tests for cooldown position calculations
--]]

local suite = {
    name = "Position Calculation"
}

function suite.run(framework)
    local function CalculatePosition(remaining, width, iconSize, isReversed)
        if remaining < 0 then
            remaining = 0  -- Clamp negative values to 0
        end
        if isReversed then
            -- Reversed: high time on left, low time on right
            remaining = LCT.maxTime - remaining
        end
        -- Calculate position based on remaining time
        local progress = remaining / LCT.maxTime
        return progress * (width - iconSize) + (iconSize/2)
    end
    
    -- Basic position tests
    local testCases = {
        { remaining = 300, width = 300, iconSize = 24, isReversed = false, expected = 288, name = "Full cooldown normal" },
        { remaining = 300, width = 300, iconSize = 24, isReversed = true, expected = 12, name = "Full cooldown reversed" },
        { remaining = 150, width = 300, iconSize = 24, isReversed = false, expected = 150, name = "Half cooldown normal" },
        { remaining = 150, width = 300, iconSize = 24, isReversed = true, expected = 150, name = "Half cooldown reversed" },
        { remaining = 0, width = 300, iconSize = 24, isReversed = false, expected = 12, name = "Empty cooldown normal" },
        { remaining = 0, width = 300, iconSize = 24, isReversed = true, expected = 288, name = "Empty cooldown reversed" }
    }
    
    for _, case in ipairs(testCases) do
        local result = CalculatePosition(case.remaining, case.width, case.iconSize, case.isReversed)
        -- Allow for small floating point differences
        local isClose = math.abs(result - case.expected) < 0.01
        framework:Assert(
            isClose,
            string.format("Position test: %s", case.name),
            string.format("Input: remaining=%.1f, width=%d, iconSize=%d, isReversed=%s\nExpected: %.2f, Got: %.2f",
                case.remaining, case.width, case.iconSize, tostring(case.isReversed),
                case.expected, result)
        )
    end
    
    -- Edge cases
    local edgeCases = {
        { remaining = -0.1, width = 300, iconSize = 24, isReversed = false, expected = 12, name = "Negative time normal" },
        { remaining = -0.1, width = 300, iconSize = 24, isReversed = true, expected = 288, name = "Negative time reversed" },
        { remaining = 0.001, width = 300, iconSize = 24, isReversed = false, expected = 12, name = "Almost zero normal" },
        { remaining = 0.001, width = 300, iconSize = 24, isReversed = true, expected = 288, name = "Almost zero reversed" },
        { remaining = 299.999, width = 300, iconSize = 24, isReversed = false, expected = 288, name = "Almost max normal" },
        { remaining = 299.999, width = 300, iconSize = 24, isReversed = true, expected = 12, name = "Almost max reversed" }
    }
    
    for _, case in ipairs(edgeCases) do
        local result = CalculatePosition(case.remaining, case.width, case.iconSize, case.isReversed)
        local isClose = math.abs(result - case.expected) < 0.01
        framework:Assert(
            isClose,
            string.format("Edge case test: %s", case.name),
            string.format("Input: remaining=%.3f, width=%d, iconSize=%d, isReversed=%s\nExpected: %.2f, Got: %.2f",
                case.remaining, case.width, case.iconSize, tostring(case.isReversed),
                case.expected, result)
        )
    end
    
    -- Different sizes
    local sizeTests = {
        { remaining = 150, width = 200, iconSize = 24, isReversed = false, expected = 100, name = "Half cooldown smaller width" },
        { remaining = 150, width = 400, iconSize = 24, isReversed = false, expected = 200, name = "Half cooldown larger width" },
        { remaining = 150, width = 300, iconSize = 16, isReversed = false, expected = 150, name = "Half cooldown smaller icon" },
        { remaining = 150, width = 300, iconSize = 32, isReversed = false, expected = 150, name = "Half cooldown larger icon" }
    }
    
    for _, case in ipairs(sizeTests) do
        local result = CalculatePosition(case.remaining, case.width, case.iconSize, case.isReversed)
        local isClose = math.abs(result - case.expected) < 0.01
        framework:Assert(
            isClose,
            string.format("Size test: %s", case.name),
            string.format("Input: remaining=%.1f, width=%d, iconSize=%d, isReversed=%s\nExpected: %.2f, Got: %.2f",
                case.remaining, case.width, case.iconSize, tostring(case.isReversed),
                case.expected, result)
        )
    end
    
    -- Smooth transitions
    local function TestTransition(start, finish, width, iconSize, isReversed, steps)
        local lastPos = nil
        local maxJump = (width - iconSize) / steps * 2  -- Allow for reasonable movement
        local success = true
        local errorDetails = {}
        
        for i = 0, steps do
            local t = i / steps
            local remaining = start + (finish - start) * t
            local pos = CalculatePosition(remaining, width, iconSize, isReversed)
            
            if lastPos then
                local jump = math.abs(pos - lastPos)
                if jump > maxJump then
                    success = false
                    table.insert(errorDetails, string.format(
                        "Large jump detected at step %d: %.2f -> %.2f (jump of %.2f)",
                        i, lastPos, pos, jump))
                end
            end
            lastPos = pos
        end
        
        framework:Assert(
            success,
            string.format("Transition test: %s to %s %s", 
                start, finish, isReversed and "(reversed)" or ""),
            success and "Smooth transition verified" or table.concat(errorDetails, "\n")
        )
        
        return success
    end
    
    -- Test various transitions
    local transitionTests = {
        { start = 300, finish = 0, name = "Full to empty" },
        { start = 0, finish = 300, name = "Empty to full" },
        { start = 150, finish = 0, name = "Half to empty" },
        { start = 0, finish = 150, name = "Empty to half" }
    }
    
    for _, test in ipairs(transitionTests) do
        TestTransition(test.start, test.finish, 300, 24, false, 50)  -- Normal direction
        TestTransition(test.start, test.finish, 300, 24, true, 50)   -- Reversed direction
    end
    
    return true
end

return suite 