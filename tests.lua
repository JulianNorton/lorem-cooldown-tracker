local addonName, LCT = ...

-- Test Framework
LCT.tests = {}
local tests = LCT.tests

function tests:RunAll()
    print("=== Lorem Cooldown Tracker Tests ===")
    local passed = 0
    local total = 0
    
    -- Test 1: Frame Creation
    total = total + 1
    if LCT.frame and LCT.frame.GetObjectType and LCT.frame:GetObjectType() == "Frame" then
        print("✓ Test 1: Main frame exists")
        passed = passed + 1
    else
        print("✗ Test 1: Main frame missing")
    end
    
    -- Test 2: Frame Properties
    total = total + 1
    if LCT.frame:GetWidth() > 0 and LCT.frame:GetHeight() > 0 and LCT.frame:IsVisible() then
        print("✓ Test 2: Frame is properly sized and visible")
        passed = passed + 1
    else
        local width = LCT.frame:GetWidth()
        local height = LCT.frame:GetHeight()
        local visible = LCT.frame:IsVisible()
        print(string.format("✗ Test 2: Frame issues - Width: %d, Height: %d, Visible: %s", 
            width, height, tostring(visible)))
    end
    
    -- Test 3: Frame Locking
    total = total + 1
    if type(LCT.frame.locked) == "boolean" then
        print("✓ Test 3: Frame lock property exists")
        passed = passed + 1
    else
        print("✗ Test 3: Frame lock property missing")
    end
    
    -- Test 4: Settings Frame
    total = total + 1
    if LCT.settingsFrame and LCT.settingsFrame:GetObjectType() == "Frame" then
        print("✓ Test 4: Settings frame exists")
        passed = passed + 1
    else
        print("✗ Test 4: Settings frame missing")
    end
    
    -- Test 5: Spell Tracking
    total = total + 1
    local testSpell = 5229 -- Enrage, a druid spell
    local start, duration = GetSpellCooldown(testSpell)
    if type(start) == "number" and type(duration) == "number" then
        print("✓ Test 5: Cooldown tracking functional")
        passed = passed + 1
    else
        print("✗ Test 5: Cooldown tracking failed")
    end

    -- Summary
    print("=== Test Summary ===")
    print(string.format("Passed: %d/%d tests", passed, total))
    print("=====================")
    
    return passed == total
end

-- Add slash command for testing
SLASH_LCTTEST1 = "/lcttest"
SlashCmdList["LCTTEST"] = function(msg)
    tests:RunAll()
end 