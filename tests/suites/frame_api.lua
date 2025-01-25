--[[
Frame API Test Suite
==================
Tests for WoW frame API compatibility
--]]

local suite = {
    name = "Frame API Compatibility"
}

function suite.run(framework)
    -- Test 1: Basic Frame Creation and Parent Setting
    local parent = CreateFrame("Frame", "TestParent")
    local child = CreateFrame("Frame", "TestChild", parent)
    
    framework:Assert(
        child:GetParent() == parent,
        "Frame parent-child relationship",
        "Child's parent should be set correctly"
    )
    
    -- Test 2: SetParent functionality
    local newParent = CreateFrame("Frame", "NewParent")
    child:SetParent(newParent)
    
    framework:Assert(
        child:GetParent() == newParent and #parent.children == 0 and #newParent.children == 1,
        "SetParent functionality",
        string.format("Parent children: %d, New parent children: %d", 
            #parent.children, #newParent.children)
    )
    
    -- Test 3: Frame Name and ID
    child:SetID(5)
    framework:Assert(
        child:GetName() == "TestChild" and child:GetID() == 5,
        "Frame name and ID handling",
        string.format("Name: %s, ID: %d", child:GetName(), child:GetID())
    )
    
    -- Test 4: Frame Strata and Level
    child:SetFrameStrata("HIGH"):SetFrameLevel(5)  -- Test method chaining
    framework:Assert(
        child:GetFrameStrata() == "HIGH" and child:GetFrameLevel() == 5,
        "Frame strata and level handling",
        string.format("Strata: %s, Level: %d", child:GetFrameStrata(), child:GetFrameLevel())
    )
    
    -- Test 5: Mouse Interaction
    child:EnableMouse(true)
    child:SetMovable(true)
    child:SetResizable(true)
    
    framework:Assert(
        child:IsMouseEnabled() and child:IsMovable() and child:IsResizable(),
        "Mouse interaction properties",
        string.format("Mouse enabled: %s, Movable: %s, Resizable: %s",
            tostring(child:IsMouseEnabled()),
            tostring(child:IsMovable()),
            tostring(child:IsResizable()))
    )
    
    -- Test 6: Backdrop
    local backdrop = {
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    }
    child:SetBackdrop(backdrop)
    child:SetBackdropColor(1, 0, 0, 1)
    
    local r, g, b, a = child:GetBackdropColor()
    framework:Assert(
        child:GetBackdrop() == backdrop and r == 1 and g == 0 and b == 0 and a == 1,
        "Backdrop handling",
        string.format("Color values - R: %.1f, G: %.1f, B: %.1f, A: %.1f", r, g, b, a)
    )
    
    -- Test 7: Event Handling
    local eventFired = false
    child:SetScript("OnEvent", function() eventFired = true end)
    child:RegisterEvent("TEST_EVENT")
    child:FireEvent("TEST_EVENT")
    child:UnregisterAllEvents()
    
    framework:Assert(
        eventFired,
        "Event handling",
        "Event should have fired and been handled"
    )
    
    -- Test 8: Required Frame Methods
    local requiredMethods = {
        "SetClampedToScreen", "SetOwner", "CreateTexture", "CreateFontString",
        "SetScript", "GetScript", "SetPoint", "GetPoint", "SetSize",
        "GetWidth", "GetHeight", "SetParent", "GetParent", "Show",
        "Hide", "IsShown", "IsVisible", "SetFrameStrata", "GetFrameStrata",
        "SetFrameLevel", "GetFrameLevel", "SetBackdrop", "GetBackdrop",
        "SetBackdropColor", "GetBackdropColor", "ClearAllPoints",
        "SetScale", "GetScale", "SetAlpha", "GetAlpha", "RegisterEvent",
        "UnregisterEvent", "UnregisterAllEvents"
    }
    
    local missingMethods = {}
    for _, method in ipairs(requiredMethods) do
        if not child[method] then
            table.insert(missingMethods, method)
        end
    end
    
    framework:Assert(
        #missingMethods == 0,
        "Required frame methods",
        #missingMethods == 0 and "All methods present" or 
        "Missing methods: " .. table.concat(missingMethods, ", ")
    )
    
    -- Test 9: SetClampedToScreen functionality
    child:SetClampedToScreen(true)
    framework:Assert(
        child.clampedToScreen == true,
        "SetClampedToScreen functionality",
        string.format("Clamped to screen: %s", tostring(child.clampedToScreen))
    )
    
    -- Test 10: SetOwner functionality
    local owner = CreateFrame("Frame")
    child:SetOwner(owner, "ANCHOR_TOPLEFT")
    framework:Assert(
        child.owner == owner and child.anchor == "ANCHOR_TOPLEFT",
        "SetOwner functionality",
        string.format("Owner set: %s, Anchor: %s", 
            tostring(child.owner == owner), tostring(child.anchor))
    )
    
    -- Test 11: Frame Visibility Chain
    local grandParent = CreateFrame("Frame", "GrandParent")
    local parentFrame = CreateFrame("Frame", "Parent", grandParent)
    local childFrame = CreateFrame("Frame", "Child", parentFrame)
    
    grandParent:Show()
    parentFrame:Show()
    childFrame:Show()
    
    framework:Assert(
        childFrame:IsVisible(),
        "Frame visibility chain - all shown",
        "Child should be visible when all ancestors are shown"
    )
    
    parentFrame:Hide()
    framework:Assert(
        not childFrame:IsVisible() and childFrame:IsShown(),
        "Frame visibility chain - parent hidden",
        "Child should not be visible but should still be shown"
    )
    
    -- Test 12: Point Setting and Getting
    childFrame:ClearAllPoints()
    childFrame:SetPoint("CENTER", parentFrame, "CENTER", 10, 20)
    
    local point, relativeTo, relativePoint, xOffset, yOffset = childFrame:GetPoint()
    framework:Assert(
        point == "CENTER" and relativeTo == parentFrame and relativePoint == "CENTER" 
        and xOffset == 10 and yOffset == 20,
        "Point setting and getting",
        string.format("Point: %s, RelativeTo: %s, RelativePoint: %s, Offset: %d, %d",
            point, tostring(relativeTo), relativePoint, xOffset or 0, yOffset or 0)
    )
    
    return true
end

return suite 