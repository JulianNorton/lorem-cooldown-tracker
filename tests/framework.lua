--[[
Test Framework for Lorem Cooldown Tracker
=======================================
Core test framework functionality
--]]

local TestFramework = {}
TestFramework.__index = TestFramework

-- Constants
local CONSTANTS = {
    MAX_TIME = 300,  -- 5 minutes in seconds
    UPDATE_FREQUENCY = 0.1,
    ANIMATION_DURATION = 0.15,
    FINISH_ANIMATION_DURATION = 0.2,
    FINAL_SECONDS_SCALE = 2.0,
    FINAL_SECONDS_THRESHOLD = 10
}

function TestFramework.new()
    local self = setmetatable({
        totalPassed = 0,
        totalTests = 0,
        currentSuite = "",
        suites = {},
        results = {},
        startTime = 0,
        beforeEach = nil,
        afterEach = nil,
        beforeAll = nil,
        afterAll = nil,
        mockState = {
            inventory = {},
            cooldowns = {},
            time = 0,
            frames = {},
            events = {},
            handlers = {}
        }
    }, TestFramework)
    
    self:initializeAPI()
    return self
end

function TestFramework:initializeAPI()
    -- Set up _G if it doesn't exist
    if not _G then _G = {} end
    
    -- Store original functions if they exist
    self.originalFunctions = {
        CreateFrame = _G.CreateFrame,
        GetTime = _G.GetTime,
        GetSpellInfo = _G.GetSpellInfo,
        GetInventoryItemTexture = _G.GetInventoryItemTexture,
        GetInventoryItemID = _G.GetInventoryItemID,
        GetItemIcon = _G.GetItemIcon,
        GetInventoryItemCooldown = _G.GetInventoryItemCooldown
    }
    
    -- Mock basic WoW API functions
    _G.GetTime = function() return self.mockState.time end
    _G.GetSpellInfo = function(spellID) return "Test Spell " .. spellID end
    _G.GetInventoryItemTexture = function() return "Interface\\Icons\\INV_Misc_QuestionMark" end
    _G.GetInventoryItemID = function(_, slot) return self.mockState.inventory[slot] end
    _G.GetItemIcon = function() return "Interface\\Icons\\INV_Misc_QuestionMark" end
    
    -- Mock C_Timer
    _G.C_Timer = {
        After = function(_, callback)
            if type(callback) == "function" then callback() end
        end
    }
    
    -- Mock cooldown functions
    _G.GetInventoryItemCooldown = function(_, slot)
        local itemID = self.mockState.inventory[slot]
        if itemID and self.mockState.cooldowns[itemID] then
            return unpack(self.mockState.cooldowns[itemID])
        end
        return 0, 0, 1
    end
end

function TestFramework:resetMockState()
    for k in pairs(self.mockState) do
        if type(self.mockState[k]) == "table" then
            self.mockState[k] = {}
        else
            self.mockState[k] = 0
        end
    end
end

function TestFramework:restoreAPI()
    for name, func in pairs(self.originalFunctions) do
        _G[name] = func
    end
end

function TestFramework:StartSuite(name)
    self.currentSuite = name
    self.suites[name] = {
        passed = 0,
        total = 0,
        startTime = GetTime(),
        errors = {}
    }
    print(string.format("\n=== Starting Test Suite: %s ===", name))
    
    if self.beforeAll then
        self:beforeAll()
    end
end

function TestFramework:EndSuite()
    if self.afterAll then
        self:afterAll()
    end
    
    local suite = self.suites[self.currentSuite]
    local duration = GetTime() - suite.startTime
    
    print(string.format("=== %s: %d/%d tests passed (%.2fs) ===", 
        self.currentSuite, suite.passed, suite.total, duration))
    
    if #suite.errors > 0 then
        print("\nErrors in this suite:")
        for _, err in ipairs(suite.errors) do
            print(string.format("  - %s", err))
        end
        print("")
    end
    
    self.currentSuite = ""
end

function TestFramework:Assert(condition, message, details)
    local suite = self.suites[self.currentSuite]
    suite.total = suite.total + 1
    self.totalTests = self.totalTests + 1
    
    if condition then
        suite.passed = suite.passed + 1
        self.totalPassed = self.totalPassed + 1
        print(string.format("✓ %s", message))
        return true
    else
        print(string.format("✗ %s", message))
        if details then
            print(string.format("  Details: %s", details))
            table.insert(suite.errors, string.format("%s - %s", message, details))
        else
            table.insert(suite.errors, message)
        end
        return false
    end
end

function TestFramework:RunTest(name, fn)
    print(string.format("\nRunning: %s", name))
    
    if self.beforeEach then
        self:beforeEach()
    end
    
    local success, result = pcall(fn)
    
    if self.afterEach then
        self:afterEach()
    end
    
    if not success then
        print(string.format("✗ Test failed with error: %s", result))
        local suite = self.suites[self.currentSuite]
        table.insert(suite.errors, string.format("%s - %s", name, result))
        return false
    end
    return result
end

function TestFramework:Summarize()
    print("\n=== Test Summary ===")
    local totalErrors = 0
    for name, suite in pairs(self.suites) do
        print(string.format("%s: %d/%d passed", name, suite.passed, suite.total))
        totalErrors = totalErrors + #suite.errors
    end
    print(string.format("\nTotal: %d/%d tests passed", self.totalPassed, self.totalTests))
    if totalErrors > 0 then
        print(string.format("\nTotal Errors: %d", totalErrors))
    end
    print("===================")
end

return TestFramework 