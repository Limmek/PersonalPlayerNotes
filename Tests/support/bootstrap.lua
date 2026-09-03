--[[
    Shared stub/bootstrap helper for loading the addon's own Lua files
    outside of a WoW client, mirroring the real load order declared in
    PersonalPlayerNotes.toc: PersonalPlayerNotes.lua, then
    SoundsManifest.lua, then PersonalPlayerNotesUtils.lua, then
    PersonalPlayerNotesConfig.lua.

    Used by the test files in Tests/ so each one doesn't need to duplicate
    the same WoW/Ace3 stub setup. Only pure, isolable logic is exercised
    this way - see .github/AGENTS.md's testing guidance for why WoW-API-heavy
    code (menu/tooltip rendering, AceGUI widgets, etc.) is deliberately left
    untested here.

    Not a test file itself - loaded with dofile("Tests/support/bootstrap.lua")
    by the actual test files, which must be run from the repo root (matching
    every other Tests/*.lua file and the Makefile/CI commands).
]]

local M = {}

--[[
    A minimal LibStub stub:
      - "AceLocale-3.0" returns a locale table whose __index returns the key
        itself, so assertions can rely on stable, predictable strings
        instead of real (or missing) locale text.
      - "AceAddon-3.0" returns an object whose NewAddon() creates a fresh
        plain table, standing in for the real Ace3 addon object.
      - Anything else (AceConfig-3.0, AceConfigDialog-3.0, LibDataBroker-1.1,
        LibDBIcon-1.0, AceDBOptions-3.0, ...) returns a table whose __index
        returns a no-op function, so unrelated `Lib:Method(...)` calls at
        module load time or inside untested code paths don't error.
]]
function M.defaultLibStub()
    return function(major)
        if major == "AceLocale-3.0" then
            return {
                GetLocale = function()
                    return setmetatable({}, {
                        __index = function(_, key)
                            return key
                        end,
                    })
                end,
            }
        end
        if major == "AceAddon-3.0" then
            return {
                NewAddon = function(_, ...)
                    return {}
                end,
            }
        end
        return setmetatable({}, {
            __index = function()
                return function() end
            end,
        })
    end
end

--[[
    Loads PersonalPlayerNotes.lua, PersonalPlayerNotesUtils.lua and
    PersonalPlayerNotesConfig.lua (in that order) into a fresh
    _G.PersonalPlayerNotes, stubbing just enough of the WoW/Ace3 global
    surface for their module-level code to run without error, and returns
    the resulting PersonalPlayerNotes table.

    `libStubOverride`, if given, replaces the default LibStub stub (e.g. to
    intercept a specific library with a recording spy for one test).
]]
function M.loadAddon(libStubOverride)
    _G.LibStub = libStubOverride or M.defaultLibStub()
    -- PersonalPlayerNotesConfig.lua calls PersonalPlayerNotes:GetNotes()/
    -- :GetAuthor()/etc. (which read C_AddOns.GetAddOnMetadata) at module
    -- load time to build its options table, so this must exist before it's
    -- loaded even if a given test doesn't care about addon metadata.
    _G.C_AddOns = _G.C_AddOns or {
        GetAddOnMetadata = function()
            return ""
        end,
    }
    -- tinsert/tremove are WoW-injected aliases for table.insert/table.remove,
    -- not real Lua 5.1 globals, but PersonalPlayerNotesConfig.lua calls them
    -- as bare globals (e.g. in SetReason/RemoveReason/NewListedPlayer).
    _G.tinsert = _G.tinsert or table.insert
    _G.tremove = _G.tremove or table.remove
    _G.PersonalPlayerNotes = nil

    local main = assert(loadfile("PersonalPlayerNotes.lua"))
    main("PersonalPlayerNotes")

    local soundManifest = assert(loadfile("SoundsManifest.lua"))
    soundManifest("PersonalPlayerNotes")

    local utils = assert(loadfile("PersonalPlayerNotesUtils.lua"))
    utils("PersonalPlayerNotes")

    local config = assert(loadfile("PersonalPlayerNotesConfig.lua"))
    config("PersonalPlayerNotes")

    return _G.PersonalPlayerNotes
end

--[[
    Returns a deep copy of PersonalPlayerNotes.defaults.profile, suitable for
    assigning to `addon.db = { profile = ..., profiles = {} }` in tests that
    need a realistic starting SavedVariables profile without pulling in the
    real AceDB-3.0 library.
]]
function M.freshProfile(addon)
    local function deepCopy(value)
        if type(value) ~= "table" then
            return value
        end
        local copy = {}
        for k, v in pairs(value) do
            copy[k] = deepCopy(v)
        end
        return copy
    end

    return deepCopy(addon.defaults.profile)
end

return M
