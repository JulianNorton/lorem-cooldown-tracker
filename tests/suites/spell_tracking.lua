--[[
Spell Tracking Test Suite
=====================
Tests for spell cooldown tracking functionality
--]]

local suite = {
    name = "Spell Tracking"
}

function suite.run(framework)
    -- Test 1: Basic spell scanning
    framework.mockState.spells.tabs = {
        {
            name = "General",
            texture = "Interface\\Icons\\Ability_Warrior_Charge",
            offset = 0,
            numSpells = 2
        }
    }
    
    framework.mockState.spells.known = {
        [1] = {
            type = "SPELL",
            id = 100,
            name = "Test Spell 1",
        },
        [2] = {
            type = "SPELL",
            id = 101,
            name = "Test Spell 2",
        }
    }
    
    framework.mockState.spells.cooldowns = {
        [100] = 10000,  -- 10 second cooldown
        [101] = 3000    -- 3 second cooldown (should not be tracked)
    }
    
    local trackedSpells = LCT.spells.ScanSpellBook()
    framework:Assert(
        trackedSpells[100] and not trackedSpells[101],
        "Basic spell scanning",
        "Should track spells with cooldowns > 5s and ignore shorter cooldowns"
    )
    
    -- Test 2: Multiple spell tabs
    framework.mockState.spells.tabs = {
        {
            name = "General",
            texture = "Interface\\Icons\\Ability_Warrior_Charge",
            offset = 0,
            numSpells = 1
        },
        {
            name = "Combat",
            texture = "Interface\\Icons\\Ability_Warrior_BattleShout",
            offset = 1,
            numSpells = 2
        }
    }
    
    framework.mockState.spells.known = {
        [1] = {
            type = "SPELL",
            id = 100,
            name = "Test Spell 1",
        },
        [2] = {
            type = "SPELL",
            id = 101,
            name = "Test Spell 2",
        },
        [3] = {
            type = "SPELL",
            id = 102,
            name = "Test Spell 3",
        }
    }
    
    framework.mockState.spells.cooldowns = {
        [100] = 10000,
        [101] = 20000,
        [102] = 30000
    }
    
    trackedSpells = LCT.spells.ScanSpellBook()
    framework:Assert(
        trackedSpells[100] and trackedSpells[101] and trackedSpells[102],
        "Multiple spell tabs",
        "Should track spells across multiple tabs"
    )
    
    -- Test 3: Druid Enrage handling
    framework.mockState.spells.playerClass = "DRUID"
    framework.mockState.spells.known[4] = {
        type = "SPELL",
        id = 5229,
        name = "Enrage"
    }
    
    trackedSpells = LCT.spells.ScanSpellBook()
    framework:Assert(
        trackedSpells[5229],
        "Druid Enrage detection",
        "Should detect and track Druid Enrage spell"
    )
    
    -- Test 4: Non-spell entries
    framework.mockState.spells.known[5] = {
        type = "FUTURESPELL",
        id = 103,
        name = "Future Spell"
    }
    
    trackedSpells = LCT.spells.ScanSpellBook()
    framework:Assert(
        not trackedSpells[103],
        "Non-spell entry handling",
        "Should ignore non-SPELL entries"
    )
    
    -- Test 5: Event handling
    local eventFrame = CreateFrame("Frame")
    local eventsFired = {}
    eventFrame.RegisterEvent = function(self, event)
        eventsFired[event] = true
    end
    
    _G.CreateFrame = function(type)
        return eventFrame
    end
    
    LCT.spells.Initialize()
    framework:Assert(
        eventsFired["SPELLS_CHANGED"] and
        eventsFired["LEARNED_SPELL_IN_TAB"] and
        eventsFired["SPELL_UPDATE_COOLDOWN"] and
        eventsFired["PLAYER_ENTERING_WORLD"],
        "Event registration",
        "Should register all required events"
    )
    
    -- Test 6: Cooldown updates
    local cooldownUpdateCalled = false
    LCT.cooldowns.UpdateAll = function()
        cooldownUpdateCalled = true
    end
    
    if eventFrame.scripts and eventFrame.scripts["OnEvent"] then
        eventFrame.scripts["OnEvent"](eventFrame, "SPELL_UPDATE_COOLDOWN")
    end
    
    framework:Assert(
        cooldownUpdateCalled,
        "Cooldown update handling",
        "Should call UpdateAll when SPELL_UPDATE_COOLDOWN fires"
    )
    
    return true
end

return suite 