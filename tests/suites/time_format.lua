--[[
Time Format Test Suite
===================
Tests for time formatting functionality
--]]

local suite = {
    name = "Time Format"
}

function suite.run(framework)
    local function FormatTimeText(remaining)
        -- Handle invalid inputs
        if type(remaining) ~= "number" then
            return "0.0"
        end
        
        -- Handle negative values
        if remaining < 0 then
            return "0.0"
        end
        
        if remaining >= 300 then
            return tostring(math.floor(remaining / 60))
        elseif remaining >= 10 then
            return tostring(math.floor(remaining + 0.5))  -- Round to nearest integer
        else
            -- Round to nearest 0.1
            return string.format("%.1f", math.floor(remaining * 10 + 0.5) / 10)
        end
    end
    
    -- Basic time format tests
    local testCases = {
        { input = 600, expected = "10", name = "10 minutes" },
        { input = 300, expected = "5", name = "5 minutes" },
        { input = 299, expected = "299", name = "Just under 5 minutes" },
        { input = 10.1, expected = "10", name = "Just over 10 seconds" },
        { input = 9.99, expected = "10.0", name = "Just under 10 seconds" },
        { input = 5.55, expected = "5.6", name = "Decimal rounding" },
        { input = 0.1, expected = "0.1", name = "Small decimal" },
        { input = 0, expected = "0.0", name = "Zero" },
        { input = -0.1, expected = "0.0", name = "Negative time" }
    }
    
    for _, case in ipairs(testCases) do
        local result = FormatTimeText(case.input)
        framework:Assert(
            result == case.expected,
            string.format("Time format test: %s", case.name),
            string.format("Input: %.1f, Expected: %s, Got: %s", 
                case.input, case.expected, result)
        )
    end
    
    -- Edge cases
    local edgeCases = {
        { input = 299.99, expected = "300", name = "Boundary case: Just under 5 minutes" },
        { input = 10.01, expected = "10", name = "Boundary case: Just over 10 seconds" },
        { input = 9.95, expected = "10.0", name = "Boundary case: Rounding up under 10 seconds" }
    }
    
    for _, case in ipairs(edgeCases) do
        local result = FormatTimeText(case.input)
        framework:Assert(
            result == case.expected,
            string.format("Edge case test: %s", case.name),
            string.format("Input: %.2f, Expected: %s, Got: %s", 
                case.input, case.expected, result)
        )
    end
    
    -- Invalid input handling
    local function testInvalidInput(input, expectedBehavior)
        local result = FormatTimeText(input)
        framework:Assert(
            result == "0.0",
            string.format("Invalid input handling: %s", type(input)),
            string.format("Input: %s, Expected behavior: %s, Got: %s",
                tostring(input), expectedBehavior, result)
        )
    end
    
    testInvalidInput(nil, "Should handle nil gracefully")
    testInvalidInput("not a number", "Should handle non-numeric input")
    testInvalidInput({}, "Should handle table input")
    
    return true
end

return suite 