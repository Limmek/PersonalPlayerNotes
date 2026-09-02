--[[
    Unit tests for the pure data-manipulation logic in
    PersonalPlayerNotesConfig.lua (AceDB defaults shape, reasons CRUD,
    listed players CRUD, alert getters/setters). No WoW client or Ace3
    libraries are required - see Tests/support/bootstrap.lua.

    Run with: lua5.1 Tests/test_config.lua
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

-- Give the addon a fresh, real-shaped profile without depending on AceDB-3.0.
local function freshDb()
    return { profile = bootstrap.freshProfile(PersonalPlayerNotes), profiles = {} }
end

--#region defaults shape

do
    PersonalPlayerNotes.db = freshDb()
    local profile = PersonalPlayerNotes.db.profile

    check("defaults.schemaVersion matches SCHEMA_VERSION", profile.schemaVersion, PersonalPlayerNotes.SCHEMA_VERSION)
    check("defaults.debug starts false", profile.debug, false)
    check("defaults.minimap.hide starts false", profile.minimap.hide, false)
    check("defaults.minimap.minimapPos starts at 240", profile.minimap.minimapPos, 240)
    check("defaults.alert.delay starts at 10", profile.alert.delay, 10)
    check("defaults.alert.enabled starts true", profile.alert.enabled, true)
    check("defaults.alert.sounds has 4 entries", #profile.alert.sounds, 4)
    check("defaults.reasons has exactly 1 entry", #profile.reasons, 1)
    check("defaults.reasons[1].id is 1", profile.reasons[1].id, 1)
    check("defaults.listedPlayers has exactly 1 entry", #profile.listedPlayers, 1)
    check("defaults.listedPlayer.id is 1", profile.listedPlayer.id, 1)
end

--#endregion

--#region Alert

do
    PersonalPlayerNotes.db = freshDb()

    -- SetAlertSoundEffect/PlayAlertSoundEffect call the global PlaySoundFile,
    -- so it must be stubbed before either is invoked.
    local playedPath, playedChannel
    _G.PlaySoundFile = function(path, channel)
        playedPath, playedChannel = path, channel
    end

    check("GetAlert reads the requested alert field", PersonalPlayerNotes:GetAlert({ "delay" }), 10)
    PersonalPlayerNotes:SetAlert({ "delay" }, 25)
    check("SetAlert writes the requested alert field", PersonalPlayerNotes:GetAlert({ "delay" }), 25)

    check("GetAlertSoundEffect reads the current sound index", PersonalPlayerNotes:GetAlertSoundEffect(), 1)

    PersonalPlayerNotes:PlayAlertSoundEffect()
    check(
        "PlayAlertSoundEffect plays the currently selected sound file",
        playedPath,
        "Interface\\AddOns\\PersonalPlayerNotes\\Sounds\\alarmbeep.ogg"
    )
    check("PlayAlertSoundEffect defaults to the master channel", playedChannel, "master")

    PersonalPlayerNotes:PlayAlertSoundEffect(2, "sfx")
    check(
        "PlayAlertSoundEffect accepts an explicit effect index",
        playedPath,
        "Interface\\AddOns\\PersonalPlayerNotes\\Sounds\\alarmbuzz.ogg"
    )
    check("PlayAlertSoundEffect accepts an explicit channel", playedChannel, "sfx")

    PersonalPlayerNotes:SetAlertSoundEffect({ "sound" }, 3)
    check("SetAlertSoundEffect writes the sound index", PersonalPlayerNotes.db.profile.alert.sound, 3)
    check(
        "SetAlertSoundEffect also plays the newly selected sound",
        playedPath,
        "Interface\\AddOns\\PersonalPlayerNotes\\Sounds\\alarmbuzzer.ogg"
    )

    _G.PlaySoundFile = nil
end

--#endregion

--#region Reasons

do
    PersonalPlayerNotes.db = freshDb()

    check(
        "GetReasons returns the profile's reasons table",
        PersonalPlayerNotes:GetReasons(),
        PersonalPlayerNotes.db.profile.reasons
    )

    local newReasons = { { id = 1, reason = "Custom", color = { r = 1, g = 1, b = 1 }, alert = true } }
    PersonalPlayerNotes:SetReasons(newReasons)
    check("SetReasons replaces the profile's reasons table", PersonalPlayerNotes.db.profile.reasons, newReasons)
end

do
    PersonalPlayerNotes.db = freshDb()
    local originalReasonText = PersonalPlayerNotes.db.profile.reason.reason

    check("GetReason reads the current reason field", PersonalPlayerNotes:GetReason({ "reason" }), originalReasonText)

    -- Re-submitting the same text is a no-op: no new reason is added.
    PersonalPlayerNotes:SetReason({ "reason" }, originalReasonText)
    check("SetReason with the same text does not add a new reason", #PersonalPlayerNotes:GetReasons(), 1)

    -- Submitting different text adds a *new* reason and selects it, leaving
    -- the original reason entry untouched (this is the actual behavior of
    -- SetReason: it never edits reasons[reason.id] in place).
    PersonalPlayerNotes:SetReason({ "reason" }, "Ninja looter")
    check("SetReason with new text adds a new reason", #PersonalPlayerNotes:GetReasons(), 2)
    check("SetReason selects the newly added reason", PersonalPlayerNotes.db.profile.reason.id, 2)
    check("SetReason's new reason has the submitted text", PersonalPlayerNotes.db.profile.reason.reason, "Ninja looter")
    check(
        "SetReason leaves the original reason entry untouched",
        PersonalPlayerNotes:GetReasons()[1].reason,
        originalReasonText
    )
end

do
    PersonalPlayerNotes.db = freshDb()
    PersonalPlayerNotes:SetReasons({
        { id = 1, reason = "First", color = { r = 1, g = 1, b = 1 }, alert = false },
        { id = 2, reason = "Second", color = { r = 0, g = 0, b = 0 }, alert = true },
    })

    PersonalPlayerNotes:SelectedReason({ "id" }, 2)
    check(
        "SelectedReason syncs reason.reason from the chosen entry",
        PersonalPlayerNotes.db.profile.reason.reason,
        "Second"
    )
    check("SelectedReason syncs reason.alert from the chosen entry", PersonalPlayerNotes.db.profile.reason.alert, true)

    local idBeforeInvalidSelection = PersonalPlayerNotes.db.profile.reason.id
    PersonalPlayerNotes:SelectedReason({ "id" }, 99)
    check(
        "SelectedReason with an out-of-range id leaves the current selection untouched",
        PersonalPlayerNotes.db.profile.reason.id,
        idBeforeInvalidSelection
    )
end

do
    PersonalPlayerNotes.db = freshDb()
    PersonalPlayerNotes:SetReasons({
        { id = 1, reason = "First", color = { r = 1, g = 1, b = 1 }, alert = false },
        { id = 2, reason = "Second", color = { r = 0, g = 0, b = 0 }, alert = true },
    })
    PersonalPlayerNotes.db.profile.reason.id = 2

    PersonalPlayerNotes:RemoveReason()
    check("RemoveReason removes the selected reason", #PersonalPlayerNotes:GetReasons(), 1)
    check("RemoveReason re-selects the new last reason", PersonalPlayerNotes.db.profile.reason.id, 1)
    check(
        "RemoveReason syncs reason.reason to the new last reason",
        PersonalPlayerNotes.db.profile.reason.reason,
        "First"
    )
end

do
    PersonalPlayerNotes.db = freshDb()
    PersonalPlayerNotes:SetReasonColor({ "color" }, 0.25, 0.5, 0.75)
    local r, g, b = PersonalPlayerNotes:GetReasonColor({ "color" })
    check("SetReasonColor/GetReasonColor round-trip (r)", r, 0.25)
    check("SetReasonColor/GetReasonColor round-trip (g)", g, 0.5)
    check("SetReasonColor/GetReasonColor round-trip (b)", b, 0.75)

    PersonalPlayerNotes.db.profile.reason.color = {}
    local dr, dg, db = PersonalPlayerNotes:GetReasonColor({ "color" })
    check("GetReasonColor defaults a missing r to 1", dr, 1)
    check("GetReasonColor defaults a missing g to 1", dg, 1)
    check("GetReasonColor defaults a missing b to 1", db, 1)
end

do
    PersonalPlayerNotes.db = freshDb()
    check("GetReasonAlert reads the current alert flag", PersonalPlayerNotes:GetReasonAlert({ "alert" }), false)
    PersonalPlayerNotes:SetReasonAlert({ "alert" }, true)
    check("SetReasonAlert writes the alert flag on reason", PersonalPlayerNotes.db.profile.reason.alert, true)
    check(
        "SetReasonAlert also updates the matching entry in reasons[]",
        PersonalPlayerNotes:GetReasons()[PersonalPlayerNotes.db.profile.reason.id].alert,
        true
    )
end

--#endregion

--#region Listed players

do
    PersonalPlayerNotes.db = freshDb()
    check(
        "GetListedPlayers returns the profile's listedPlayers table",
        PersonalPlayerNotes:GetListedPlayers(),
        PersonalPlayerNotes.db.profile.listedPlayers
    )
end

do
    PersonalPlayerNotes.db = freshDb()
    PersonalPlayerNotes:SetReasons({ { id = 1, reason = "AFK", color = { r = 1, g = 1, b = 1 }, alert = false } })
    PersonalPlayerNotes.db.profile.listedPlayers = {}
    PersonalPlayerNotes.db.profile.listedPlayer.id = 0

    local created = PersonalPlayerNotes:NewListedPlayer("Thrall", "Frostmourne")
    check("NewListedPlayer assigns the first id", created.id, 1)
    check("NewListedPlayer stores the given name", created.name, "Thrall")
    check("NewListedPlayer stores the given realm", created.realm, "Frostmourne")
    check("NewListedPlayer defaults reason to 1", created.reason, 1)
    check("NewListedPlayer defaults description to an empty string", created.description, "")
    check("NewListedPlayer appends to listedPlayers", #PersonalPlayerNotes:GetListedPlayers(), 1)

    local found = PersonalPlayerNotes:GetListedPlayer("Thrall", "Frostmourne")
    check("GetListedPlayer finds a player by name/realm", found, created)

    local notFound = PersonalPlayerNotes:GetListedPlayer("Jaina", "Frostmourne")
    check("GetListedPlayer returns nil for an unlisted player", notFound, nil)
end

-- SetListedPlayerRealm/SetListedPlayerName sync ALL fields from the
-- `listedPlayer` scratch/mirror object onto the stored player entry (not
-- just the field being edited), so the mirror must be fully populated to
-- match the player being edited first - exactly like the real options UI
-- would do via SetListedPlayerSelected before editing a sub-field.
local function selectPlayerForEditing(player)
    local listedPlayer = PersonalPlayerNotes.db.profile.listedPlayer
    listedPlayer.id = player.id
    listedPlayer.name = player.name
    listedPlayer.realm = player.realm
    listedPlayer.reason = player.reason
    listedPlayer.description = player.description
    listedPlayer.color = player.color
    listedPlayer.alert = player.alert
end

do
    PersonalPlayerNotes.db = freshDb()
    local player = {
        id = 1,
        name = "Thrall",
        realm = "Frostmourne",
        reason = 1,
        description = "",
        color = { r = 1, g = 1, b = 1 },
        alert = true,
    }
    PersonalPlayerNotes.db.profile.listedPlayers = { player }
    selectPlayerForEditing(player)

    check(
        "GetListedPlayerRealm reads the selected-player mirror",
        PersonalPlayerNotes:GetListedPlayerRealm({ "realm" }),
        "Frostmourne"
    )

    PersonalPlayerNotes:SetListedPlayerRealm({ "realm" }, "Stormrage")
    check(
        "SetListedPlayerRealm updates the stored player's realm",
        PersonalPlayerNotes:GetListedPlayers()[1].realm,
        "Stormrage"
    )
    check(
        "SetListedPlayerRealm keeps the stored player's name intact",
        PersonalPlayerNotes:GetListedPlayers()[1].name,
        "Thrall"
    )
end

do
    PersonalPlayerNotes.db = freshDb()
    local player = {
        id = 1,
        name = "Thrall",
        realm = "Frostmourne",
        reason = 1,
        description = "",
        color = { r = 1, g = 1, b = 1 },
        alert = true,
    }
    PersonalPlayerNotes.db.profile.listedPlayers = { player }
    selectPlayerForEditing(player)

    check(
        "GetListedPlayerName reads the selected-player mirror",
        PersonalPlayerNotes:GetListedPlayerName({ "name" }),
        "Thrall"
    )

    -- Renaming to a name that already exists at the same realm should sync
    -- fields onto the existing entry instead of creating a duplicate.
    PersonalPlayerNotes:SetListedPlayerName({ "name" }, "Thrall")
    check("SetListedPlayerName on an unchanged name keeps a single entry", #PersonalPlayerNotes:GetListedPlayers(), 1)

    -- Renaming to a name/realm combination that doesn't exist yet creates a
    -- brand new listed player instead.
    PersonalPlayerNotes:SetListedPlayerName({ "name" }, "Jaina")
    check("SetListedPlayerName with an unknown name creates a new entry", #PersonalPlayerNotes:GetListedPlayers(), 2)
end

do
    PersonalPlayerNotes.db = freshDb()
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
        {
            id = 2,
            name = "Jaina",
            realm = "Theramore",
            reason = 1,
            description = "",
            color = { r = 1, g = 1, b = 1 },
            alert = false,
        },
    }
    PersonalPlayerNotes.db.profile.listedPlayer.id = 2

    PersonalPlayerNotes:RemoveListedPlayer()
    check("RemoveListedPlayer removes the selected player", #PersonalPlayerNotes:GetListedPlayers(), 1)
    check("RemoveListedPlayer re-selects the new last player", PersonalPlayerNotes.db.profile.listedPlayer.id, 1)
    check(
        "RemoveListedPlayer syncs listedPlayer.name to the new last player",
        PersonalPlayerNotes.db.profile.listedPlayer.name,
        "Thrall"
    )
end

do
    -- Removing the very last listed player must not crash (listedPlayers[0]
    -- used to be indexed here, erroring "attempt to index a nil value").
    PersonalPlayerNotes.db = freshDb()
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
    PersonalPlayerNotes.db.profile.listedPlayer.id = 1

    local ok = PersonalPlayerNotes:RemoveListedPlayer()
    check("RemoveListedPlayer does not error when removing the last player", ok, true)
    check("RemoveListedPlayer allows listedPlayers to become empty", #PersonalPlayerNotes:GetListedPlayers(), 0)
    check(
        "RemoveListedPlayer resets the mirror's id to 0 when the list is empty",
        PersonalPlayerNotes.db.profile.listedPlayer.id,
        0
    )
    check(
        "RemoveListedPlayer resets the mirror's name to blank when the list is empty",
        PersonalPlayerNotes.db.profile.listedPlayer.name,
        ""
    )
end

do
    PersonalPlayerNotes.db = freshDb()
    PersonalPlayerNotes.db.profile.listedPlayers = {
        {
            id = 1,
            name = "Thrall",
            realm = "Frostmourne",
            reason = 1,
            description = "",
            color = { r = 1, g = 1, b = 1 },
            alert = false,
        },
    }
    PersonalPlayerNotes.db.profile.listedPlayer.id = 1

    PersonalPlayerNotes:SetListedPlayerSelectedReason({ "reason" }, 2)
    check(
        "SetListedPlayerSelectedReason writes reason on the stored player",
        PersonalPlayerNotes:GetListedPlayers()[1].reason,
        2
    )
    check(
        "GetListedPlayerSelectedReason reads back the selected-player mirror",
        PersonalPlayerNotes:GetListedPlayerSelectedReason({ "reason" }),
        2
    )

    PersonalPlayerNotes:SetListedPlayerSelectedDescription({ "description" }, "Ninja looted raid gear")
    check(
        "SetListedPlayerSelectedDescription writes description on the stored player",
        PersonalPlayerNotes:GetListedPlayers()[1].description,
        "Ninja looted raid gear"
    )
    check(
        "GetListedPlayerSelectedDescription reads back the selected-player mirror",
        PersonalPlayerNotes:GetListedPlayerSelectedDescription({ "description" }),
        "Ninja looted raid gear"
    )

    PersonalPlayerNotes:SetListedPlayerColor({ "color" }, 0.1, 0.2, 0.3)
    local r, g, b = PersonalPlayerNotes:GetListedPlayerColor({ "color" })
    check("SetListedPlayerColor/GetListedPlayerColor round-trip (r)", r, 0.1)
    check("SetListedPlayerColor/GetListedPlayerColor round-trip (g)", g, 0.2)
    check("SetListedPlayerColor/GetListedPlayerColor round-trip (b)", b, 0.3)

    PersonalPlayerNotes:SetListedPlayerAlert({ "alert" }, true)
    check(
        "SetListedPlayerAlert writes the stored player's alert flag",
        PersonalPlayerNotes:GetListedPlayers()[1].alert,
        true
    )
    check(
        "GetListedPlayerAlert reads back the selected-player mirror",
        PersonalPlayerNotes:GetListedPlayerAlert({ "alert" }),
        true
    )
end

do
    PersonalPlayerNotes.db = freshDb()
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
        {
            id = 2,
            name = "Jaina",
            realm = "Theramore",
            reason = 1,
            description = "",
            color = { r = 1, g = 1, b = 1 },
            alert = false,
        },
    }
    PersonalPlayerNotes.db.profile.listedPlayer.id = 1

    PersonalPlayerNotes:SetListedPlayerSelected({ "id" }, 2)
    check(
        "SetListedPlayerSelected switches to the requested player's id",
        PersonalPlayerNotes.db.profile.listedPlayer.id,
        2
    )
    check(
        "SetListedPlayerSelected syncs the selected player's name",
        PersonalPlayerNotes.db.profile.listedPlayer.name,
        "Jaina"
    )
    check(
        "GetListedPlayerSelected reads back the requested field",
        PersonalPlayerNotes:GetListedPlayerSelected({ "name" }),
        "Jaina"
    )
end

--#endregion

if failures > 0 then
    print(string.format("\n%d test(s) failed.", failures))
    os.exit(1)
end

print("\nAll tests passed.")
