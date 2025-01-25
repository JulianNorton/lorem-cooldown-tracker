--[[
Trinket Tracking Test Suite
========================
Tests for trinket cooldown tracking functionality
--]]

local suite = {
    name = "Trinket Tracking"
}

function suite.run(framework)
    -- Test 1: Basic trinket registration
    framework.mockState.inventory[13] = 12345  -- Mock trinket in first slot
    framework.mockState.cooldowns[12345] = {0, 0, 1}  -- Usable trinket with no current cooldown
    LCT.items.UpdateEquippedTrinkets()
    
    framework:Assert(
        LCT.cooldowns.trackedItems[13],
        "Basic trinket registration",
        "Trinket in slot 13 should be tracked"
    )
    
    -- Test 2: Multiple trinket registration
    framework.mockState.inventory[14] = 67890  -- Mock trinket in second slot
    framework.mockState.cooldowns[67890] = {0, 0, 1}  -- Usable trinket with no current cooldown
    LCT.items.UpdateEquippedTrinkets()
    
    framework:Assert(
        LCT.cooldowns.trackedItems[13] and LCT.cooldowns.trackedItems[14],
        "Multiple trinket registration",
        "Both trinket slots should be tracked"
    )
    
    -- Test 3: Non-usable trinket handling
    framework.mockState.inventory[13] = 99999  -- Non-usable trinket
    framework.mockState.cooldowns[99999] = {0, 0, 0}  -- enabled = 0 means no on-use effect
    LCT.items.UpdateEquippedTrinkets()
    
    framework:Assert(
        not LCT.cooldowns.trackedItems[13] and LCT.cooldowns.trackedItems[14],
        "Non-usable trinket handling",
        "Trinket without on-use effect should not be tracked"
    )
    
    -- Test 4: Trinket cooldown tracking
    framework.mockState.inventory[14] = 67890  -- Restore usable trinket
    framework.mockState.time = 1000
    framework.mockState.cooldowns[67890] = {1000, 120, 1}  -- 2 minute cooldown
    
    local start, duration, enabled = GetInventoryItemCooldown("player", 14)
    framework:Assert(
        start == 1000 and duration == 120 and enabled == 1,
        "Trinket cooldown tracking",
        string.format("Cooldown values - Start: %d, Duration: %d, Enabled: %d",
            start or 0, duration or 0, enabled or 0)
    )
    
    -- Test 5: Cooldown remaining calculation
    local remaining = LCT.cooldowns.UpdateCooldown(14, true)
    framework:Assert(
        remaining == 120,
        "Cooldown remaining calculation",
        string.format("Expected 120 seconds remaining, got %s",
            tostring(remaining))
    )
    
    -- Test 6: Multiple cooldown tracking
    framework.mockState.inventory[13] = 12345  -- Restore first usable trinket
    framework.mockState.cooldowns[12345] = {1000, 120, 1}  -- Same duration for both trinkets
    framework.mockState.cooldowns[67890] = {1000, 120, 1}
    LCT.items.UpdateEquippedTrinkets()
    
    local remaining1 = LCT.cooldowns.UpdateCooldown(13, true)
    local remaining2 = LCT.cooldowns.UpdateCooldown(14, true)
    
    framework:Assert(
        remaining1 == 120 and remaining2 == 120,
        "Multiple cooldown tracking",
        string.format("Trinket 1: %d seconds, Trinket 2: %d seconds",
            remaining1 or 0, remaining2 or 0)
    )
    
    -- Test 7: Cooldown expiration
    framework.mockState.time = 1200  -- Advance time past first trinket's cooldown
    remaining = LCT.cooldowns.UpdateCooldown(13, true)
    
    framework:Assert(
        not remaining,
        "Cooldown expiration",
        "Cooldown should be expired"
    )
    
    -- Test 8: Trinket unequip handling
    framework.mockState.inventory[13] = nil
    LCT.items.UpdateEquippedTrinkets()
    
    framework:Assert(
        not LCT.cooldowns.trackedItems[13] and LCT.cooldowns.trackedItems[14],
        "Trinket unequip handling",
        "Unequipped trinket should not be tracked"
    )
    
    -- Test 9: Invalid slot handling
    local result = LCT.cooldowns.UpdateCooldown(15, true)  -- Invalid trinket slot
    framework:Assert(
        not result,
        "Invalid slot handling",
        "Invalid trinket slot should return nil"
    )
    
    -- Test 10: Cooldown update batch
    framework.mockState.inventory[13] = 12345
    framework.mockState.inventory[14] = 67890
    framework.mockState.cooldowns[12345] = {1000, 120, 1}
    framework.mockState.cooldowns[67890] = {1000, 120, 1}
    framework.mockState.time = 1000
    
    -- First verify the trinkets are tracked
    LCT.items.UpdateEquippedTrinkets()
    framework:Assert(
        LCT.cooldowns.trackedItems[13] and LCT.cooldowns.trackedItems[14],
        "Pre-batch update check",
        string.format("Tracked items - Slot 13: %s, Slot 14: %s",
            tostring(LCT.cooldowns.trackedItems[13]), tostring(LCT.cooldowns.trackedItems[14]))
    )
    
    -- Then verify individual cooldown updates work
    local remaining13 = LCT.cooldowns.UpdateCooldown(13, true)
    local remaining14 = LCT.cooldowns.UpdateCooldown(14, true)
    framework:Assert(
        remaining13 == 120 and remaining14 == 120,
        "Individual cooldown updates",
        string.format("Individual updates - Slot 13: %s, Slot 14: %s",
            tostring(remaining13), tostring(remaining14))
    )
    
    -- Finally test batch update
    LCT.cooldowns.UpdateAll()
    framework:Assert(
        LCT.cooldowns.activeCooldowns[13] == 120 and LCT.cooldowns.activeCooldowns[14] == 120,
        "Cooldown update batch",
        string.format("Active cooldowns - Slot 13: %s, Slot 14: %s\nTracked items - Slot 13: %s, Slot 14: %s",
            tostring(LCT.cooldowns.activeCooldowns[13]), tostring(LCT.cooldowns.activeCooldowns[14]),
            tostring(LCT.cooldowns.trackedItems[13]), tostring(LCT.cooldowns.trackedItems[14]))
    )
    
    return true
end

return suite 