--[[
Lorem Cooldown Tracker Test Runner
================================
Main entry point for running all tests
--]]

-- Load mock functions first
local mockEnv = require("tests.mock_functions")

-- Set up global mock functions
for name, func in pairs(mockEnv) do
    if type(func) == "function" then
        _G[name] = func
    end
end

-- Now load LCT mock environment
_G.LCT = require("tests.mock_lct")

-- Load mock spells module
LCT.spells = require("tests.mock_spells")

-- Test framework
local TestFramework = {
    totalTests = 0,
    passedTests = 0,
    currentSuite = nil,
    results = {},
    mockState = mockEnv
}

-- Framework functions
function TestFramework:StartSuite(name)
    self.currentSuite = name
    self.results[name] = {
        passed = 0,
        total = 0,
        failures = {}
    }
    print(string.format("=== Starting Test Suite: %s ===", name))
    
    -- Reset mock state before each suite
    self.mockState.time = 0
    self.mockState.inventory = {}
    self.mockState.cooldowns = {}
    self.mockState.frames = {}
    self.mockState.events = {}
    
    -- Reset LCT state
    if LCT then
        LCT.cooldowns.trackedItems = {}
        LCT.cooldowns.trackedSpells = {}
        LCT.cooldowns.activeCooldowns = {}
        LCT.animations = {
            CancelAnimation = function() end,
            StartFinishAnimation = function() end,
            StartPositionAnimation = function() end
        }
    end
end

function TestFramework:Assert(condition, testName, details)
    self.totalTests = self.totalTests + 1
    self.results[self.currentSuite].total = self.results[self.currentSuite].total + 1
    
    if condition then
        self.passedTests = self.passedTests + 1
        self.results[self.currentSuite].passed = self.results[self.currentSuite].passed + 1
        print(string.format("✓ %s", testName))
    else
        table.insert(self.results[self.currentSuite].failures, {
            name = testName,
            details = details
        })
        print(string.format("✗ %s", testName))
        print(string.format("  Details: %s", details))
    end
end

function TestFramework:EndSuite()
    local suiteResults = self.results[self.currentSuite]
    print(string.format("=== Suite Complete: %d/%d tests passed ===\n",
        suiteResults.passed, suiteResults.total))
end

function TestFramework:Summarize()
    print("\n=== Test Summary ===")
    for suiteName, results in pairs(self.results) do
        print(string.format("%s: %d/%d passed", 
            suiteName, results.passed, results.total))
        if #results.failures > 0 then
            print("Failures:")
            for _, failure in ipairs(results.failures) do
                print(string.format("  - %s\n    %s",
                    failure.name, failure.details))
            end
        end
    end
    print(string.format("\nTotal: %d/%d tests passed",
        self.passedTests, self.totalTests))
end

-- Load and run test suites
local function loadTestSuite(name)
    local success, suite = pcall(require, "tests.suites." .. name)
    if not success then
        print(string.format("Failed to load test suite '%s': %s", name, suite))
        return nil
    end
    return suite
end

local function runTestSuite(suite)
    if not suite or not suite.name or not suite.run then
        print("Invalid test suite format")
        return false
    end
    
    TestFramework:StartSuite(suite.name)
    local success, result = pcall(suite.run, TestFramework)
    if not success then
        print(string.format("Suite failed with error: %s", result))
        return false
    end
    TestFramework:EndSuite()
    return result
end

local function runAllTests()
    local suites = {
        "time_format",
        "position_calculation",
        "trinket_tracking",
        "ui_interference",
        "pvp_trinket",
        "compatibility",
        "spell_tracking",
        "animation"
    }
    
    for _, name in ipairs(suites) do
        local suite = loadTestSuite(name)
        if suite then
            runTestSuite(suite)
        end
    end
    
    TestFramework:Summarize()
end

-- Run all tests
runAllTests()

return {
    framework = TestFramework,
    runAllTests = runAllTests
} 