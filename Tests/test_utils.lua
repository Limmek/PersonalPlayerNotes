--[[
    Minimal, dependency-free Lua test for the pure-logic helpers in
    PersonalPlayerNotesUtils.lua (legacy Shitlist key parsing and client
    feature detection). No WoW client or Ace3 libraries are required.

    Run with: lua5.1 Tests/test_utils.lua
]]

-- Minimal stubs so PersonalPlayerNotesUtils.lua can be loaded outside of WoW.
_G.LibStub = function(major)
    if major == "AceLocale-3.0" then
        return {
            GetLocale = function()
                return setmetatable({}, {
                    __index = function()
                        return ""
                    end,
                })
            end,
        }
    end
    return setmetatable({}, {
        __index = function()
            return function() end
        end,
    })
end

_G.PersonalPlayerNotes = {}

local chunk = assert(loadfile("PersonalPlayerNotesUtils.lua"))
chunk("PersonalPlayerNotes")

local PersonalPlayerNotes = _G.PersonalPlayerNotes

local failures = 0

local function check(description, actual, expected)
    if actual ~= expected then
        failures = failures + 1
        print(string.format("FAIL: %s (expected %s, got %s)", description, tostring(expected), tostring(actual)))
    else
        print(string.format("PASS: %s", description))
    end
end

-- ParseLegacyPlayerKey
do
    local name, realm = PersonalPlayerNotes:ParseLegacyPlayerKey("Thrall-Frostmourne")
    check("parses a simple Name-Realm key (name)", name, "Thrall")
    check("parses a simple Name-Realm key (realm)", realm, "Frostmourne")
end

do
    local name, realm = PersonalPlayerNotes:ParseLegacyPlayerKey("NoHyphenKey")
    check("returns nil for a key without a hyphen (name)", name, nil)
    check("returns nil for a key without a hyphen (realm)", realm, nil)
end

do
    local name, realm = PersonalPlayerNotes:ParseLegacyPlayerKey(nil)
    check("returns nil for a non-string key (name)", name, nil)
    check("returns nil for a non-string key (realm)", realm, nil)
end

do
    -- Realm names can contain spaces (e.g. "Emerald Dream"); the pattern
    -- only splits on the hyphen, so spaces pass through untouched.
    local name, realm = PersonalPlayerNotes:ParseLegacyPlayerKey("Thrall-Emerald Dream")
    check("parses a Name-Realm key with a spaced realm (name)", name, "Thrall")
    check("parses a Name-Realm key with a spaced realm (realm)", realm, "Emerald Dream")
end

do
    -- The match pattern "([^-]+)-([^-]+)" only captures the first two
    -- hyphen-delimited segments, so a key with more than one hyphen is
    -- truncated rather than erroring or capturing everything after the
    -- first hyphen. This documents that actual (surprising) behavior.
    local name, realm = PersonalPlayerNotes:ParseLegacyPlayerKey("A-B-C")
    check("a multi-hyphen key only captures the first segment as name", name, "A")
    check("a multi-hyphen key only captures the second segment as realm", realm, "B")
end

-- Feature detection: must not error and must default to false when the
-- corresponding WoW globals don't exist.
check("HasModernMenuAPI is false without a Menu global", PersonalPlayerNotes:HasModernMenuAPI(), false)
check(
    "HasModernTooltipAPI is false without TooltipDataProcessor/Enum",
    PersonalPlayerNotes:HasModernTooltipAPI(),
    false
)
check("HasModernSettingsAPI is false without a Settings global", PersonalPlayerNotes:HasModernSettingsAPI(), false)
check("HasModernAddOnAPI is false without a C_AddOns global", PersonalPlayerNotes:HasModernAddOnAPI(), false)
check("HasModernUIReloadAPI is false without a C_UI global", PersonalPlayerNotes:HasModernUIReloadAPI(), false)

_G.Menu = { ModifyMenu = function() end }
check("HasModernMenuAPI is true once Menu.ModifyMenu exists", PersonalPlayerNotes:HasModernMenuAPI(), true)
_G.Menu = nil

-- Some Classic clients pick up part of the modern API surface before the
-- rest (e.g. the Menu table exists but ModifyMenu isn't implemented yet),
-- so each Has*API() check must require the full surface, not just the
-- presence of the parent table.
_G.Menu = {}
check(
    "HasModernMenuAPI is false when Menu exists but ModifyMenu doesn't",
    PersonalPlayerNotes:HasModernMenuAPI(),
    false
)
_G.Menu = nil

_G.TooltipDataProcessor = { AddTooltipPostCall = function() end }
_G.Enum = { TooltipDataType = { Unit = 1 } }
check(
    "HasModernTooltipAPI is true once TooltipDataProcessor/Enum exist",
    PersonalPlayerNotes:HasModernTooltipAPI(),
    true
)
_G.TooltipDataProcessor = nil
_G.Enum = nil

_G.TooltipDataProcessor = { AddTooltipPostCall = function() end }
_G.Enum = {}
check(
    "HasModernTooltipAPI is false when Enum exists but TooltipDataType doesn't",
    PersonalPlayerNotes:HasModernTooltipAPI(),
    false
)
_G.TooltipDataProcessor = nil
_G.Enum = nil

_G.Settings = { OpenToCategory = function() end }
check(
    "HasModernSettingsAPI is true once Settings.OpenToCategory exists",
    PersonalPlayerNotes:HasModernSettingsAPI(),
    true
)
_G.Settings = nil

_G.C_AddOns = { LoadAddOn = function() end, DisableAddOn = function() end }
check(
    "HasModernAddOnAPI is true once C_AddOns.LoadAddOn/DisableAddOn exist",
    PersonalPlayerNotes:HasModernAddOnAPI(),
    true
)
_G.C_AddOns = nil

_G.C_AddOns = { LoadAddOn = function() end }
check(
    "HasModernAddOnAPI is false when only C_AddOns.LoadAddOn exists (missing DisableAddOn)",
    PersonalPlayerNotes:HasModernAddOnAPI(),
    false
)
_G.C_AddOns = nil

_G.C_UI = { Reload = function() end }
check("HasModernUIReloadAPI is true once C_UI.Reload exists", PersonalPlayerNotes:HasModernUIReloadAPI(), true)
_G.C_UI = nil

-- IsSecretUnit
check("IsSecretUnit is false without an issecretvalue global", PersonalPlayerNotes:IsSecretUnit("player"), false)

_G.issecretvalue = function()
    return true
end
check(
    "IsSecretUnit is true once issecretvalue exists and reports true",
    PersonalPlayerNotes:IsSecretUnit("player"),
    true
)

_G.issecretvalue = function()
    return false
end
check(
    "IsSecretUnit is false once issecretvalue exists but reports false",
    PersonalPlayerNotes:IsSecretUnit("player"),
    false
)
_G.issecretvalue = nil

-- Metadata getters: thin wrappers around C_AddOns.GetAddOnMetadata(), each
-- falling back to L["PPN_NA"] ("" with this file's locale stub) when the
-- requested field is missing.
do
    _G.C_AddOns = {
        GetAddOnMetadata = function(_, field)
            local fixture = {
                Title = "Personal Player Notes",
                Author = "Some Author",
                Notes = "Some notes",
                ["X-Localizations"] = "enUS, zhCN",
                ["X-Category"] = "Combat",
                ["X-Website"] = "https://example.invalid",
                ["X-License"] = "MIT",
            }
            return fixture[field]
        end,
    }

    check("GetTitle reads the Title metadata field", PersonalPlayerNotes:GetTitle(), "Personal Player Notes")
    check("GetAuthor reads the Author metadata field", PersonalPlayerNotes:GetAuthor(), "Some Author")
    check("GetNotes reads the Notes metadata field", PersonalPlayerNotes:GetNotes(), "Some notes")
    check(
        "GetLocalizations reads the X-Localizations metadata field",
        PersonalPlayerNotes:GetLocalizations(),
        "enUS, zhCN"
    )
    check("GetCategory reads the X-Category metadata field", PersonalPlayerNotes:GetCategory(), "Combat")
    check("GetWebsite reads the X-Website metadata field", PersonalPlayerNotes:GetWebsite(), "https://example.invalid")
    check("GetLicense reads the X-License metadata field", PersonalPlayerNotes:GetLicense(), "MIT")

    -- GetVersion wraps the result in tostring(), so even a missing/nil
    -- metadata field becomes the *string* "nil" rather than falling back to
    -- L["PPN_NA"] - the `or` fallback in GetVersion() is effectively dead
    -- code. This test documents that actual (if surprising) behavior.
    check("GetVersion tostring()-wraps a present Version field", PersonalPlayerNotes:GetVersion(), "nil")

    _G.C_AddOns.GetAddOnMetadata = function(_, field)
        if field == "Version" then
            return "1.2.3"
        end
        return nil
    end
    check("GetVersion reads a present Version metadata field", PersonalPlayerNotes:GetVersion(), "1.2.3")
    check('GetTitle falls back to L["PPN_NA"] when the field is missing', PersonalPlayerNotes:GetTitle(), "")

    _G.C_AddOns = nil
end

-- MigrateSavedVariablesSchema
do
    PersonalPlayerNotes.db = {
        profile = {
            schemaVersion = nil,
            alert = { sound = 1, sounds = { "alarmbeep", "alarmbuzz", "alarmbuzzer", "alarmdouble" }, last = {} },
        },
    }
    PersonalPlayerNotes:MigrateSavedVariablesSchema()
    check(
        "MigrateSavedVariablesSchema stamps a fresh profile with SCHEMA_VERSION",
        PersonalPlayerNotes.db.profile.schemaVersion,
        PersonalPlayerNotes.SCHEMA_VERSION
    )
    check(
        "MigrateSavedVariablesSchema resets the old numeric alert.sound to the new default filename",
        PersonalPlayerNotes.db.profile.alert.sound,
        "default.mp3"
    )
    check(
        "MigrateSavedVariablesSchema drops the now-unused alert.sounds array",
        PersonalPlayerNotes.db.profile.alert.sounds,
        nil
    )
    check(
        "MigrateSavedVariablesSchema fills in an empty alert.customSounds list",
        #PersonalPlayerNotes.db.profile.alert.customSounds,
        0
    )
    check(
        "MigrateSavedVariablesSchema fills in a blank alert.newCustomSound",
        PersonalPlayerNotes.db.profile.alert.newCustomSound,
        ""
    )

    PersonalPlayerNotes.db = {
        profile = { schemaVersion = PersonalPlayerNotes.SCHEMA_VERSION, alert = { sound = "default.mp3" } },
    }
    PersonalPlayerNotes:MigrateSavedVariablesSchema()
    check(
        "MigrateSavedVariablesSchema leaves an already-current profile at SCHEMA_VERSION",
        PersonalPlayerNotes.db.profile.schemaVersion,
        PersonalPlayerNotes.SCHEMA_VERSION
    )
    check(
        "MigrateSavedVariablesSchema does not touch an already-migrated alert.sound",
        PersonalPlayerNotes.db.profile.alert.sound,
        "default.mp3"
    )
end

-- OpenBlizzardOptions
do
    local capturedCategoryID
    _G.Settings = {
        OpenToCategory = function(categoryID)
            capturedCategoryID = categoryID
        end,
    }
    PersonalPlayerNotes.blizOptionsCategoryID = 42
    PersonalPlayerNotes:OpenBlizzardOptions()
    check(
        "OpenBlizzardOptions uses Settings.OpenToCategory when the modern Settings API is available",
        capturedCategoryID,
        42
    )
    _G.Settings = nil
end

do
    -- Reload the module with a spy standing in for AceConfigDialog-3.0, so
    -- OpenBlizzardOptions()'s fallback branch (used on clients without the
    -- modern Settings API, or before blizOptionsCategoryID is known) can be
    -- verified to actually call AceConfigDialog:Open(...).
    local openedKey
    _G.LibStub = function(major)
        if major == "AceLocale-3.0" then
            return {
                GetLocale = function()
                    return setmetatable({}, {
                        __index = function()
                            return ""
                        end,
                    })
                end,
            }
        end
        if major == "AceConfigDialog-3.0" then
            return {
                Open = function(_, key)
                    openedKey = key
                end,
            }
        end
        return setmetatable({}, {
            __index = function()
                return function() end
            end,
        })
    end

    local reloadChunk = assert(loadfile("PersonalPlayerNotesUtils.lua"))
    reloadChunk("PersonalPlayerNotes")

    PersonalPlayerNotes.blizOptionsCategoryID = nil
    PersonalPlayerNotes:OpenBlizzardOptions()
    check(
        "OpenBlizzardOptions falls back to AceConfigDialog:Open without a bliz options category",
        openedKey,
        "PersonalPlayerNotesSettings Info"
    )
end

-- Print / PrintDebug
do
    local realPrint = print

    local function captureArgs(fn)
        local captured
        _G.print = function(...)
            captured = { n = select("#", ...), ... }
        end
        fn()
        _G.print = realPrint
        return captured
    end

    PersonalPlayerNotes.db = nil
    local args = captureArgs(function()
        PersonalPlayerNotes:Print("hello", "world")
    end)
    check("Print works without a db (self.db is nil)", args ~= nil, true)
    check("Print forwards call args without a db", args[3], "world")

    PersonalPlayerNotes.db = { profile = { debug = false } }
    args = captureArgs(function()
        PersonalPlayerNotes:Print("normal")
    end)
    check("Print forwards call args when debug is off", args[2], "normal")

    PersonalPlayerNotes.db.profile.debug = true
    args = captureArgs(function()
        PersonalPlayerNotes:Print("debug-mode")
    end)
    check("Print forwards call args when debug is on", args[2], "debug-mode")

    PersonalPlayerNotes.db.profile.debug = false
    args = captureArgs(function()
        PersonalPlayerNotes:PrintDebug("should not print")
    end)
    check("PrintDebug is a no-op when debug is off", args, nil)

    PersonalPlayerNotes.db.profile.debug = true
    args = captureArgs(function()
        PersonalPlayerNotes:PrintDebug("should print")
    end)
    check("PrintDebug forwards to Print when debug is on", args[2], "should print")

    PersonalPlayerNotes.db = nil
end

if failures > 0 then
    print(string.format("\n%d test(s) failed.", failures))
    os.exit(1)
end

print("\nAll tests passed.")
