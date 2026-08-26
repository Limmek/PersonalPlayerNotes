--[[
    Unit tests for PersonalPlayerNotes:GetOldConfigData(), the legacy
    Shitlist -> Personal Player Notes data migration logic in
    PersonalPlayerNotes.lua. This is the one piece of non-trivial pure(ish)
    business logic in that file - the rest (menu/tooltip hooks, AceGUI
    widgets, minimap icon) is too tightly coupled to the real WoW client to
    usefully unit test, see .github/AGENTS.md.

    Run with: lua5.1 Tests/test_main.lua
]]

local bootstrap = dofile("Tests/support/bootstrap.lua")

local failures = 0

local function check(description, actual, expected)
    if actual ~= expected then
        failures = failures + 1
        print(string.format("FAIL: %s (expected %s, got %s)", description, tostring(expected), tostring(actual)))
    else
        print(string.format("PASS: %s", description))
    end
end

local PersonalPlayerNotes = bootstrap.loadAddon()

local function freshDb()
    return { profile = bootstrap.freshProfile(PersonalPlayerNotes), profiles = {} }
end

local function resetGlobals()
    _G.ShitlistDB = nil
    _G.StaticPopupDialogs = {}
    _G.StaticPopup_Show = function() end
end

-- No Shitlist data installed at all: must not error, must not touch the db.
do
    PersonalPlayerNotes.db = freshDb()
    resetGlobals()
    local reasonsBefore = #PersonalPlayerNotes:GetReasons()
    local playersBefore = #PersonalPlayerNotes:GetListedPlayers()

    PersonalPlayerNotes:GetOldConfigData()

    check("GetOldConfigData is a no-op without a ShitlistDB global", #PersonalPlayerNotes:GetReasons(), reasonsBefore)
    check(
        "GetOldConfigData leaves listedPlayers untouched without ShitlistDB",
        #PersonalPlayerNotes:GetListedPlayers(),
        playersBefore
    )
end

-- ShitlistDB exists but has neither pre-2.0 Reasons/ListedPlayers nor
-- profiles to migrate: must still be a no-op.
do
    PersonalPlayerNotes.db = freshDb()
    resetGlobals()
    _G.ShitlistDB = {}
    local reasonsBefore = #PersonalPlayerNotes:GetReasons()

    PersonalPlayerNotes:GetOldConfigData()

    check("GetOldConfigData is a no-op for an empty ShitlistDB", #PersonalPlayerNotes:GetReasons(), reasonsBefore)
end

-- Pre-2.0 legacy data: a new reason and a new listed player should both be
-- migrated in, and the legacy tables cleared afterwards.
do
    PersonalPlayerNotes.db = freshDb()
    PersonalPlayerNotes:SetReasons({ { id = 1, reason = "AFK", color = { r = 1, g = 1, b = 1 }, alert = false } })
    PersonalPlayerNotes.db.profile.listedPlayers = {}
    resetGlobals()
    _G.ShitlistDB = {
        Reasons = { "unused, only presence is checked" },
        ListedPlayers = {
            ["Thrall-Frostmourne"] = { "Ninja looter", "Stole the raid loot" },
        },
    }

    PersonalPlayerNotes:GetOldConfigData()

    check("GetOldConfigData migrates a new legacy reason", #PersonalPlayerNotes:GetReasons(), 2)
    check("GetOldConfigData migrates a new legacy listed player", #PersonalPlayerNotes:GetListedPlayers(), 1)

    local migrated = PersonalPlayerNotes:GetListedPlayer("Thrall", "Frostmourne")
    check("GetOldConfigData migrates the legacy player's name/realm", migrated ~= nil, true)
    check("GetOldConfigData migrates the legacy player's description", migrated.description, "Stole the raid loot")
    check(
        "GetOldConfigData assigns the newly created reason's id",
        migrated.reason,
        PersonalPlayerNotes:GetReasons()[2].id
    )
    check(
        "GetOldConfigData's migrated reason keeps the legacy reason text",
        PersonalPlayerNotes:GetReasons()[2].reason,
        "Ninja looter"
    )
    check("GetOldConfigData clears the legacy ListedPlayers table", ShitlistDB.ListedPlayers, nil)
    check("GetOldConfigData clears the legacy Reasons table", ShitlistDB.Reasons, nil)
end

-- Pre-2.0 legacy data that reuses an existing reason's text: no duplicate
-- reason should be created, the existing reason id should be reused.
do
    PersonalPlayerNotes.db = freshDb()
    PersonalPlayerNotes:SetReasons({ { id = 1, reason = "AFK", color = { r = 1, g = 1, b = 1 }, alert = false } })
    PersonalPlayerNotes.db.profile.listedPlayers = {}
    resetGlobals()
    _G.ShitlistDB = {
        Reasons = { "unused" },
        ListedPlayers = {
            ["Jaina-Theramore"] = { "AFK", "" },
        },
    }

    PersonalPlayerNotes:GetOldConfigData()

    check("GetOldConfigData does not duplicate an existing reason", #PersonalPlayerNotes:GetReasons(), 1)
    local migrated = PersonalPlayerNotes:GetListedPlayer("Jaina", "Theramore")
    check("GetOldConfigData reuses the existing reason's id", migrated.reason, 1)
end

-- Pre-2.0 legacy data for a player that's already listed: should be skipped
-- (not duplicated).
do
    PersonalPlayerNotes.db = freshDb()
    PersonalPlayerNotes:SetReasons({ { id = 1, reason = "AFK", color = { r = 1, g = 1, b = 1 }, alert = false } })
    PersonalPlayerNotes.db.profile.listedPlayers = {
        {
            id = 1,
            name = "Thrall",
            realm = "Frostmourne",
            reason = 1,
            description = "",
            color = { r = 1, g = 1, b = 1 },
            alert = true,
        },
    }
    resetGlobals()
    _G.ShitlistDB = {
        Reasons = { "unused" },
        ListedPlayers = {
            ["Thrall-Frostmourne"] = { "AFK", "Already listed" },
        },
    }

    PersonalPlayerNotes:GetOldConfigData()

    check("GetOldConfigData skips a legacy player that's already listed", #PersonalPlayerNotes:GetListedPlayers(), 1)
end

-- ShitlistDB.profiles present: should prompt a migration popup, without
-- actually running its OnAccept side effects (disabling Shitlist, reloading
-- the UI, etc. - those aren't invoked unless a real user confirms the popup).
do
    PersonalPlayerNotes.db = freshDb()
    resetGlobals()
    local shownKey
    _G.StaticPopup_Show = function(key)
        shownKey = key
    end
    _G.ShitlistDB = {
        profiles = { Default = { reasons = {}, listedPlayers = {} } },
    }

    PersonalPlayerNotes:GetOldConfigData()

    check(
        "GetOldConfigData registers a MIGRATE_PROFILES popup when ShitlistDB.profiles exists",
        type(StaticPopupDialogs["MIGRATE_PROFILES"]),
        "table"
    )
    check("GetOldConfigData shows the MIGRATE_PROFILES popup", shownKey, "MIGRATE_PROFILES")
end

if failures > 0 then
    print(string.format("\n%d test(s) failed.", failures))
    os.exit(1)
end

print("\nAll tests passed.")
