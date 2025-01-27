local addonName, LCT = ...

-- Spell tracking module
local spells = {}
LCT.spells = spells

-- Function to scan spellbook and build list of trackable spells
function spells.ScanSpellBook()
    LCT:Debug("Scanning spellbook...")
    local _, playerClass = UnitClass("player")
    LCT:Debug("Player class:", playerClass)
    local trackedSpells = {}
    local count = 0
    
    -- Scan all spellbook tabs
    local numTabs = GetNumSpellTabs()
    LCT:Debug("Found", numTabs, "spellbook tabs")
    
    for tabIndex = 1, numTabs do
        local tabName, _, offset, numSpells = GetSpellTabInfo(tabIndex)
        LCT:Debug("Scanning tab", tabIndex, tabName, "with", numSpells, "spells")
        
        -- Scan all spells in current tab
        for spellIndex = offset + 1, offset + numSpells do
            local spellType, spellID = GetSpellBookItemInfo(spellIndex, "player")
            local spellName = GetSpellBookItemName(spellIndex, "player")
            
            if spellType == "SPELL" and spellID then
                local cooldown = GetSpellBaseCooldown(spellID)
                LCT:Debug("Found spell:", spellName, "ID:", spellID, "Cooldown:", cooldown and cooldown/1000 or "none")
                
                -- Only track spells with cooldowns between 5s and GCD
                if cooldown and cooldown > 5000 then
                    trackedSpells[spellID] = true
                    -- Register the spell with the cooldowns module
                    if LCT.cooldowns and LCT.cooldowns.RegisterSpell then
                        LCT.cooldowns.RegisterSpell(spellID)
                        count = count + 1
                        LCT:Debug("Registered spell:", spellName, "with", cooldown/1000, "second cooldown")
                    else
                        LCT:Debug("ERROR - Could not register spell, cooldowns module not ready")
                    end
                end
            end
        end
    end
    
    -- Manually check for Enrage if player is a Druid
    if playerClass == "DRUID" then
        local enrageID = 5229  -- Enrage spell ID
        local name = GetSpellInfo(enrageID)
        if IsSpellKnown(enrageID) then
            LCT:Debug("Found Druid Enrage spell")
            trackedSpells[enrageID] = true
            if LCT.cooldowns and LCT.cooldowns.RegisterSpell then
                LCT.cooldowns.RegisterSpell(enrageID)
                count = count + 1
                LCT:Debug("Registered Enrage spell")
            end
        end
    end
    
    LCT:Debug("Found", count, "spells with cooldowns")
    return trackedSpells
end

-- Initialize spell tracking
function spells.Initialize()
    LCT:Debug("Initializing spell tracking")
    
    -- Create a separate frame for spell events
    local eventFrame = CreateFrame("Frame")
    
    -- Register spell-related events
    eventFrame:RegisterEvent("SPELLS_CHANGED")
    eventFrame:RegisterEvent("LEARNED_SPELL_IN_TAB")
    eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    -- Set up event handler
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        LCT:Debug("Spell event fired:", event)
        if event == "SPELLS_CHANGED" or event == "LEARNED_SPELL_IN_TAB" or event == "PLAYER_ENTERING_WORLD" then
            LCT:Debug("Spell list changed or player entered world, rescanning...")
            spells.ScanSpellBook()
        elseif event == "SPELL_UPDATE_COOLDOWN" then
            if LCT.cooldowns and LCT.cooldowns.UpdateAll then
                LCT.cooldowns.UpdateAll()
            end
        end
    end)
    
    -- Initial scan
    C_Timer.After(2, function()
        LCT:Debug("Performing initial spell scan")
        spells.ScanSpellBook()
    end)
end

-- Return the module
return spells 