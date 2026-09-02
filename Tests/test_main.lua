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

--[[
    GameTooltip, MiniMapIcon, DropDownMenuInitialize and UnitPopup_ShowMenu
    are normally excluded from unit testing here as "WoW-API-coupled" (see
    the module docstring above and .github/AGENTS.md), since they're
    registered as hooks/callbacks into real Blizzard UI objects (tooltips,
    Menu descriptions, dropdown menus, LibDataBroker data objects).

    However, each of these is written with colon-method sugar
    (`function PersonalPlayerNotes:GameTooltip()`, etc.), which the WoW
    client always invokes with the *real UI object* as `self`/the callback
    args - not with the addon table. That's what makes the pure decision
    logic inside them (which button/line to show, which options panel to
    open, whether to create/edit a listed player, whether to fire an alert)
    directly callable here with small fake doubles standing in for the real
    tooltip/rootDescription/dropdown-button objects, instead of a real WoW
    client. The one genuine boundary that still can't be usefully faked is
    AceGUIDefaults() (real AceGUI-3.0 widget creation), so it's stubbed out
    exactly like LibStub()-returned libraries are elsewhere in these tests -
    the actual Blizzard rendering behind all four hooks remains untested.
]]

-- GameTooltip
local function newFakeTooltip(name, unit)
    local calls = {}
    return {
        calls = calls,
        GetUnit = function()
            return name, unit
        end,
        AddLine = function(_, text, r, g, b, wrap)
            table.insert(calls, { kind = "AddLine", text = text, r = r, g = g, b = b, wrap = wrap })
        end,
        AddDoubleLine = function(_, left, right, r, g, b)
            table.insert(calls, { kind = "AddDoubleLine", left = left, right = right, r = r, g = g, b = b })
        end,
    }
end

local function freshGameTooltipAddon()
    local addon = bootstrap.loadAddon()
    addon.db = {
        profile = {
            icon = "Interface\\AddOns\\PersonalPlayerNotes\\Images\\icon.png",
            reasons = { { id = 1, reason = "Ninja looter", color = { r = 1, g = 0, b = 0 }, alert = true } },
            listedPlayers = {
                {
                    id = 1,
                    name = "Thrall",
                    realm = "Frostmourne",
                    reason = 1,
                    description = "Stole the raid loot",
                    color = { r = 0, g = 1, b = 0 },
                    alert = true,
                },
            },
            alert = { enabled = true, delay = 10, last = {} },
        },
    }
    addon.ScheduleTimer = function() end
    addon.PlayAlertSoundEffect = function() end
    return addon
end

_G.time = function()
    return 1000
end
_G.PlaySoundFile = function() end

do
    local addon = freshGameTooltipAddon()
    _G.UnitIsPlayer = function()
        return true
    end
    _G.UnitFullName = function()
        return "Thrall", "Frostmourne"
    end
    _G.GetRealmName = function()
        return "Frostmourne"
    end
    _G.issecretvalue = nil

    local tooltip = newFakeTooltip(nil, nil)
    addon.GameTooltip(tooltip)
    check("GameTooltip is a no-op without a unit token", #tooltip.calls, 0)
end

do
    local addon = freshGameTooltipAddon()
    _G.issecretvalue = function()
        return true
    end
    _G.UnitIsPlayer = function()
        return true
    end
    _G.UnitFullName = function()
        return "Thrall", "Frostmourne"
    end
    _G.GetRealmName = function()
        return "Frostmourne"
    end

    local tooltip = newFakeTooltip("Thrall", "target")
    addon.GameTooltip(tooltip)
    check("GameTooltip is a no-op for a secret unit", #tooltip.calls, 0)
    _G.issecretvalue = nil
end

do
    local addon = freshGameTooltipAddon()
    _G.UnitIsPlayer = function()
        return false
    end

    local tooltip = newFakeTooltip("Grunt", "target")
    addon.GameTooltip(tooltip)
    check("GameTooltip is a no-op for a non-player unit", #tooltip.calls, 0)
end

do
    local addon = freshGameTooltipAddon()
    _G.UnitIsPlayer = function()
        return true
    end
    -- UnitFullName's name disagrees with GetUnit()'s name: stale tooltip data.
    _G.UnitFullName = function()
        return "SomeoneElse", "Frostmourne"
    end
    _G.GetRealmName = function()
        return "Frostmourne"
    end

    local tooltip = newFakeTooltip("Thrall", "target")
    addon.GameTooltip(tooltip)
    check("GameTooltip is a no-op when UnitFullName disagrees with GetUnit's name", #tooltip.calls, 0)
end

do
    local addon = freshGameTooltipAddon()
    addon.db.profile.listedPlayers = {}
    _G.UnitIsPlayer = function()
        return true
    end
    _G.UnitFullName = function()
        return "Jaina", "Theramore"
    end
    _G.GetRealmName = function()
        return "Theramore"
    end

    local tooltip = newFakeTooltip("Jaina", "target")
    addon.GameTooltip(tooltip)
    check("GameTooltip is a no-op for an unlisted player", #tooltip.calls, 0)
end

do
    local addon = freshGameTooltipAddon()
    addon.db.profile.reasons = { { id = 1, reason = "None", color = { r = 1, g = 1, b = 1 }, alert = false } }
    addon.db.profile.listedPlayers[1].reason = 1
    addon.db.profile.listedPlayers[1].description = ""
    _G.UnitIsPlayer = function()
        return true
    end
    _G.UnitFullName = function()
        return "Thrall", "Frostmourne"
    end
    _G.GetRealmName = function()
        return "Frostmourne"
    end

    local tooltip = newFakeTooltip("Thrall", "target")
    addon.GameTooltip(tooltip)
    check("GameTooltip adds no extra lines for the default 'None'/empty-description entry", #tooltip.calls, 0)
end

do
    local addon = freshGameTooltipAddon()
    _G.UnitIsPlayer = function()
        return true
    end
    _G.UnitFullName = function()
        return "Thrall", "Frostmourne"
    end
    _G.GetRealmName = function()
        return "Frostmourne"
    end

    local tooltip = newFakeTooltip("Thrall", "target")
    addon.GameTooltip(tooltip)
    check("GameTooltip adds the reason/description lines for a listed player", #tooltip.calls, 3)
    check("GameTooltip's first added line is a blank separator", tooltip.calls[1].kind, "AddLine")
    check("GameTooltip's double line shows the reason text", tooltip.calls[2].left, "Ninja looter")
    check("GameTooltip's last line shows the player's description", tooltip.calls[3].text, "Stole the raid loot")
end

do
    local addon = freshGameTooltipAddon()
    _G.UnitIsPlayer = function()
        return true
    end
    _G.UnitFullName = function()
        return "Thrall", "Frostmourne"
    end
    _G.GetRealmName = function()
        return "Frostmourne"
    end

    local scheduled
    addon.ScheduleTimer = function(_, callbackName, delay, name)
        scheduled = { callbackName = callbackName, delay = delay, name = name }
    end
    local played, playedSound
    addon.PlayAlertSoundEffect = function(_, sound)
        played = true
        playedSound = sound
    end
    addon.db.profile.alert.sound = "default.mp3"

    local tooltip = newFakeTooltip("Thrall", "target")
    addon.GameTooltip(tooltip)
    check("GameTooltip schedules an alert for a first-time listed-player sighting", scheduled ~= nil, true)
    check("GameTooltip's alert timer targets AlertDelayTimer", scheduled.callbackName, "AlertDelayTimer")
    check("GameTooltip's alert timer uses the profile's alert delay", scheduled.delay, 10)
    check("GameTooltip plays the alert sound effect", played, true)
    check("GameTooltip falls back to the global sound when reason/player have none", playedSound, "default.mp3")
    check("GameTooltip records the alert cooldown expiry", addon.db.profile.alert.last["Thrall"], 1010)
end

do
    local addon = freshGameTooltipAddon()
    _G.UnitIsPlayer = function()
        return true
    end
    _G.UnitFullName = function()
        return "Thrall", "Frostmourne"
    end
    _G.GetRealmName = function()
        return "Frostmourne"
    end

    local playedSound
    addon.PlayAlertSoundEffect = function(_, sound)
        playedSound = sound
    end
    addon.db.profile.alert.sound = "default.mp3"
    addon.db.profile.reasons[1].sound = "alarmbuzz.ogg"

    local tooltip = newFakeTooltip("Thrall", "target")
    addon.GameTooltip(tooltip)
    check("GameTooltip prefers the reason's sound over the global default", playedSound, "alarmbuzz.ogg")
end

do
    local addon = freshGameTooltipAddon()
    _G.UnitIsPlayer = function()
        return true
    end
    _G.UnitFullName = function()
        return "Thrall", "Frostmourne"
    end
    _G.GetRealmName = function()
        return "Frostmourne"
    end

    local playedSound
    addon.PlayAlertSoundEffect = function(_, sound)
        playedSound = sound
    end
    addon.db.profile.alert.sound = "default.mp3"
    addon.db.profile.reasons[1].sound = "alarmbuzz.ogg"
    addon.db.profile.listedPlayers[1].sound = "alarmdouble.ogg"

    local tooltip = newFakeTooltip("Thrall", "target")
    addon.GameTooltip(tooltip)
    check("GameTooltip prefers the player's sound over the reason's and global default", playedSound, "alarmdouble.ogg")
end

do
    local addon = freshGameTooltipAddon()
    addon.db.profile.alert.last["Thrall"] = 2000 -- still within cooldown
    _G.UnitIsPlayer = function()
        return true
    end
    _G.UnitFullName = function()
        return "Thrall", "Frostmourne"
    end
    _G.GetRealmName = function()
        return "Frostmourne"
    end

    local scheduled = false
    addon.ScheduleTimer = function()
        scheduled = true
    end

    local tooltip = newFakeTooltip("Thrall", "target")
    addon.GameTooltip(tooltip)
    check("GameTooltip does not re-trigger the alert within its cooldown", scheduled, false)
end

do
    local addon = freshGameTooltipAddon()
    addon.db.profile.alert.sessionOnly = true
    _G.UnitIsPlayer = function()
        return true
    end
    _G.UnitFullName = function()
        return "Thrall", "Frostmourne"
    end
    _G.GetRealmName = function()
        return "Frostmourne"
    end

    local scheduled = false
    addon.ScheduleTimer = function()
        scheduled = true
    end
    local played = false
    addon.PlayAlertSoundEffect = function()
        played = true
    end

    local tooltip = newFakeTooltip("Thrall", "target")
    addon.GameTooltip(tooltip)
    check("GameTooltip's sessionOnly alert does not schedule an AlertDelayTimer", scheduled, false)
    check("GameTooltip's sessionOnly alert still plays the sound the first time", played, true)
    check("GameTooltip's sessionOnly alert marks the player as alerted", addon.db.profile.alert.last["Thrall"], true)

    played = false
    addon.GameTooltip(tooltip)
    check("GameTooltip's sessionOnly alert does not repeat for the same player", played, false)
end

do
    local addon = freshGameTooltipAddon()
    addon.db.profile.alert.enabled = false
    _G.UnitIsPlayer = function()
        return true
    end
    _G.UnitFullName = function()
        return "Thrall", "Frostmourne"
    end
    _G.GetRealmName = function()
        return "Frostmourne"
    end

    local scheduled = false
    addon.ScheduleTimer = function()
        scheduled = true
    end

    local tooltip = newFakeTooltip("Thrall", "target")
    addon.GameTooltip(tooltip)
    check("GameTooltip does not alert when alerts are globally disabled", scheduled, false)
end

_G.UnitIsPlayer = nil
_G.UnitFullName = nil
_G.GetRealmName = nil
_G.issecretvalue = nil
_G.time = nil
_G.PlaySoundFile = nil

-- MiniMapIcon: OnClick left/right/modifier-click routing, OnTooltipShow.
-- LibDataBroker is captured as a module-level upvalue at load time, so a
-- custom LibStub override that echoes the data object straight back
-- (instead of the generic no-op stub) is needed to get a handle on its
-- OnClick/OnTooltipShow closures at all.
local minimapDialogState = { openedKey = nil }
local function libStubForMiniMapIcon()
    local defaultStub = bootstrap.defaultLibStub()
    return function(major)
        if major == "LibDataBroker-1.1" then
            return {
                NewDataObject = function(_, _, dataObject)
                    return dataObject
                end,
            }
        end
        if major == "AceConfigDialog-3.0" then
            return {
                CloseAll = function() end,
                SetDefaultSize = function() end,
                Open = function(_, key)
                    minimapDialogState.openedKey = key
                end,
            }
        end
        return defaultStub(major)
    end
end

local function freshMiniMapIconAddon()
    local addon = bootstrap.loadAddon(libStubForMiniMapIcon())
    addon.db = { profile = { icon = "Interface\\AddOns\\PersonalPlayerNotes\\Images\\icon.png" } }
    -- AceGUIDefaults() creates a real AceGUI-3.0 Frame widget - the one
    -- genuine boundary that can't be usefully faked, so it's stubbed here
    -- exactly like LibStub()-returned libraries are stubbed elsewhere.
    addon.AceGUIDefaults = function()
        return { SetTitle = function() end }
    end
    return addon
end

do
    local addon = freshMiniMapIconAddon()
    local dataObject = addon:MiniMapIcon()
    minimapDialogState.openedKey = nil

    dataObject.OnClick(nil, "RightButton")
    check(
        "MiniMapIcon's right-click opens the Blizzard options fallback",
        minimapDialogState.openedKey,
        "PersonalPlayerNotesSettings Info"
    )
end

do
    local addon = freshMiniMapIconAddon()
    local dataObject = addon:MiniMapIcon()
    minimapDialogState.openedKey = nil
    _G.IsShiftKeyDown = function()
        return false
    end
    _G.IsControlKeyDown = function()
        return false
    end

    dataObject.OnClick(nil, "LeftButton")
    check(
        "MiniMapIcon's plain left-click opens the Settings panel",
        minimapDialogState.openedKey,
        "PersonalPlayerNotesSettings Options"
    )
end

do
    local addon = freshMiniMapIconAddon()
    local dataObject = addon:MiniMapIcon()
    minimapDialogState.openedKey = nil
    _G.IsShiftKeyDown = function()
        return true
    end
    _G.IsControlKeyDown = function()
        return false
    end

    dataObject.OnClick(nil, "LeftButton")
    check(
        "MiniMapIcon's shift-left-click opens the Reasons panel",
        minimapDialogState.openedKey,
        "PersonalPlayerNotesSettings Reasons"
    )
end

do
    local addon = freshMiniMapIconAddon()
    local dataObject = addon:MiniMapIcon()
    minimapDialogState.openedKey = nil
    _G.IsShiftKeyDown = function()
        return false
    end
    _G.IsControlKeyDown = function()
        return true
    end

    dataObject.OnClick(nil, "LeftButton")
    check(
        "MiniMapIcon's ctrl-left-click opens the Listed Players panel",
        minimapDialogState.openedKey,
        "PersonalPlayerNotesSettings Listed_Players"
    )
end

do
    local addon = freshMiniMapIconAddon()
    local dataObject = addon:MiniMapIcon()
    minimapDialogState.openedKey = nil

    dataObject.OnClick(nil, "MiddleButton")
    check("MiniMapIcon ignores unrecognized mouse buttons", minimapDialogState.openedKey, nil)
end

do
    local addon = freshMiniMapIconAddon()
    local dataObject = addon:MiniMapIcon()

    local hidden = {}
    _G.SettingsPanel = { name = "SettingsPanel" }
    _G.GameMenuFrame = { name = "GameMenuFrame" }
    _G.HideUIPanel = function(frame)
        table.insert(hidden, frame)
    end

    dataObject.OnClick(nil, "MiddleButton")
    check("MiniMapIcon's OnClick hides the Settings panel if present", hidden[1], _G.SettingsPanel)
    check("MiniMapIcon's OnClick hides the game menu if present", hidden[2], _G.GameMenuFrame)

    _G.SettingsPanel = nil
    _G.GameMenuFrame = nil
end

do
    local addon = freshMiniMapIconAddon()
    local dataObject = addon:MiniMapIcon()

    local tooltipCalls = {}
    local fakeTooltip = {
        AddDoubleLine = function()
            table.insert(tooltipCalls, "AddDoubleLine")
        end,
        AddLine = function()
            table.insert(tooltipCalls, "AddLine")
        end,
    }
    dataObject.OnTooltipShow(fakeTooltip)
    check("MiniMapIcon's OnTooltipShow renders the expected number of lines", #tooltipCalls, 6)
    check("MiniMapIcon's OnTooltipShow starts with the title/version double line", tooltipCalls[1], "AddDoubleLine")
end

_G.IsShiftKeyDown = nil
_G.IsControlKeyDown = nil

-- UnitPopup_ShowMenu: the legacy (pre-Menu-API) Classic dropdown fallback.
local function freshDropdownAddon()
    local addon = bootstrap.loadAddon()
    addon.db = {
        profile = {
            icon = "Interface\\AddOns\\PersonalPlayerNotes\\Images\\icon.png",
            listedPlayers = {},
            listedPlayer = { id = 1, name = "", realm = "", reason = 1, description = "", color = {}, alert = true },
        },
    }
    return addon
end

do
    local addon = freshDropdownAddon()
    local buttons = {}
    _G.UIDropDownMenu_AddButton = function(info, level)
        table.insert(buttons, { info = info, level = level })
    end
    _G.UIDropDownMenu_CreateInfo = function()
        return {}
    end
    _G.UIDROPDOWNMENU_MENU_LEVEL = 1
    _G.UIDROPDOWNMENU_MENU_VALUE = nil

    addon:UnitPopup_ShowMenu("SELF", "target", nil)
    check("UnitPopup_ShowMenu ignores the SELF target", #buttons, 0)

    addon:UnitPopup_ShowMenu("FRIEND", "target", nil)
    check("UnitPopup_ShowMenu ignores the FRIEND target", #buttons, 0)
end

do
    local addon = freshDropdownAddon()
    local buttons = {}
    _G.UIDropDownMenu_AddButton = function(info, level)
        table.insert(buttons, { info = info, level = level })
    end
    _G.UIDropDownMenu_CreateInfo = function()
        return {}
    end
    _G.UIDROPDOWNMENU_MENU_LEVEL = 1
    _G.UIDROPDOWNMENU_MENU_VALUE = nil
    _G.UnitIsPlayer = function()
        return false
    end

    addon:UnitPopup_ShowMenu("PLAYER", "target", nil)
    check("UnitPopup_ShowMenu ignores a non-player unit", #buttons, 0)
end

do
    local addon = freshDropdownAddon()
    local buttons = {}
    _G.UIDropDownMenu_AddButton = function(info, level)
        table.insert(buttons, { info = info, level = level })
    end
    _G.UIDropDownMenu_CreateInfo = function()
        return {}
    end
    _G.UIDROPDOWNMENU_MENU_LEVEL = 1
    _G.UIDROPDOWNMENU_MENU_VALUE = nil
    _G.UnitIsPlayer = function()
        return true
    end
    _G.UnitName = function()
        return "Jaina", nil
    end
    _G.GetRealmName = function()
        return "Theramore"
    end

    addon:UnitPopup_ShowMenu("PLAYER", "target", nil)
    check("UnitPopup_ShowMenu (root level, unlisted) adds exactly one button", #buttons, 1)
    check("UnitPopup_ShowMenu (root level, unlisted) offers the Add option", buttons[1].info.text, "PPN_POPUP_ADD")
    check("UnitPopup_ShowMenu (root level, unlisted) is not checkable", buttons[1].info.notCheckable, true)
end

do
    local addon = freshDropdownAddon()
    addon.db.profile.listedPlayers = {
        {
            id = 1,
            name = "Jaina",
            realm = "Theramore",
            reason = 1,
            description = "",
            color = { r = 1, g = 1, b = 1 },
            alert = true,
        },
    }
    local buttons = {}
    _G.UIDropDownMenu_AddButton = function(info, level)
        table.insert(buttons, { info = info, level = level })
    end
    _G.UIDropDownMenu_CreateInfo = function()
        return {}
    end
    _G.UIDROPDOWNMENU_MENU_LEVEL = 1
    _G.UIDROPDOWNMENU_MENU_VALUE = nil
    _G.UnitIsPlayer = function()
        return true
    end
    _G.UnitName = function()
        return "Jaina", nil
    end
    _G.GetRealmName = function()
        return "Theramore"
    end

    addon:UnitPopup_ShowMenu("PLAYER", "target", nil)
    check("UnitPopup_ShowMenu (root level, listed) adds exactly one button", #buttons, 1)
    check("UnitPopup_ShowMenu (root level, listed) shows a submenu arrow", buttons[1].info.hasArrow, true)
end

do
    local addon = freshDropdownAddon()
    addon.db.profile.listedPlayers = {
        {
            id = 1,
            name = "Jaina",
            realm = "Theramore",
            reason = 1,
            description = "",
            color = { r = 1, g = 1, b = 1 },
            alert = true,
        },
    }
    local buttons = {}
    _G.UIDropDownMenu_AddButton = function(info, level)
        table.insert(buttons, { info = info, level = level })
    end
    _G.UIDropDownMenu_CreateInfo = function()
        return {}
    end
    _G.UIDROPDOWNMENU_MENU_LEVEL = 2
    _G.UIDROPDOWNMENU_MENU_VALUE = "PersonalPlayerNotes"
    _G.UnitIsPlayer = function()
        return true
    end
    _G.UnitName = function()
        return "Jaina", nil
    end
    _G.GetRealmName = function()
        return "Theramore"
    end

    addon:UnitPopup_ShowMenu("PLAYER", "target", nil)
    check("UnitPopup_ShowMenu (submenu level) adds a title and an Edit button", #buttons, 2)
    check("UnitPopup_ShowMenu (submenu level) offers the Edit option", buttons[2].info.text, "PPN_POPUP_EDIT")
end

_G.UIDropDownMenu_AddButton = nil
_G.UIDropDownMenu_CreateInfo = nil
_G.UIDROPDOWNMENU_MENU_LEVEL = nil
_G.UIDROPDOWNMENU_MENU_VALUE = nil
_G.UnitIsPlayer = nil
_G.UnitName = nil
_G.GetRealmName = nil

-- DropDownMenuInitialize: the modern Menu API dropdown. It registers a
-- per-unit-menu-tag handler via Menu.ModifyMenu(); capturing that handler
-- with a Menu stub makes the actual add/edit decision logic directly
-- callable, using fake rootDescription/contextData doubles instead of a
-- real Blizzard Menu description object.
local function freshModernMenuAddon()
    local addon = bootstrap.loadAddon()
    addon.db = {
        profile = {
            listedPlayers = {},
            listedPlayer = { id = 1, name = "", realm = "", reason = 1, description = "", color = {}, alert = true },
        },
    }
    addon.AceGUIDefaults = function()
        return { SetTitle = function() end }
    end
    return addon
end

local function newFakeRootDescription()
    local calls = {}
    local rootDescription = {
        CreateDivider = function()
            table.insert(calls, { kind = "CreateDivider" })
        end,
        CreateTitle = function(_, text)
            table.insert(calls, { kind = "CreateTitle", text = text })
        end,
        CreateButton = function(_, text, func)
            table.insert(calls, { kind = "CreateButton", text = text, func = func })
        end,
    }
    return rootDescription, calls
end

local function captureModernMenuHandlers(addon)
    local handlers = {}
    _G.Menu = {
        ModifyMenu = function(menuTag, handler)
            handlers[menuTag] = handler
        end,
    }
    addon:DropDownMenuInitialize()
    _G.Menu = nil
    return handlers
end

do
    local addon = freshModernMenuAddon()
    local handlers = captureModernMenuHandlers(addon)
    check("DropDownMenuInitialize registers the player unit menu", type(handlers["MENU_UNIT_PLAYER"]), "function")
    check(
        "DropDownMenuInitialize registers the enemy player unit menu",
        type(handlers["MENU_UNIT_ENEMY_PLAYER"]),
        "function"
    )
    check("DropDownMenuInitialize registers the friend unit menu", type(handlers["MENU_UNIT_FRIEND"]), "function")

    local rootDescription, calls = newFakeRootDescription()
    handlers["MENU_UNIT_PLAYER"](nil, rootDescription, { unit = nil })
    check("The registered handler is a no-op without a unit token", #calls, 0)
end

do
    local addon = freshModernMenuAddon()
    local handlers = captureModernMenuHandlers(addon)
    _G.UnitIsPlayer = function()
        return false
    end

    local rootDescription, calls = newFakeRootDescription()
    handlers["MENU_UNIT_PLAYER"](nil, rootDescription, { unit = "target" })
    check("The registered handler is a no-op for a non-player unit", #calls, 0)
end

do
    local addon = freshModernMenuAddon()
    local handlers = captureModernMenuHandlers(addon)
    _G.UnitIsPlayer = function()
        return true
    end
    _G.UnitName = function()
        return "Jaina", nil
    end
    _G.GetRealmName = function()
        return "Theramore"
    end

    local rootDescription, calls = newFakeRootDescription()
    handlers["MENU_UNIT_PLAYER"](nil, rootDescription, { unit = "target" })
    check("The unlisted-player menu adds a divider, title and Add button", #calls, 3)
    check("The unlisted-player menu's button offers the Add option", calls[3].text, "PPN_POPUP_ADD")

    calls[3].func()
    check("Clicking Add creates a new listed player", #addon:GetListedPlayers(), 1)
    check("Clicking Add stores the target's name", addon:GetListedPlayers()[1].name, "Jaina")
    check("Clicking Add syncs the listedPlayer mirror's name", addon.db.profile.listedPlayer.name, "Jaina")
end

do
    local addon = freshModernMenuAddon()
    addon.db.profile.listedPlayers = {
        {
            id = 1,
            name = "Jaina",
            realm = "Theramore",
            reason = 1,
            description = "Ninja looter",
            color = { r = 1, g = 1, b = 1 },
            alert = true,
        },
    }
    local handlers = captureModernMenuHandlers(addon)
    _G.UnitIsPlayer = function()
        return true
    end
    _G.UnitName = function()
        return "Jaina", nil
    end
    _G.GetRealmName = function()
        return "Theramore"
    end

    local rootDescription, calls = newFakeRootDescription()
    handlers["MENU_UNIT_PLAYER"](nil, rootDescription, { unit = "target" })
    check("The listed-player menu adds a divider, title and Edit button", #calls, 3)
    check("The listed-player menu's button offers the Edit option", calls[3].text, "PPN_POPUP_EDIT")

    calls[3].func()
    check(
        "Clicking Edit syncs the listedPlayer mirror's description",
        addon.db.profile.listedPlayer.description,
        "Ninja looter"
    )
end

_G.UnitIsPlayer = nil
_G.UnitName = nil
_G.GetRealmName = nil

-- ToggleMiniMapIcon / ToggleDebug
do
    local addon = bootstrap.loadAddon()
    addon.db = { profile = { minimap = { hide = false }, debug = false } }
    local loadConfigCalls = 0
    addon.LoadConfig = function()
        loadConfigCalls = loadConfigCalls + 1
    end

    addon:ToggleMiniMapIcon()
    check("ToggleMiniMapIcon flips minimap.hide", addon.db.profile.minimap.hide, true)
    check("ToggleMiniMapIcon calls LoadConfig", loadConfigCalls, 1)

    addon:ToggleDebug()
    check("ToggleDebug flips debug", addon.db.profile.debug, true)
    check("ToggleDebug calls LoadConfig", loadConfigCalls, 2)
end

-- AlertDelayTimer
do
    local addon = bootstrap.loadAddon()
    addon.db = { profile = { alert = { last = { Thrall = 1234 } } } }

    addon:AlertDelayTimer("Thrall")
    check("AlertDelayTimer clears the named player's alert cooldown", addon.db.profile.alert.last["Thrall"], nil)
end

-- Client flavor detection: PersonalPlayerNotes.IsRetail is computed once, at
-- module load time, from `WOW_PROJECT_ID == WOW_PROJECT_MAINLINE`. A real
-- WoW client always defines both as numbers (Retail sets them equal, every
-- Classic flavor sets WOW_PROJECT_ID to a different constant), so reload
-- the addon under each combination to exercise this module-level logic.
do
    _G.WOW_PROJECT_MAINLINE = 1
    _G.WOW_PROJECT_ID = 1
    local retailAddon = bootstrap.loadAddon()
    check("IsRetail is true when WOW_PROJECT_ID matches WOW_PROJECT_MAINLINE", retailAddon.IsRetail, true)
end

do
    _G.WOW_PROJECT_MAINLINE = 1
    _G.WOW_PROJECT_ID = 2 -- e.g. WOW_PROJECT_CLASSIC on a Classic client
    local classicAddon = bootstrap.loadAddon()
    check("IsRetail is false on a Classic client (different WOW_PROJECT_ID)", classicAddon.IsRetail, false)
end

do
    -- Neither global defined: `nil == nil` evaluates to true in Lua, so this
    -- documents that IS_RETAIL would default to true (not false) if a client
    -- ever failed to define these - which doesn't happen in practice, but is
    -- the opposite of what a "safe" default would be.
    _G.WOW_PROJECT_MAINLINE = nil
    _G.WOW_PROJECT_ID = nil
    local undefinedAddon = bootstrap.loadAddon()
    check("IsRetail is true (not false) when both globals are undefined", undefinedAddon.IsRetail, true)
end

if failures > 0 then
    print(string.format("\n%d test(s) failed.", failures))
    os.exit(1)
end

print("\nAll tests passed.")
