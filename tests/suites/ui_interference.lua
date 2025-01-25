--[[
UI Non-interference Test Suite
==========================
Tests to ensure the addon doesn't interfere with other UI elements
--]]

local suite = {
    name = "UI Non-interference"
}

function suite.run(framework)
    -- Test 1: Frame strata
    local icon = CreateFrame("Frame", nil, UIParent)
    icon:SetFrameStrata("MEDIUM")
    
    framework:Assert(
        icon:GetFrameStrata() == "MEDIUM",
        "Frame strata setting",
        string.format("Expected MEDIUM strata, got %s", icon:GetFrameStrata())
    )
    
    -- Test 2: Frame level
    icon:SetFrameLevel(5)
    framework:Assert(
        icon:GetFrameLevel() == 5,
        "Frame level setting",
        string.format("Expected level 5, got %d", icon:GetFrameLevel())
    )
    
    -- Test 3: Frame naming
    local namedIcon = CreateFrame("Frame", "TestIcon", UIParent)
    framework:Assert(
        namedIcon:GetName() == "TestIcon",
        "Frame naming",
        string.format("Expected name 'TestIcon', got %s", namedIcon:GetName())
    )
    
    -- Test 4: Parent-child relationship
    local child = CreateFrame("Frame", nil, icon)
    framework:Assert(
        child:GetParent() == icon,
        "Parent-child relationship",
        "Child frame should have correct parent"
    )
    
    -- Test 5: Frame visibility
    icon:Show()
    child:Show()
    
    framework:Assert(
        icon:IsShown() and child:IsShown(),
        "Frame visibility",
        "Both parent and child frames should be shown"
    )
    
    -- Test 6: Frame visibility inheritance
    icon:Hide()
    framework:Assert(
        not child:IsVisible() and child:IsShown(),
        "Frame visibility inheritance",
        "Child should not be visible when parent is hidden"
    )
    
    -- Test 7: Frame positioning
    icon:ClearAllPoints()
    icon:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    
    local point, relativeTo, relativePoint, xOffset, yOffset = icon:GetPoint()
    framework:Assert(
        point == "CENTER" and relativeTo == UIParent and relativePoint == "CENTER" 
        and xOffset == 0 and yOffset == 0,
        "Frame positioning",
        string.format("Point: %s, RelativeTo: %s, RelativePoint: %s, Offset: %d, %d",
            point, tostring(relativeTo), relativePoint, xOffset or 0, yOffset or 0)
    )
    
    -- Test 8: Frame size
    icon:SetSize(32, 32)
    framework:Assert(
        icon:GetWidth() == 32 and icon:GetHeight() == 32,
        "Frame size",
        string.format("Size: %dx%d", icon:GetWidth(), icon:GetHeight())
    )
    
    -- Test 9: Frame scale
    icon:SetScale(1.5)
    framework:Assert(
        icon:GetScale() == 1.5,
        "Frame scale",
        string.format("Expected scale 1.5, got %.1f", icon:GetScale())
    )
    
    -- Test 10: Frame alpha
    icon:SetAlpha(0.5)
    framework:Assert(
        icon:GetAlpha() == 0.5,
        "Frame alpha",
        string.format("Expected alpha 0.5, got %.1f", icon:GetAlpha())
    )
    
    -- Test 11: Mouse interaction
    icon:EnableMouse(false)
    framework:Assert(
        not icon:IsMouseEnabled(),
        "Mouse interaction",
        "Frame should not interact with mouse"
    )
    
    -- Test 12: Frame layering
    local topFrame = CreateFrame("Frame", nil, UIParent)
    local bottomFrame = CreateFrame("Frame", nil, UIParent)
    
    topFrame:SetFrameStrata("HIGH")
    bottomFrame:SetFrameStrata("LOW")
    
    framework:Assert(
        topFrame:GetFrameStrataLevel() > bottomFrame:GetFrameStrataLevel(),
        "Frame layering",
        string.format("Top frame (%s, level %d) should be above bottom frame (%s, level %d)",
            topFrame:GetFrameStrata(), topFrame:GetFrameStrataLevel(),
            bottomFrame:GetFrameStrata(), bottomFrame:GetFrameStrataLevel())
    )
    
    return true
end

return suite 