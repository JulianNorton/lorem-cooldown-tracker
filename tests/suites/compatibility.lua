--[[
Compatibility Test Suite
=====================
Tests for compatibility with other addons
--]]

local suite = {
    name = "Addon Compatibility"
}

function suite.run(framework)
    -- Test 1: MinimapButtonButton compatibility
    local button = CreateFrame("Frame", "MinimapButtonButton", UIParent, "BackdropTemplate")
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(7)  -- MinimapButtonButton uses level 7
    
    framework:Assert(
        button:GetFrameStrata() == "MEDIUM" and button:GetFrameLevel() == 7,
        "MinimapButtonButton frame level",
        string.format("Strata: %s, Level: %d", button:GetFrameStrata(), button:GetFrameLevel())
    )
    
    -- Test 2: MinimapButtonButton SetPoint variations
    local success = pcall(function()
        button:SetPoint("CENTER")  -- Single argument
        button:SetPoint("CENTER", UIParent, "CENTER")  -- Three arguments
        button:SetPoint("CENTER", UIParent, "CENTER", 0, 0)  -- Five arguments
        button:SetPoint("CENTER", 0, 0)  -- Three arguments with coordinates
    end)
    
    framework:Assert(
        success,
        "MinimapButtonButton SetPoint variations",
        "All SetPoint variations should work"
    )
    
    -- Test 3: OmniBar tooltip compatibility
    local tooltip = CreateFrame("Frame", "GameTooltip")
    success = pcall(function()
        tooltip:SetOwner(UIParent, "ANCHOR_NONE")
        tooltip:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT")
    end)
    
    framework:Assert(
        success and tooltip:GetOwner() == UIParent and tooltip:GetFrameStrata() == "TOOLTIP",
        "OmniBar tooltip functionality",
        string.format("Tooltip owner: %s, Strata: %s",
            tostring(tooltip:GetOwner()), tooltip:GetFrameStrata())
    )
    
    -- Test 4: Frame method chaining
    local frame = CreateFrame("Frame")
    success = pcall(function()
        frame:SetPoint("CENTER")
             :SetSize(100, 100)
             :SetFrameLevel(1)
             :SetFrameStrata("MEDIUM")
             :EnableMouse(true)
             :SetClampedToScreen(true)
    end)
    
    framework:Assert(
        success,
        "Frame method chaining",
        "Method chaining should work"
    )
    
    -- Test 5: Event propagation
    local parent = CreateFrame("Frame")
    local child = CreateFrame("Frame", nil, parent)
    local eventFired = 0
    
    parent:SetScript("OnEvent", function() eventFired = eventFired + 1 end)
    child:SetScript("OnEvent", function() eventFired = eventFired + 1 end)
    
    parent:RegisterEvent("TEST_EVENT")
    child:RegisterEvent("TEST_EVENT")
    
    parent:FireEvent("TEST_EVENT")
    child:FireEvent("TEST_EVENT")
    
    framework:Assert(
        eventFired == 2,
        "Event propagation",
        string.format("Expected 2 events, got %d", eventFired)
    )
    
    -- Test 6: Frame property inheritance
    parent:SetFrameLevel(5)
    child:SetFrameLevel(6)
    
    framework:Assert(
        child:GetFrameLevel() > parent:GetFrameLevel(),
        "Frame level inheritance",
        string.format("Child level (%d) should be higher than parent (%d)",
            child:GetFrameLevel(), parent:GetFrameLevel())
    )
    
    -- Test 7: Frame cleanup on parent change
    local newParent = CreateFrame("Frame")
    local oldParentChildCount = #parent.children
    child:SetParent(newParent)
    
    framework:Assert(
        #parent.children == oldParentChildCount - 1 and #newParent.children == 1,
        "Frame cleanup on parent change",
        string.format("Old parent children: %d, New parent children: %d",
            #parent.children, #newParent.children)
    )
    
    -- Test 8: Frame visibility chain
    local grandParent = CreateFrame("Frame")
    local parentFrame = CreateFrame("Frame", nil, grandParent)
    local childFrame = CreateFrame("Frame", nil, parentFrame)
    
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
    
    -- Test 9: Frame method availability after parent change
    success = pcall(function()
        childFrame:SetPoint("CENTER", newParent, "CENTER")
                 :SetSize(50, 50)
                 :SetFrameLevel(7)
    end)
    
    framework:Assert(
        success,
        "Frame methods after parent change",
        "Frame methods should work after parent change"
    )
    
    -- Test 10: Frame template compatibility
    local templateFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    success = pcall(function()
        templateFrame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        templateFrame:SetBackdropColor(1, 0, 0, 1)
    end)
    
    framework:Assert(
        success,
        "Frame template compatibility",
        "BackdropTemplate should work correctly"
    )
    
    return true
end

return suite 