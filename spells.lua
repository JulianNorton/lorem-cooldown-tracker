local addonName, LCT = ...

-- Spell tracking module
local spells = {}
LCT.spells = spells

-- Function to scan spellbook and build list of trackable spells
function spells.ScanSpellBook()
    local _, playerClass = UnitClass("player")
    local trackedSpells = {}
    
    -- Scan all spellbook tabs
    for tabIndex = 1, GetNumSpellTabs() do
        local _, _, offset, numSpells = GetSpellTabInfo(tabIndex)
        
        -- Scan all spells in current tab
        for spellIndex = offset + 1, offset + numSpells do
            local spellType, spellID = GetSpellBookItemInfo(spellIndex, "player")
            if spellType == "SPELL" and spellID then
                local cooldown = GetSpellBaseCooldown(spellID)
                -- Only track spells with cooldowns between 5s and GCD
                if cooldown and cooldown > 5000 then
                    trackedSpells[spellID] = true
                end
            end
        end
    end
    
    return trackedSpells
end

-- Initialize spell tracking
function spells.Initialize()
    -- Register spell-related events
    LCT.frame:RegisterEvent("SPELLS_CHANGED")
    LCT.frame:RegisterEvent("LEARNED_SPELL_IN_TAB")
    LCT.frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    
    -- Set up event handler
    LCT.frame:HookScript("OnEvent", function(self, event, ...)
        if event == "SPELLS_CHANGED" or event == "LEARNED_SPELL_IN_TAB" then
            spells.ScanSpellBook()
        elseif event == "SPELL_UPDATE_COOLDOWN" then
            LCT.cooldowns.UpdateAll()
        end
    end)
end

-- Return the module
return spells 