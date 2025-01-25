-- Mock WoW API functions
local mockEnv = {
    time = 0,
    inventory = {},
    cooldowns = {},
    frames = {},
    events = {},
    spells = {
        known = {},
        cooldowns = {},
        tabs = {},
        playerClass = "WARRIOR"
    }
}

-- Frame strata levels
local FRAME_STRATA_LEVELS = {
    BACKGROUND = 1,
    LOW = 2,
    MEDIUM = 3,
    HIGH = 4,
    DIALOG = 5,
    FULLSCREEN = 6,
    FULLSCREEN_DIALOG = 7,
    TOOLTIP = 8
}

-- Frame creation and management
local function CreateFrame(frameType, name, parent, template)
    local frame = {
        children = {},
        points = {},
        scripts = {},
        events = {},
        shown = true,
        alpha = 1,
        scale = 1,
        level = 1,
        strata = "MEDIUM",
        owner = nil,
        
        SetParent = function(self, newParent)
            if self.parent then
                for i, child in ipairs(self.parent.children) do
                    if child == self then
                        table.remove(self.parent.children, i)
                        break
                    end
                end
            end
            self.parent = newParent
            if newParent then
                table.insert(newParent.children, self)
            end
            return self
        end,
        
        GetParent = function(self)
            return self.parent
        end,
        
        SetPoint = function(self, ...)
            table.insert(self.points, {...})
            return self
        end,
        
        GetPoint = function(self, index)
            index = index or 1
            return unpack(self.points[index])
        end,
        
        ClearAllPoints = function(self)
            self.points = {}
            return self
        end,
        
        SetSize = function(self, width, height)
            self.width = width
            self.height = height
            return self
        end,
        
        GetWidth = function(self)
            return self.width or 0
        end,
        
        GetHeight = function(self)
            return self.height or 0
        end,
        
        Show = function(self)
            self.shown = true
            return self
        end,
        
        Hide = function(self)
            self.shown = false
            return self
        end,
        
        IsShown = function(self)
            return self.shown
        end,
        
        IsVisible = function(self)
            if not self.shown then return false end
            local parent = self:GetParent()
            if parent then
                return parent:IsVisible()
            end
            return true
        end,
        
        SetFrameLevel = function(self, level)
            self.level = level
            return self
        end,
        
        GetFrameLevel = function(self)
            return self.level
        end,
        
        SetFrameStrata = function(self, strata)
            if FRAME_STRATA_LEVELS[strata] then
                self.strata = strata
            end
            return self
        end,
        
        GetFrameStrata = function(self)
            return self.strata
        end,
        
        GetFrameStrataLevel = function(self)
            return FRAME_STRATA_LEVELS[self.strata] or FRAME_STRATA_LEVELS.MEDIUM
        end,
        
        SetScript = function(self, event, handler)
            self.scripts[event] = handler
            return self
        end,
        
        GetScript = function(self, event)
            return self.scripts[event]
        end,
        
        RegisterEvent = function(self, event)
            self.events[event] = true
            return self
        end,
        
        UnregisterEvent = function(self, event)
            self.events[event] = nil
            return self
        end,
        
        FireEvent = function(self, event, ...)
            if self.events[event] and self.scripts["OnEvent"] then
                self.scripts["OnEvent"](self, event, ...)
            end
            return self
        end,
        
        SetAlpha = function(self, alpha)
            self.alpha = alpha
            return self
        end,
        
        GetAlpha = function(self)
            return self.alpha
        end,
        
        SetScale = function(self, scale)
            self.scale = scale
            return self
        end,
        
        GetScale = function(self)
            return self.scale
        end,
        
        EnableMouse = function(self, enable)
            self.mouseEnabled = enable
            return self
        end,
        
        IsMouseEnabled = function(self)
            return self.mouseEnabled
        end,
        
        SetClampedToScreen = function(self, clamped)
            self.clampedToScreen = clamped
            return self
        end,
        
        GetName = function(self)
            return self.name
        end,
        
        SetBackdrop = function(self, backdrop)
            self.backdrop = backdrop
            return self
        end,
        
        SetBackdropColor = function(self, r, g, b, a)
            self.backdropColor = {r, g, b, a}
            return self
        end,
        
        SetOwner = function(self, owner, anchor)
            self.owner = owner
            self.anchor = anchor
            return self
        end,
        
        GetOwner = function(self)
            return self.owner
        end
    }
    
    if parent then
        frame:SetParent(parent)
    end
    
    if name then
        frame.name = name
        _G[name] = frame
    end
    
    -- Special handling for GameTooltip
    if name == "GameTooltip" then
        frame.strata = "TOOLTIP"
    end
    
    return frame
end

-- Basic WoW API mocks
mockEnv.GetInventoryItemID = function(unit, slot)
    return mockEnv.inventory[slot]
end

mockEnv.GetInventoryItemCooldown = function(unit, slot)
    local itemID = mockEnv.inventory[slot]
    if not itemID then return 0, 0, 0 end
    local cooldown = mockEnv.cooldowns[itemID]
    if not cooldown then return 0, 0, 0 end
    return unpack(cooldown)
end

mockEnv.GetTime = function()
    return mockEnv.time
end

mockEnv.GetCooldownIcon = function(itemID)
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- Spell-related mock functions
mockEnv.UnitClass = function(unit)
    return "Unknown", mockEnv.spells.playerClass
end

mockEnv.GetNumSpellTabs = function()
    return #mockEnv.spells.tabs
end

mockEnv.GetSpellTabInfo = function(tabIndex)
    local tab = mockEnv.spells.tabs[tabIndex]
    if not tab then return nil end
    return tab.name, tab.texture, tab.offset, tab.numSpells
end

mockEnv.GetSpellBookItemInfo = function(spellIndex, bookType)
    local spell = mockEnv.spells.known[spellIndex]
    if not spell then return nil end
    return spell.type, spell.id
end

mockEnv.GetSpellBookItemName = function(spellIndex, bookType)
    local spell = mockEnv.spells.known[spellIndex]
    if not spell then return nil end
    return spell.name
end

mockEnv.GetSpellBaseCooldown = function(spellID)
    return mockEnv.spells.cooldowns[spellID]
end

mockEnv.IsSpellKnown = function(spellID)
    for _, spell in pairs(mockEnv.spells.known) do
        if spell.id == spellID then return true end
    end
    return false
end

mockEnv.GetSpellInfo = function(spellID)
    for _, spell in pairs(mockEnv.spells.known) do
        if spell.id == spellID then return spell.name end
    end
    return nil
end

-- Timer mock
_G.C_Timer = {
    After = function(delay, callback)
        callback()
    end
}

-- Add CreateFrame to mockEnv
mockEnv.CreateFrame = CreateFrame

-- Create UIParent
_G.UIParent = CreateFrame("Frame", "UIParent")

return mockEnv 