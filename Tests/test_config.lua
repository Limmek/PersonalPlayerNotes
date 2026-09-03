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
    check("defaults.alert.sessionOnly starts false", profile.alert.sessionOnly, false)
    check("defaults.alert.sound starts at default.mp3", profile.alert.sound, "default.mp3")
    check("defaults.alert.customSounds starts empty", #profile.alert.customSounds, 0)
    check("defaults.alert.newCustomSound starts empty", profile.alert.newCustomSound, "")
    check("SoundManifest has 1 entry", #PersonalPlayerNotes.SoundManifest, 1)
    check("SoundManifest lists default.mp3 first", PersonalPlayerNotes.SoundManifest[1], "default.mp3")
    check("defaults.customIcons starts empty", #profile.customIcons, 0)
    check("defaults.newCustomIcon starts empty", profile.newCustomIcon, "")
    check("defaults.customIconSelected starts empty", profile.customIconSelected, "")
    check("defaults.reasons has exactly 1 entry", #profile.reasons, 1)
    check("defaults.reasons[1].id is 1", profile.reasons[1].id, 1)
    check("defaults.reasons[1].icon starts nil", profile.reasons[1].icon, nil)
    check("defaults.reason.icon starts nil", profile.reason.icon, nil)
    check("defaults.listedPlayers has exactly 1 entry", #profile.listedPlayers, 1)
    check("defaults.listedPlayer.id is 1", profile.listedPlayer.id, 1)
    check("defaults.listedPlayer.icon starts nil", profile.listedPlayer.icon, nil)
    check("defaults.listedPlayers[1].icon starts nil", profile.listedPlayers[1].icon, nil)
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

    check(
        "GetAlertSoundEffect reads the current sound filename",
        PersonalPlayerNotes:GetAlertSoundEffect(),
        "default.mp3"
    )

    PersonalPlayerNotes:PlayAlertSoundEffect()
    check(
        "PlayAlertSoundEffect plays the currently selected sound file",
        playedPath,
        "Interface\\AddOns\\PersonalPlayerNotes\\Sounds\\default.mp3"
    )
    check("PlayAlertSoundEffect defaults to the master channel", playedChannel, "master")

    PersonalPlayerNotes:PlayAlertSoundEffect("alarmbuzz.ogg", "sfx")
    check(
        "PlayAlertSoundEffect accepts an explicit effect filename",
        playedPath,
        "Interface\\AddOns\\PersonalPlayerNotes\\Sounds\\alarmbuzz.ogg"
    )
    check("PlayAlertSoundEffect accepts an explicit channel", playedChannel, "sfx")

    PersonalPlayerNotes:SetAlertSoundEffect({ "sound" }, "alarmbuzzer.ogg")
    check(
        "SetAlertSoundEffect writes the sound filename",
        PersonalPlayerNotes.db.profile.alert.sound,
        "alarmbuzzer.ogg"
    )
    check(
        "SetAlertSoundEffect also plays the newly selected sound",
        playedPath,
        "Interface\\AddOns\\PersonalPlayerNotes\\Sounds\\alarmbuzzer.ogg"
    )

    PersonalPlayerNotes.db.profile.alert.newCustomSound = "  mine.mp3  "
    PersonalPlayerNotes:AddCustomSound()
    check(
        "AddCustomSound trims and adds the typed filename",
        PersonalPlayerNotes.db.profile.alert.customSounds[1],
        "mine.mp3"
    )
    check("AddCustomSound clears the input field", PersonalPlayerNotes.db.profile.alert.newCustomSound, "")
    check("IsCustomSound recognizes an added custom sound", PersonalPlayerNotes:IsCustomSound("mine.mp3"), true)
    check("IsCustomSound is false for a shipped sound", PersonalPlayerNotes:IsCustomSound("default.mp3"), false)

    PersonalPlayerNotes.db.profile.alert.newCustomSound = "mine.mp3"
    PersonalPlayerNotes:AddCustomSound()
    check("AddCustomSound does not add a duplicate", #PersonalPlayerNotes.db.profile.alert.customSounds, 1)

    PersonalPlayerNotes.db.profile.alert.newCustomSound = "default.mp3"
    PersonalPlayerNotes:AddCustomSound()
    check(
        "AddCustomSound does not add a name already in the shipped manifest",
        #PersonalPlayerNotes.db.profile.alert.customSounds,
        1
    )

    PersonalPlayerNotes.db.profile.alert.newCustomSound = "   "
    PersonalPlayerNotes:AddCustomSound()
    check("AddCustomSound ignores a blank/whitespace-only name", #PersonalPlayerNotes.db.profile.alert.customSounds, 1)

    PersonalPlayerNotes:SetAlertSoundEffect({ "sound" }, "mine.mp3")
    check(
        "PlayAlertSoundEffect plays a custom-added sound directly by filename",
        playedPath,
        "Interface\\AddOns\\PersonalPlayerNotes\\Sounds\\mine.mp3"
    )

    PersonalPlayerNotes:RemoveCustomSound()
    check(
        "RemoveCustomSound removes the currently selected custom sound",
        #PersonalPlayerNotes.db.profile.alert.customSounds,
        0
    )
    check(
        "RemoveCustomSound resets the global selection back to the default sound",
        PersonalPlayerNotes.db.profile.alert.sound,
        "default.mp3"
    )

    PersonalPlayerNotes.db.profile.alert.sound = "default.mp3"
    PersonalPlayerNotes:RemoveCustomSound()
    check(
        "RemoveCustomSound is a no-op when the current selection isn't a custom sound",
        PersonalPlayerNotes.db.profile.alert.sound,
        "default.mp3"
    )

    _G.PlaySoundFile = nil
end

--#endregion

--#region Custom Icons

do
    PersonalPlayerNotes.db = freshDb()

    PersonalPlayerNotes.db.profile.newCustomIcon = "  mine.png  "
    PersonalPlayerNotes:AddCustomIcon()
    check("AddCustomIcon trims and adds the typed filename", PersonalPlayerNotes.db.profile.customIcons[1], "mine.png")
    check("AddCustomIcon clears the input field", PersonalPlayerNotes.db.profile.newCustomIcon, "")
    check("AddCustomIcon selects the newly added icon", PersonalPlayerNotes.db.profile.customIconSelected, "mine.png")
    check("IsCustomIcon recognizes an added custom icon", PersonalPlayerNotes:IsCustomIcon("mine.png"), true)
    check("IsCustomIcon is false for an unadded filename", PersonalPlayerNotes:IsCustomIcon("other.png"), false)

    PersonalPlayerNotes.db.profile.newCustomIcon = "mine.png"
    PersonalPlayerNotes:AddCustomIcon()
    check("AddCustomIcon does not add a duplicate", #PersonalPlayerNotes.db.profile.customIcons, 1)

    PersonalPlayerNotes.db.profile.newCustomIcon = "   "
    PersonalPlayerNotes:AddCustomIcon()
    check("AddCustomIcon ignores a blank/whitespace-only name", #PersonalPlayerNotes.db.profile.customIcons, 1)

    PersonalPlayerNotes.db.profile.newCustomIcon = "second.png"
    PersonalPlayerNotes:AddCustomIcon()
    check("AddCustomIcon appends a second entry", #PersonalPlayerNotes.db.profile.customIcons, 2)

    PersonalPlayerNotes.db.profile.customIconSelected = "mine.png"
    PersonalPlayerNotes:RemoveCustomIcon()
    check("RemoveCustomIcon removes the selected custom icon", #PersonalPlayerNotes.db.profile.customIcons, 1)
    check(
        "RemoveCustomIcon re-selects the remaining icon",
        PersonalPlayerNotes.db.profile.customIconSelected,
        "second.png"
    )

    PersonalPlayerNotes:RemoveCustomIcon()
    check("RemoveCustomIcon can empty the custom icons list", #PersonalPlayerNotes.db.profile.customIcons, 0)
    check(
        "RemoveCustomIcon resets the selection to blank when empty",
        PersonalPlayerNotes.db.profile.customIconSelected,
        ""
    )

    PersonalPlayerNotes:RemoveCustomIcon()
    check("RemoveCustomIcon is a no-op when nothing is selected", #PersonalPlayerNotes.db.profile.customIcons, 0)
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

do
    PersonalPlayerNotes.db = freshDb()
    check(
        "GetReasonSound defaults to __inherit__ when unset",
        PersonalPlayerNotes:GetReasonSound({ "sound" }),
        "__inherit__"
    )

    PersonalPlayerNotes:SetReasonSound({ "sound" }, "alarmbuzz.ogg")
    check("SetReasonSound writes the sound on reason", PersonalPlayerNotes.db.profile.reason.sound, "alarmbuzz.ogg")
    check(
        "SetReasonSound also updates the matching entry in reasons[]",
        PersonalPlayerNotes:GetReasons()[PersonalPlayerNotes.db.profile.reason.id].sound,
        "alarmbuzz.ogg"
    )
    check("GetReasonSound reads the overridden sound", PersonalPlayerNotes:GetReasonSound({ "sound" }), "alarmbuzz.ogg")

    PersonalPlayerNotes:SetReasonSound({ "sound" }, "__inherit__")
    check("SetReasonSound(__inherit__) stores nil", PersonalPlayerNotes.db.profile.reason.sound, nil)
    check(
        "GetReasonSound reports __inherit__ again after clearing",
        PersonalPlayerNotes:GetReasonSound({ "sound" }),
        "__inherit__"
    )

    check("GetReasonIcon defaults to blank input when unset", PersonalPlayerNotes:GetReasonIcon({ "icon" }), "")

    PersonalPlayerNotes:SetReasonIcon({ "icon" }, "Interface\\Icons\\INV_Misc_QuestionMark")
    check(
        "SetReasonIcon writes the icon on reason",
        PersonalPlayerNotes.db.profile.reason.icon,
        "Interface\\Icons\\INV_Misc_QuestionMark"
    )
    check(
        "SetReasonIcon also updates the matching entry in reasons[]",
        PersonalPlayerNotes:GetReasons()[PersonalPlayerNotes.db.profile.reason.id].icon,
        "Interface\\Icons\\INV_Misc_QuestionMark"
    )

    PersonalPlayerNotes:SetReasonIcon({ "icon" }, "")
    check("SetReasonIcon(blank) stores nil", PersonalPlayerNotes.db.profile.reason.icon, nil)

    PersonalPlayerNotes:SetReasonIcon({ "icon" }, "12345")
    check("SetReasonIcon accepts numeric fileIDs", PersonalPlayerNotes.db.profile.reason.icon, "12345")

    PersonalPlayerNotes:SetReasonIcon({ "icon" }, "|Tbad|t")
    check("SetReasonIcon rejects unsafe texture tags", PersonalPlayerNotes.db.profile.reason.icon, nil)
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

    check(
        "GetListedPlayerIcon defaults to blank input when unset",
        PersonalPlayerNotes:GetListedPlayerIcon({ "icon" }),
        ""
    )

    PersonalPlayerNotes:SetListedPlayerIcon({ "icon" }, "Interface\\Icons\\INV_Sword_04")
    check(
        "SetListedPlayerIcon writes the icon on listedPlayer",
        PersonalPlayerNotes.db.profile.listedPlayer.icon,
        "Interface\\Icons\\INV_Sword_04"
    )
    check(
        "SetListedPlayerIcon also updates the backing listedPlayers[] entry",
        PersonalPlayerNotes.db.profile.listedPlayers[1].icon,
        "Interface\\Icons\\INV_Sword_04"
    )

    PersonalPlayerNotes:SetListedPlayerIcon({ "icon" }, "")
    check("SetListedPlayerIcon(blank) stores nil", PersonalPlayerNotes.db.profile.listedPlayer.icon, nil)
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

    check(
        "GetListedPlayerSound defaults to __inherit__ when unset",
        PersonalPlayerNotes:GetListedPlayerSound({ "sound" }),
        "__inherit__"
    )
    PersonalPlayerNotes:SetListedPlayerSound({ "sound" }, "alarmdouble.ogg")
    check(
        "SetListedPlayerSound writes the stored player's sound",
        PersonalPlayerNotes:GetListedPlayers()[1].sound,
        "alarmdouble.ogg"
    )
    check(
        "GetListedPlayerSound reads back the selected-player mirror",
        PersonalPlayerNotes:GetListedPlayerSound({ "sound" }),
        "alarmdouble.ogg"
    )
    PersonalPlayerNotes:SetListedPlayerSound({ "sound" }, "__inherit__")
    check("SetListedPlayerSound(__inherit__) stores nil", PersonalPlayerNotes:GetListedPlayers()[1].sound, nil)
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
