--[[
PvP Trinket Test Suite
===================
Tests for PvP trinket functionality
--]]

local suite = {
    name = "PvP Trinket"
}

function suite.run(framework)
    -- Test 1: Alliance Insignia detection
    framework.mockState.inventory[13] = 18854  -- Insignia of the Alliance
    LCT.items.UpdateEquippedTrinkets()
    
    framework:Assert(
        LCT.cooldowns.trackedItems[13],
        "Alliance Insignia detection",
        "Alliance Insignia should be tracked"
    )
    
    -- Test 2: Horde Insignia detection
    framework.mockState.inventory[13] = 18864  -- Insignia of the Horde
    LCT.items.UpdateEquippedTrinkets()
    
    framework:Assert(
        LCT.cooldowns.trackedItems[13],
        "Horde Insignia detection",
        "Horde Insignia should be tracked"
    )
    
    -- Test 3: PvP trinket cooldown tracking
    framework.mockState.time = 1000
    framework.mockState.cooldowns[18864] = {1000, 120, 1}  -- 2 minute cooldown
    
    local start, duration, enabled = GetInventoryItemCooldown("player", 13)
    framework:Assert(
        start == 1000 and duration == 120 and enabled == 1,
        "PvP trinket cooldown tracking",
        string.format("Cooldown values - Start: %d, Duration: %d, Enabled: %d",
            start or 0, duration or 0, enabled or 0)
    )
    
    -- Test 4: PvP trinket cooldown remaining
    local remaining = LCT.cooldowns.UpdateCooldown(13, true)
    framework:Assert(
        remaining == 120,
        "PvP trinket cooldown remaining",
        string.format("Expected 120 seconds remaining, got %s",
            tostring(remaining))
    )
    
    -- Test 5: PvP trinket cooldown expiration
    framework.mockState.time = 1200  -- Advance time past cooldown
    remaining = LCT.cooldowns.UpdateCooldown(13, true)
    
    framework:Assert(
        not remaining,
        "PvP trinket cooldown expiration",
        "Cooldown should be expired"
    )
    
    -- Test 6: PvP trinket unequip handling
    framework.mockState.inventory[13] = nil
    LCT.items.UpdateEquippedTrinkets()
    
    framework:Assert(
        not LCT.cooldowns.trackedItems[13],
        "PvP trinket unequip handling",
        "Unequipped PvP trinket should not be tracked"
    )
    
    -- Test 7: Multiple PvP trinkets
    framework.mockState.inventory[13] = 18854  -- Alliance in first slot
    framework.mockState.inventory[14] = 18864  -- Horde in second slot
    framework.mockState.time = 1000
    framework.mockState.cooldowns[18854] = {1000, 120, 1}
    framework.mockState.cooldowns[18864] = {1000, 120, 1}
    LCT.items.UpdateEquippedTrinkets()
    
    framework:Assert(
        LCT.cooldowns.trackedItems[13] and LCT.cooldowns.trackedItems[14],
        "Multiple PvP trinkets",
        "Both PvP trinkets should be tracked"
    )
    
    -- Test 8: PvP trinket cooldown states
    framework.mockState.time = 1000
    framework.mockState.cooldowns[18854] = {1000, 120, 1}  -- First trinket on cooldown
    framework.mockState.cooldowns[18864] = {0, 0, 1}       -- Second trinket ready
    
    local remaining1 = LCT.cooldowns.UpdateCooldown(13, true)
    local remaining2 = LCT.cooldowns.UpdateCooldown(14, true)
    
    framework:Assert(
        remaining1 == 120 and not remaining2,
        "PvP trinket cooldown states",
        string.format("Trinket 1: %s, Trinket 2: %s",
            tostring(remaining1), tostring(remaining2))
    )
    
    -- Test 9: PvP trinket disabled state
    framework.mockState.cooldowns[18854] = {0, 0, 0}  -- Disabled state
    remaining = LCT.cooldowns.UpdateCooldown(13, true)
    
    framework:Assert(
        not remaining,
        "PvP trinket disabled state",
        "Disabled PvP trinket should return nil"
    )
    
    -- Test 10: PvP trinket batch update
    framework.mockState.inventory[13] = 18854
    framework.mockState.inventory[14] = 18864
    framework.mockState.cooldowns[18854] = {1000, 120, 1}
    framework.mockState.cooldowns[18864] = {1000, 120, 1}
    framework.mockState.time = 1000
    
    LCT.cooldowns.UpdateAll()
    framework:Assert(
        LCT.cooldowns.trackedItems[13] and LCT.cooldowns.trackedItems[14],
        "PvP trinket batch update",
        "Batch update should process all PvP trinkets"
    )
    
    return true
end

return suite 