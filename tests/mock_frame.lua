--[[
Mock Frame System for Lorem Cooldown Tracker Tests
===============================================
Simulates WoW's frame system for testing
--]]

local MockFrame = {}
MockFrame.__index = MockFrame

function MockFrame.new(frameType, name, parent, template)
    local self = setmetatable({
        frameType = frameType,
        name = name,
        parent = nil,  -- Set through SetParent to ensure proper setup
        children = {},
        shown = true,
        hidden = false,
        points = {},
        size = { width = 32, height = 32 },
        level = 0,
        strata = "MEDIUM",
        events = {},
        scripts = {},
        handlers = {},
        textures = {},
        fontStrings = {},
        mouseEnabled = false,
        movable = false,
        resizable = false,
        clampedToScreen = false,
        scale = 1,
        alpha = 1,
        backdrop = nil,
        owner = nil,
        anchor = nil,
        id = 0
    }, MockFrame)
    
    if parent then
        self:SetParent(parent)
    end
    
    return self
end

-- Core frame methods
function MockFrame:SetParent(newParent)
    if self.parent and self.parent.children then
        for i, child in ipairs(self.parent.children) do
            if child == self then
                table.remove(self.parent.children, i)
                break
            end
        end
    end
    self.parent = newParent
    if newParent and newParent.children then
        table.insert(newParent.children, self)
    end
    return self
end

function MockFrame:GetParent()
    return self.parent
end

function MockFrame:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
    table.insert(self.points, {
        point = point,
        relativeTo = relativeTo,
        relativePoint = relativePoint,
        xOffset = xOffset,
        yOffset = yOffset
    })
    return self
end

function MockFrame:GetPoint(index)
    index = index or 1
    if self.points[index] then
        local p = self.points[index]
        return p.point, p.relativeTo, p.relativePoint, p.xOffset, p.yOffset
    end
    return nil
end

function MockFrame:ClearAllPoints()
    self.points = {}
    return self
end

function MockFrame:SetSize(width, height)
    self.size.width = width
    self.size.height = height
    return self
end

function MockFrame:GetWidth()
    return self.size.width
end

function MockFrame:GetHeight()
    return self.size.height
end

-- Visibility methods
function MockFrame:Show()
    self.shown = true
    self.hidden = false
    return self
end

function MockFrame:Hide()
    self.shown = false
    self.hidden = true
    return self
end

function MockFrame:IsShown()
    return self.shown
end

function MockFrame:IsVisible()
    if not self.shown then return false end
    if self.parent then return self.parent:IsVisible() end
    return true
end

-- Frame properties
function MockFrame:SetFrameStrata(strata)
    self.strata = strata
    return self
end

function MockFrame:GetFrameStrata()
    return self.strata
end

function MockFrame:SetFrameLevel(level)
    self.level = level
    return self
end

function MockFrame:GetFrameLevel()
    return self.level
end

-- Mouse interaction
function MockFrame:EnableMouse(enabled)
    self.mouseEnabled = enabled
    return self
end

function MockFrame:IsMouseEnabled()
    return self.mouseEnabled
end

function MockFrame:SetMovable(movable)
    self.movable = movable
    return self
end

function MockFrame:IsMovable()
    return self.movable
end

function MockFrame:SetResizable(resizable)
    self.resizable = resizable
    return self
end

function MockFrame:IsResizable()
    return self.resizable
end

-- Screen clamping
function MockFrame:SetClampedToScreen(clamped)
    self.clampedToScreen = clamped
    return self
end

-- Event handling
function MockFrame:SetScript(scriptType, handler)
    if type(handler) == "function" or handler == nil then
        self.handlers[scriptType] = handler
    end
    return self
end

function MockFrame:GetScript(scriptType)
    return self.handlers[scriptType]
end

function MockFrame:RegisterEvent(event)
    if not self.events[event] then
        self.events[event] = true
    end
    return self
end

function MockFrame:UnregisterEvent(event)
    self.events[event] = nil
    return self
end

function MockFrame:UnregisterAllEvents()
    self.events = {}
    return self
end

function MockFrame:FireEvent(event, ...)
    local handler = self.handlers["OnEvent"]
    if self.events[event] and type(handler) == "function" then
        handler(self, event, ...)
        return true
    end
    return false
end

-- Visual elements
function MockFrame:CreateTexture(name, layer)
    local texture = MockFrame.new("Texture", name, self)
    texture.SetTexture = function(self, ...) return self end
    texture.SetTexCoord = function(self, ...) return self end
    texture.SetAllPoints = function(self) return self end
    texture.SetColorTexture = function(self, ...) return self end
    table.insert(self.textures, texture)
    return texture
end

function MockFrame:CreateFontString(name, layer, template)
    local fontString = {
        text = "",
        SetText = function(self, text) self.text = text; return self end,
        GetText = function(self) return self.text end,
        SetPoint = function(self, ...) return self end
    }
    table.insert(self.fontStrings, fontString)
    return fontString
end

-- Backdrop handling
function MockFrame:SetBackdrop(backdrop)
    self.backdrop = backdrop
    return self
end

function MockFrame:GetBackdrop()
    return self.backdrop
end

function MockFrame:SetBackdropColor(r, g, b, a)
    if not self.backdrop then self.backdrop = {} end
    self.backdrop.color = {r = r, g = g, b = b, a = a}
    return self
end

function MockFrame:GetBackdropColor()
    if self.backdrop and self.backdrop.color then
        return self.backdrop.color.r, self.backdrop.color.g, 
               self.backdrop.color.b, self.backdrop.color.a
    end
    return 1, 1, 1, 1
end

-- Scale and alpha
function MockFrame:SetScale(scale)
    self.scale = scale
    return self
end

function MockFrame:GetScale()
    return self.scale
end

function MockFrame:SetAlpha(alpha)
    self.alpha = alpha
    return self
end

function MockFrame:GetAlpha()
    return self.alpha
end

-- Frame identification
function MockFrame:SetID(id)
    self.id = id
    return self
end

function MockFrame:GetID()
    return self.id
end

function MockFrame:GetName()
    return self.name
end

-- Tooltip functionality
function MockFrame:SetOwner(owner, anchor)
    self.owner = owner
    self.anchor = anchor
    return self
end

-- Child management
function MockFrame:GetChildren()
    return unpack(self.children)
end

return MockFrame 