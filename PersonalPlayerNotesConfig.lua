local personalPlayerNotes = ...
local L = LibStub("AceLocale-3.0"):GetLocale(personalPlayerNotes, true)

--[[
    Builds the `values` table for an alert-sound-selection dropdown: every
    filename in PersonalPlayerNotes.SoundManifest (the sounds shipped with
    the addon, regenerated from Sounds/ by Tools/generate-sounds-manifest.lua
    - see Sounds/Manifest.lua), plus every filename the user has added
    themselves via AddCustomSound() (self.db.profile.alert.customSounds).
    When includeInherit is true (used by the Reasons/ListedPlayers dropdowns,
    not the global one), an extra "__inherit__" entry is prepended for "use
    the level above's sound"; Get/SetReasonSound() and
    Get/SetListedPlayerSound() map that sentinel to/from a nil `sound` field.
]]
local function AlertSoundChoices(includeInherit)
    local choices = {}
    if includeInherit then
        choices["__inherit__"] = L["PPN_SOUND_INHERIT"]
    end
    for _, file in ipairs(PersonalPlayerNotes.SoundManifest or {}) do
        choices[file] = file
    end
    for _, file in ipairs(PersonalPlayerNotes.db.profile.alert.customSounds) do
        choices[file] = file
    end
    return choices
end

PersonalPlayerNotes.defaults = {
    profile = {
        schemaVersion = PersonalPlayerNotes.SCHEMA_VERSION,
        icon = "Interface\\AddOns\\" .. personalPlayerNotes .. "\\Images\\icon.png",
        debug = false,
        minimap = { hide = false, minimapPos = 240 },
        alert = {
            delay = 10,
            enabled = true,
            -- When true, an alert only ever plays once per listed player for
            -- the whole session (cleared on /reload or profile change, see
            -- LoadConfig()); when false (default), it repeats every time
            -- `delay` seconds have passed since the last alert for them.
            sessionOnly = false,
            -- Filename (with extension) of the global alert sound, resolved
            -- from PersonalPlayerNotes.SoundManifest (see Sounds/Manifest.lua)
            -- or from the user's own customSounds below. Reasons/listedPlayers
            -- may set their own `sound` field to override this; nil there
            -- means "inherit".
            sound = "default.mp3",
            -- Filenames the user has added themselves via AddCustomSound();
            -- these show up as real entries in every sound dropdown
            -- alongside PersonalPlayerNotes.SoundManifest.
            customSounds = {},
            -- Scratch field for the "add a custom sound" text input.
            newCustomSound = "",
            last = {},
        },
        reasons = {
            { id = 1, reason = L["PPN_DEFAULT_REASON"], color = { r = 1, g = 1, b = 1 }, alert = false },
        },
        reason = { id = 1, reason = L["PPN_DEFAULT_REASON"], color = { r = 1, g = 1, b = 1 }, alert = false },
        listedPlayer = {
            id = 1,
            name = L["PPN_LISTED_PLAYERS_EXAMPLE_NAME"],
            realm = L["PPN_LISTED_PLAYERS_EXAMPLE_REALM"],
            reason = 1,
            description = L["PPN_DEFAULT_REASON"],
            color = { r = 1, g = 1, b = 1 },
            alert = true,
        },
        listedPlayers = {
            {
                id = 1,
                name = L["PPN_LISTED_PLAYERS_EXAMPLE_NAME"],
                realm = L["PPN_LISTED_PLAYERS_EXAMPLE_REALM"],
                reason = 1,
                description = L["PPN_DEFAULT_REASON"],
                color = { r = 1, g = 1, b = 1 },
                alert = true,
            },
        },
    },
}

-- https://www.wowace.com/projects/ace3/pages/ace-config-3-0-options-tables
PersonalPlayerNotes.options = {
    Info = {
        type = "group",
        order = 0,
        name = L["PPN_MENU_TITLE"],
        inline = true,
        cmdHidden = true,
        args = {
            Notes = {
                order = 1,
                type = "description",
                fontSize = "medium",
                name = PersonalPlayerNotes:GetNotes() .. "\n\n\n",
            },
            Commands = {
                name = L["PPN_INFO_COMMANDS_TITLE"],
                desc = L["PPN_INFO_COMMANDS_DESC"],
                order = 2,
                type = "group",
                inline = true,
                args = {
                    info = {
                        order = 1,
                        type = "description",
                        fontSize = "medium",
                        name = L["PPN_INFO_COMMANDS_1"],
                    },
                    options = {
                        order = 2,
                        type = "description",
                        fontSize = "medium",
                        name = L["PPN_INFO_COMMANDS_2"],
                    },
                    reasons = {
                        order = 3,
                        type = "description",
                        fontSize = "medium",
                        name = L["PPN_INFO_COMMANDS_3"],
                    },
                    players = {
                        order = 4,
                        type = "description",
                        fontSize = "medium",
                        name = L["PPN_INFO_COMMANDS_4"],
                    },
                    minimap = {
                        order = 5,
                        type = "description",
                        fontSize = "medium",
                        name = L["PPN_INFO_COMMANDS_5"],
                    },
                },
            },
            About = {
                name = L["PPN_INFO_ABOUT_TITLE"],
                order = 3,
                type = "group",
                inline = true,
                args = {
                    version = {
                        type = "description",
                        order = 0,
                        width = "full",
                        fontSize = "medium",
                        name = "|cffffd700"
                            .. L["PPN_INFO_ABOUT_VERSION"]
                            .. ": |cffff8c00"
                            .. PersonalPlayerNotes:GetVersion(),
                    },
                    author = {
                        type = "description",
                        order = 1,
                        width = "full",
                        fontSize = "medium",
                        name = "|cffffd700"
                            .. L["PPN_INFO_ABOUT_AUTHOR"]
                            .. ": |cffffffff"
                            .. PersonalPlayerNotes:GetAuthor(),
                    },
                    category = {
                        type = "description",
                        order = 2,
                        width = "full",
                        fontSize = "medium",
                        name = "|cffffd700"
                            .. L["PPN_INFO_ABOUT_CATEGORY"]
                            .. ": |cffffffff"
                            .. PersonalPlayerNotes:GetCategory(),
                    },
                    localizations = {
                        type = "description",
                        order = 3,
                        width = "full",
                        fontSize = "medium",
                        name = "|cffffd700"
                            .. L["PPN_INFO_ABOUT_LOCALIZATION"]
                            .. ": |cffffffff"
                            .. PersonalPlayerNotes:GetLocalizations(),
                    },
                    license = {
                        type = "description",
                        order = 4,
                        width = "full",
                        fontSize = "medium",
                        name = "|cffffd700"
                            .. L["PPN_INFO_ABOUT_LICENSE"]
                            .. ": |cffffffff"
                            .. PersonalPlayerNotes:GetLicense(),
                    },
                    website = {
                        type = "description",
                        order = 5,
                        width = "full",
                        fontSize = "medium",
                        name = "|cffffd700"
                            .. L["PPN_INFO_ABOUT_WEB"]
                            .. ": |cffffffff"
                            .. PersonalPlayerNotes:GetWebsite(),
                    },
                },
            },
        },
    },
    Settings = {
        type = "group",
        order = 1,
        name = L["PPN_SETTINGS_TITLE"],
        inline = true,
        childGroups = "tab",
        handler = PersonalPlayerNotes,
        args = {
            minimap = {
                name = L["PPN_SETTINGS_MINIMAP"],
                order = 1,
                type = "group",
                inline = true,
                args = {
                    minimapToggle = {
                        type = "toggle",
                        order = 0,
                        name = L["PPN_SETTINGS_MINIMAP_ICON"],
                        desc = L["PPN_SETTINGS_MINIMAP_ICON_DESC"],
                        get = function(info)
                            return PersonalPlayerNotes.db.profile.minimap.hide
                        end,
                        set = function(info, value)
                            PersonalPlayerNotes.db.profile.minimap.hide = value
                            PersonalPlayerNotes:LoadConfig()
                        end,
                    },
                    minimapPos = {
                        type = "range",
                        order = 1,
                        name = L["PPN_SETTINGS_MINIMAP_POS"],
                        desc = L["PPN_SETTINGS_MINIMAP_POS_DESC"],
                        width = 1.5,
                        get = function(info)
                            return PersonalPlayerNotes.db.profile.minimap.minimapPos
                        end,
                        set = function(info, value)
                            PersonalPlayerNotes.db.profile.minimap.minimapPos = value
                            PersonalPlayerNotes:LoadConfig()
                        end,
                        min = 0,
                        max = 360,
                        step = 1,
                    },
                },
            },
            alert = {
                name = L["PPN_SETTINGS_ALERT"],
                order = 3,
                type = "group",
                inline = true,
                width = 0.5,
                get = "GetAlert",
                set = "SetAlert",
                args = {
                    description = {
                        type = "description",
                        order = 0,
                        name = L["PPN_SETTINGS_ALERT_DESC"],
                    },
                    -- AceConfigDialog wraps widgets onto a new row purely based on
                    -- each widget's pixel width vs. the container's actual pixel
                    -- width (see width_multiplier in AceConfigDialog-3.0.lua) - that
                    -- differs between the Blizzard options panel (wide) and the
                    -- standalone AceGUI window (narrower), so plain sibling widgets
                    -- would wrap onto different rows depending on which one is open.
                    -- Nesting each intended row in its own unnamed inline group
                    -- (renders as a plain, borderless SimpleGroup - see
                    -- AceConfigDialog-3.0.lua's FeedOptions) forces a hard row break
                    -- around it regardless of the container's width.
                    row1 = {
                        type = "group",
                        inline = true,
                        name = "",
                        order = 1,
                        args = {
                            enabled = {
                                type = "toggle",
                                order = 1,
                                name = L["PPN_SETTINGS_ALERT_ENABLED"],
                                desc = L["PPN_SETTINGS_ALERT_ENABLED_DESC"],
                                width = 0.5,
                            },
                            sounds = {
                                type = "select",
                                order = 2,
                                name = L["PPN_SETTINGS_ALERT_SOUNDS"],
                                desc = L["PPN_SETTINGS_ALERT_SOUNDS_DESC"],
                                values = function()
                                    return AlertSoundChoices(false)
                                end,
                                width = 1,
                                set = "SetAlertSoundEffect",
                                get = "GetAlertSoundEffect",
                            },
                            testSound = {
                                type = "execute",
                                order = 3,
                                name = L["PPN_SOUND_TEST"],
                                desc = L["PPN_SOUND_TEST_DESC"],
                                width = 0.5,
                                func = "TestAlertSound",
                            },
                        },
                    },
                    row2 = {
                        type = "group",
                        inline = true,
                        name = "",
                        order = 2,
                        args = {
                            newCustomSound = {
                                type = "input",
                                order = 1,
                                name = L["PPN_SETTINGS_ALERT_CUSTOM_SOUND"],
                                desc = L["PPN_SETTINGS_ALERT_CUSTOM_SOUND_DESC"],
                                width = 1.5,
                                get = function(info)
                                    local sound = PersonalPlayerNotes.db.profile.alert.sound
                                    if PersonalPlayerNotes:IsCustomSound(sound) then
                                        return sound
                                    end
                                    return PersonalPlayerNotes.db.profile.alert.newCustomSound
                                end,
                                set = function(info, value)
                                    PersonalPlayerNotes.db.profile.alert.newCustomSound = value
                                    PersonalPlayerNotes:AddCustomSound()
                                end,
                            },
                            removeCustomSound = {
                                type = "execute",
                                order = 2,
                                name = L["PPN_SOUND_REMOVE_CUSTOM"],
                                desc = L["PPN_SOUND_REMOVE_CUSTOM_DESC"],
                                width = 0.5,
                                func = "RemoveCustomSound",
                                disabled = function()
                                    return not PersonalPlayerNotes:IsCustomSound(
                                        PersonalPlayerNotes.db.profile.alert.sound
                                    )
                                end,
                            },
                        },
                    },
                    row3 = {
                        type = "group",
                        inline = true,
                        name = "",
                        order = 3,
                        args = {
                            delay = {
                                type = "range",
                                order = 1,
                                min = 1,
                                max = 60,
                                step = 1,
                                name = L["PPN_SETTINGS_ALERT_DELAY"],
                                desc = L["PPN_SETTINGS_ALERT_DELAY_DESC"],
                                width = 1,
                                disabled = function()
                                    return PersonalPlayerNotes.db.profile.alert.sessionOnly
                                end,
                            },
                            sessionOnly = {
                                type = "toggle",
                                order = 2,
                                name = L["PPN_SETTINGS_ALERT_SESSION_ONLY"],
                                desc = L["PPN_SETTINGS_ALERT_SESSION_ONLY_DESC"],
                                width = 1,
                            },
                        },
                    },
                },
            },
        },
    },
    Reasons = {
        type = "group",
        order = 2,
        name = L["PPN_REASONS_TITLE"],
        inline = false,
        handler = PersonalPlayerNotes,
        args = {
            description = {
                type = "description",
                order = 0,
                width = "full",
                name = L["PPN_REASON_DESCRIPTION"],
            },
            id = {
                type = "select",
                order = 1,
                width = 1.6,
                name = L["PPN_REASONS"],
                values = function()
                    local _return = {}
                    for key, value in pairs(PersonalPlayerNotes.db.profile.reasons) do
                        _return[key] = value.reason
                    end
                    return _return
                end,
                get = "GetReason",
                set = "SelectedReason",
            },
            remove = {
                type = "execute",
                order = 2,
                width = 1,
                cmdHidden = true,
                name = L["PPN_REASON_REMOVE"],
                confirm = function()
                    return L["PPN_REASON_REMOVE_CONFIRMATION"]
                        .. PersonalPlayerNotes.db.profile.reason.reason
                        .. "|cffffffff?"
                end,
                func = "RemoveReason",
                disabled = function()
                    if PersonalPlayerNotes.db.profile.reason.id <= #PersonalPlayerNotes.defaults.profile.reasons then
                        return true
                    end
                    return false
                end,
            },
            reason = {
                type = "input",
                order = 3,
                name = L["PPN_REASON"],
                width = 2.6,
                get = "GetReason",
                set = "SetReason",
            },
            color = {
                type = "color",
                order = 4,
                width = 1.5,
                name = L["PPN_REASON_COLOR"],
                hasAlpha = false,
                get = "GetReasonColor",
                set = "SetReasonColor",
            },
            alert = {
                type = "toggle",
                order = 5,
                width = 1,
                name = L["PPN_REASON_ALERT_ENABLED"],
                desc = L["PPN_REASON_ALERT_ENABLED_DESC"],
                get = "GetReasonAlert",
                set = "SetReasonAlert",
            },
            sound = {
                type = "select",
                order = 6,
                width = 1.6,
                name = L["PPN_REASON_SOUND"],
                desc = L["PPN_REASON_SOUND_DESC"],
                values = function()
                    return AlertSoundChoices(true)
                end,
                get = "GetReasonSound",
                set = "SetReasonSound",
            },
            testSound = {
                type = "execute",
                order = 7,
                width = 1,
                name = L["PPN_SOUND_TEST"],
                desc = L["PPN_SOUND_TEST_DESC"],
                func = "TestReasonSound",
            },
        },
    },
    ListedPlayers = {
        type = "group",
        order = 3,
        name = L["PPN_LISTED_PLAYERS_TITLE"],
        inline = true,
        handler = PersonalPlayerNotes,
        args = {
            id = {
                type = "select",
                order = 1,
                width = 1.6,
                name = L["PPN_LISTED_PLAYERS"],
                values = function()
                    local _return = {}
                    for key, value in pairs(PersonalPlayerNotes:GetListedPlayers()) do
                        _return[key] = value.name .. "-" .. value.realm
                    end
                    return _return
                end,
                get = "GetListedPlayerSelected",
                set = "SetListedPlayerSelected",
            },
            remove = {
                type = "execute",
                order = 2,
                width = 1,
                cmdHidden = true,
                name = L["PPN_LISTED_PLAYER_REMOVE"],
                confirm = function()
                    return L["PPN_LISTED_PLAYER_REMOVE_CONFIRMATION"]
                        .. PersonalPlayerNotes.db.profile.listedPlayer.name
                        .. "-"
                        .. PersonalPlayerNotes.db.profile.listedPlayer.realm
                        .. "|cffffffff?"
                end,
                func = "RemoveListedPlayer",
            },
            name = {
                type = "input",
                order = 3,
                name = L["PPN_LISTED_PLAYER_NAME"],
                width = 1.25,
                get = "GetListedPlayerName",
                set = "SetListedPlayerName",
            },
            realm = {
                type = "input",
                order = 4,
                name = L["PPN_LISTED_PLAYER_REALM"],
                width = 1.25,
                get = "GetListedPlayerRealm",
                set = "SetListedPlayerRealm",
            },
            reason = {
                type = "select",
                order = 5,
                width = 2.6,
                name = L["PPN_LISTED_PLAYER_REASON"],
                values = function()
                    local _return = {}
                    for key, value in pairs(PersonalPlayerNotes:GetReasons()) do
                        _return[key] = value.reason
                    end
                    return _return
                end,
                get = "GetListedPlayerSelectedReason",
                set = "SetListedPlayerSelectedReason",
            },
            description = {
                type = "input",
                order = 6,
                name = L["PPN_LISTED_PLAYER_DESCRIPTION"],
                width = 2.6,
                get = "GetListedPlayerSelectedDescription",
                set = "SetListedPlayerSelectedDescription",
            },
            color = {
                type = "color",
                order = 7,
                width = 1.5,
                name = L["PPN_LISTED_PLAYER_COLOR"],
                hasAlpha = false,
                get = "GetListedPlayerColor",
                set = "SetListedPlayerColor",
            },
            alert = {
                type = "toggle",
                order = 8,
                width = 1,
                name = L["PPN_LISTED_PLAYER_ALERT_ENABLED"],
                desc = L["PPN_LISTED_PLAYER_ALERT_ENABLED_DESC"],
                get = "GetListedPlayerAlert",
                set = "SetListedPlayerAlert",
                disabled = function()
                    return not PersonalPlayerNotes.db.profile.reasons[PersonalPlayerNotes.db.profile.listedPlayer.reason].alert
                end,
            },
            sound = {
                type = "select",
                order = 9,
                width = 1.6,
                name = L["PPN_LISTED_PLAYER_SOUND"],
                desc = L["PPN_LISTED_PLAYER_SOUND_DESC"],
                values = function()
                    return AlertSoundChoices(true)
                end,
                get = "GetListedPlayerSound",
                set = "SetListedPlayerSound",
            },
            testSound = {
                type = "execute",
                order = 10,
                width = 1,
                name = L["PPN_SOUND_TEST"],
                desc = L["PPN_SOUND_TEST_DESC"],
                func = "TestListedPlayerSound",
            },
        },
    },
}

--#region Sound

--[[
    Generic AceConfig get handler for self.db.profile.alert.* fields (enabled,
    delay, ...): the option's arg name (last segment of `info`) is used as
    the field key.
]]
function PersonalPlayerNotes:GetAlert(info)
    return self.db.profile.alert[info[#info]]
end

--[[
    Generic AceConfig set handler counterpart to GetAlert().
]]
function PersonalPlayerNotes:SetAlert(info, value)
    self.db.profile.alert[info[#info]] = value
end

--[[
    Returns the filename (e.g. "default.mp3") of the currently selected
    global alert sound effect - either one shipped with the addon
    (PersonalPlayerNotes.SoundManifest) or one the user added themselves
    (self.db.profile.alert.customSounds, see AddCustomSound()).
]]
function PersonalPlayerNotes:GetAlertSoundEffect(info)
    return self.db.profile.alert.sound
end

--[[
    Selects a new global alert sound effect by filename, playing it
    immediately as a preview.
]]
function PersonalPlayerNotes:SetAlertSoundEffect(info, value)
    self:PlayAlertSoundEffect(value)
    self.db.profile.alert.sound = value
end

--[[
    Plays an alert sound effect file from this addon's Sounds/ folder.
    `effect` is a filename (with extension, shipped or custom-added), or nil
    to fall back to the currently selected global sound effect
    (GetAlertSoundEffect()). Silently does nothing if the resolved filename
    is missing/blank.
]]
function PersonalPlayerNotes:PlayAlertSoundEffect(effect, channel)
    local sound = effect or self:GetAlertSoundEffect()
    if not sound or sound == "" then
        return
    end
    PlaySoundFile("Interface\\AddOns\\" .. personalPlayerNotes .. "\\Sounds\\" .. sound, channel or "master")
end

--[[
    Returns whether `sound` (a filename) is one the user added themselves
    via AddCustomSound(), as opposed to one shipped with the addon
    (PersonalPlayerNotes.SoundManifest).
]]
function PersonalPlayerNotes:IsCustomSound(sound)
    for _, file in ipairs(self.db.profile.alert.customSounds) do
        if file == sound then
            return true
        end
    end
    return false
end

--[[
    Adds the filename currently typed into alert.newCustomSound as a new
    selectable sound - it then shows up in every sound dropdown alongside
    PersonalPlayerNotes.SoundManifest - and clears the input. Called by
    options.Settings.args.alert.args.newCustomSound's own `set` handler,
    which stores the typed value first, so this runs whenever the input is
    confirmed (Enter or its built-in accept button). No-ops for a
    blank/whitespace-only name, or one that's already available (either
    shipped or already added).
]]
function PersonalPlayerNotes:AddCustomSound()
    local name = (self.db.profile.alert.newCustomSound or ""):match("^%s*(.-)%s*$")
    self.db.profile.alert.newCustomSound = ""
    if name == "" or self:IsCustomSound(name) then
        return
    end
    for _, file in ipairs(self.SoundManifest or {}) do
        if file == name then
            return
        end
    end
    tinsert(self.db.profile.alert.customSounds, name)
end

--[[
    Removes the currently selected global sound (self.db.profile.alert.sound)
    from the custom sounds list, resetting the selection back to the default
    sound. A no-op if the current selection isn't a custom sound - see
    options.Settings.args.alert.args.removeCustomSound.disabled, which
    disables the button in that case.
]]
function PersonalPlayerNotes:RemoveCustomSound()
    local sound = self.db.profile.alert.sound
    for index, file in ipairs(self.db.profile.alert.customSounds) do
        if file == sound then
            tremove(self.db.profile.alert.customSounds, index)
            self.db.profile.alert.sound = self.defaults.profile.alert.sound
            return
        end
    end
end

--[[
    Test button handler for the global Alert sound dropdown: previews
    exactly the currently selected global sound (or custom file).
]]
function PersonalPlayerNotes:TestAlertSound()
    self:PlayAlertSoundEffect()
end

--[[
    Test button handler for a Reason's sound dropdown: previews the sound
    that would actually be used for that reason (its own override, or the
    global sound if left at "Use default").
]]
function PersonalPlayerNotes:TestReasonSound()
    self:PlayAlertSoundEffect(self.db.profile.reason.sound or self.db.profile.alert.sound)
end

--[[
    Test button handler for a Listed Player's sound dropdown: previews the
    sound that would actually be used for that player, following the same
    player > reason > global priority as the real alert (see GameTooltip()).
]]
function PersonalPlayerNotes:TestListedPlayerSound()
    local reason = self:GetReasons()[self.db.profile.listedPlayer.reason]
    self:PlayAlertSoundEffect(
        self.db.profile.listedPlayer.sound or (reason and reason.sound) or self.db.profile.alert.sound
    )
end

--#endregion

--#region Reasons

--[[
    Returns all reasons
]]
function PersonalPlayerNotes:GetReasons()
    return self.db.profile.reasons
end

function PersonalPlayerNotes:SetReasons(data)
    self.db.profile.reasons = data
end

--[[
    Returns a field of the currently selected reason mirror
    (self.db.profile.reason), keyed by the AceConfig option's arg name.
]]
function PersonalPlayerNotes:GetReason(info)
    return self.db.profile.reason[info[#info]]
end

--[[
    Writes the reason text field. If it doesn't match the currently selected
    reasons[] entry's text, a brand new reason entry is created and selected
    instead of renaming the existing one in place.
]]
function PersonalPlayerNotes:SetReason(info, value)
    self.db.profile.reason[info[#info]] = value
    if self.db.profile.reasons[self.db.profile.reason.id].reason == value then
        return
    else
        tinsert(self.db.profile.reasons, #self.db.profile.reasons + 1, {
            id = #self.db.profile.reasons + 1,
            reason = value,
            color = { r = 1, g = 1, b = 1 },
            alert = true,
        })
        self.db.profile.reason.id = #self.db.profile.reasons
        self:SelectedReason(info, self.db.profile.reason.id)
        self:GetReason(info)
    end
end

--[[
    Selects a reason by id, syncing the self.db.profile.reason mirror from
    the matching reasons[] entry. A no-op if the id doesn't exist.
]]
function PersonalPlayerNotes:SelectedReason(info, value)
    local r = self.db.profile.reasons[value]
    if not r then
        return
    end
    self.db.profile.reason[info[#info]] = value
    self.db.profile.reason.reason = r.reason
    self.db.profile.reason.color = r.color
    self.db.profile.reason.alert = r.alert
    self.db.profile.reason.sound = r.sound
end

--[[
    Removes the currently selected reason and re-selects the new last entry.
    The UI disables this action for the default (built-in) reason, see
    options.Reasons.args.remove.disabled.
]]
function PersonalPlayerNotes:RemoveReason()
    tremove(self.db.profile.reasons, self.db.profile.reason.id)
    local reasons = self:GetReasons()
    self.db.profile.reason.id = #reasons
    self.db.profile.reason.reason = reasons[#reasons].reason
    self.db.profile.reason.color = reasons[#reasons].color
    self.db.profile.reason.alert = reasons[#reasons].alert
    self.db.profile.reason.sound = reasons[#reasons].sound
    return true
end

--[[
    Returns the selected reason's r/g/b color, defaulting any missing
    channel to 1.
]]
function PersonalPlayerNotes:GetReasonColor(info)
    local c = self.db.profile.reason[info[#info]]
    return c.r or 1, c.g or 1, c.b or 1
end

--[[
    Writes the selected reason's r/g/b color, defaulting any omitted channel
    to 1.
]]
function PersonalPlayerNotes:SetReasonColor(info, r, g, b)
    local c = self.db.profile.reason[info[#info]]
    c.r, c.g, c.b = r or 1, g or 1, b or 1
end

--[[
    Returns whether the selected reason currently triggers alerts.
]]
function PersonalPlayerNotes:GetReasonAlert(info)
    return self.db.profile.reason[info[#info]]
end

--[[
    Writes the selected reason's alert flag, syncing both the reason mirror
    and its backing reasons[] entry.
]]
function PersonalPlayerNotes:SetReasonAlert(info, value)
    self.db.profile.reason[info[#info]] = value
    local reason = self:GetReasons()[self.db.profile.reason.id]
    reason.alert = value
end

--[[
    Returns the selected reason's sound override, or "__inherit__" if it
    has none set (meaning "use the global alert sound").
]]
function PersonalPlayerNotes:GetReasonSound(info)
    return self.db.profile.reason.sound or "__inherit__"
end

--[[
    Writes the selected reason's sound override ( "__inherit__" is stored as
    nil, meaning "use the global alert sound"), syncing both the reason
    mirror and its backing reasons[] entry.
]]
function PersonalPlayerNotes:SetReasonSound(info, value)
    if value == "__inherit__" then
        value = nil
    end
    self.db.profile.reason.sound = value
    local reason = self:GetReasons()[self.db.profile.reason.id]
    reason.sound = value
end

--#endregion

--#region Listed Players

--[[
    Returns all listed players.
]]
function PersonalPlayerNotes:GetListedPlayers()
    return self.db.profile.listedPlayers
end

--[[
    Return listed player data by name and realm.
]]
function PersonalPlayerNotes:GetListedPlayer(name, realm)
    for index, value in pairs(self.db.profile.listedPlayers) do
        if tostring(name) == value.name and tostring(realm) == value.realm then
            return self.db.profile.listedPlayers[index]
        end
    end
    return nil
end

--[[
    Return the current selected player data.
]]
function PersonalPlayerNotes:GetListedPlayerSelected(info)
    return self.db.profile.listedPlayer[info[#info]]
end

--[[
    Set player data by current selected player data.
]]
function PersonalPlayerNotes:SetListedPlayerSelected(info, value)
    self.db.profile.listedPlayer[info[#info]] = value
    local player = self.db.profile.listedPlayers[self.db.profile.listedPlayer.id]
    if player then
        self.db.profile.listedPlayer.id = value
        self.db.profile.listedPlayer.name = player.name
        self.db.profile.listedPlayer.realm = player.realm
        self.db.profile.listedPlayer.reason = player.reason
        self.db.profile.listedPlayer.description = player.description
        self.db.profile.listedPlayer.color = player.color
        self.db.profile.listedPlayer.alert = player.alert
        self.db.profile.listedPlayer.sound = player.sound
    end
end

function PersonalPlayerNotes:GetListedPlayerRealm(info)
    return self.db.profile.listedPlayer[info[#info]]
end

--[[
    Writes the selected player's realm field, syncing the backing
    listedPlayers[] entry in place.
]]
function PersonalPlayerNotes:SetListedPlayerRealm(info, value)
    self.db.profile.listedPlayer[info[#info]] = value
    local player = PersonalPlayerNotes:GetListedPlayers()[self.db.profile.listedPlayer.id]
    --local player = PersonalPlayerNotes:GetListedPlayer(self.db.profile.listedPlayer.name, value)
    if player then
        player.id = self.db.profile.listedPlayer.id
        player.name = self.db.profile.listedPlayer.name
        player.realm = value
        player.reason = self.db.profile.listedPlayer.reason
        player.description = self.db.profile.listedPlayer.description
        player.color = self.db.profile.listedPlayer.color
        player.alert = self.db.profile.listedPlayer.alert
        player.sound = self.db.profile.listedPlayer.sound
    end
end

function PersonalPlayerNotes:GetListedPlayerName(info)
    return self.db.profile.listedPlayer[info[#info]]
end

--[[
    Writes the selected player's name field. If no listedPlayers[] entry
    matches the new name/realm pair, a brand new player entry is created and
    selected instead of renaming the existing one in place.
]]
function PersonalPlayerNotes:SetListedPlayerName(info, value)
    self.db.profile.listedPlayer[info[#info]] = value
    --local player = PersonalPlayerNotes:GetListedPlayers()[self.db.profile.listedPlayer.id]
    local player = PersonalPlayerNotes:GetListedPlayer(value, self.db.profile.listedPlayer.realm)
    if player then
        player.id = self.db.profile.listedPlayer.id
        player.name = value
        player.realm = self.db.profile.listedPlayer.realm
        player.reason = self.db.profile.listedPlayer.reason
        player.description = self.db.profile.listedPlayer.description
        player.color = self.db.profile.listedPlayer.color
        player.alert = self.db.profile.listedPlayer.alert
        player.sound = self.db.profile.listedPlayer.sound
    else
        local new = PersonalPlayerNotes:NewListedPlayer(value, self.db.profile.listedPlayer.realm)
        PersonalPlayerNotes:SetListedPlayerSelected(info, new.id)
        PersonalPlayerNotes:GetListedPlayerSelected(info)
    end
end

--[[
    Removes the currently selected listed player and re-selects the new last
    entry. Unlike RemoveReason(), listedPlayers[] is allowed to become empty
    (there's no built-in/default entry to protect), so the listedPlayer
    mirror is reset to a blank placeholder instead of indexing a nil last
    entry when the list is emptied.
]]
function PersonalPlayerNotes:RemoveListedPlayer()
    tremove(self.db.profile.listedPlayers, self.db.profile.listedPlayer.id)
    local listedPlayers = self:GetListedPlayers()
    local last = listedPlayers[#listedPlayers]
    if last then
        self.db.profile.listedPlayer.id = #listedPlayers
        self.db.profile.listedPlayer.name = last.name
        self.db.profile.listedPlayer.realm = last.realm
        self.db.profile.listedPlayer.reason = last.reason
        self.db.profile.listedPlayer.description = last.description
        self.db.profile.listedPlayer.color = last.color
        self.db.profile.listedPlayer.alert = last.alert
        self.db.profile.listedPlayer.sound = last.sound
    else
        self.db.profile.listedPlayer.id = 0
        self.db.profile.listedPlayer.name = ""
        self.db.profile.listedPlayer.realm = ""
        self.db.profile.listedPlayer.reason = 1
        self.db.profile.listedPlayer.description = ""
        self.db.profile.listedPlayer.color = { r = 1, g = 1, b = 1 }
        self.db.profile.listedPlayer.alert = true
        self.db.profile.listedPlayer.sound = nil
    end
    return true
end

function PersonalPlayerNotes:GetListedPlayerSelectedReason(info)
    return self.db.profile.listedPlayer[info[#info]]
end

--[[
    Writes the selected player's reason id, syncing the backing
    listedPlayers[] entry in place.
]]
function PersonalPlayerNotes:SetListedPlayerSelectedReason(info, value)
    self.db.profile.listedPlayer[info[#info]] = value
    local player = PersonalPlayerNotes:GetListedPlayers()[self.db.profile.listedPlayer.id]
    player.reason = value
end

function PersonalPlayerNotes:GetListedPlayerSelectedDescription(info)
    return self.db.profile.listedPlayer[info[#info]]
end

--[[
    Writes the selected player's description field, syncing the backing
    listedPlayers[] entry in place.
]]
function PersonalPlayerNotes:SetListedPlayerSelectedDescription(info, value)
    self.db.profile.listedPlayer[info[#info]] = value
    local player = PersonalPlayerNotes:GetListedPlayers()[self.db.profile.listedPlayer.id]
    player.description = value
end

--[[
    Returns the selected player's r/g/b color, defaulting any missing
    channel to 1.
]]
function PersonalPlayerNotes:GetListedPlayerColor(info)
    local c = self.db.profile.listedPlayer[info[#info]]
    return c.r or 1, c.g or 1, c.b or 1
end

--[[
    Writes the selected player's r/g/b color, defaulting any omitted channel
    to 1.
]]
function PersonalPlayerNotes:SetListedPlayerColor(info, r, g, b)
    local c = self.db.profile.listedPlayer[info[#info]]
    c.r, c.g, c.b = r or 1, g or 1, b or 1
end

--[[
    Appends a new listed player entry and returns it. Any field left nil
    falls back to the current listedPlayer mirror's value (name/realm) or a
    sane default (reason 1, empty description). Does not select the new
    entry - callers sync self.db.profile.listedPlayer themselves afterward.
]]
function PersonalPlayerNotes:NewListedPlayer(name, realm, reason, description)
    self.db.profile.listedPlayer.id = #self.db.profile.listedPlayers + 1
    local newPlayer = {
        id = self.db.profile.listedPlayer.id,
        name = name or self.db.profile.listedPlayer.name,
        realm = realm or self.db.profile.listedPlayer.realm,
        reason = reason or 1,
        description = description or "",
        color = { r = 1, g = 1, b = 1 },
        alert = true,
    }
    tinsert(self.db.profile.listedPlayers, self.db.profile.listedPlayer.id, newPlayer)
    return newPlayer
end

function PersonalPlayerNotes:GetListedPlayerAlert(info)
    return self.db.profile.listedPlayer[info[#info]]
end

--[[
    Writes the selected player's alert flag, syncing the backing
    listedPlayers[] entry in place.
]]
function PersonalPlayerNotes:SetListedPlayerAlert(info, value)
    self.db.profile.listedPlayer[info[#info]] = value
    local player = PersonalPlayerNotes:GetListedPlayers()[self.db.profile.listedPlayer.id]
    player.alert = value
end

--[[
    Returns the selected player's sound override, or "__inherit__" if it has
    none set (meaning "use the reason's sound, or the global one").
]]
function PersonalPlayerNotes:GetListedPlayerSound(info)
    return self.db.profile.listedPlayer.sound or "__inherit__"
end

--[[
    Writes the selected player's sound override ("__inherit__" is stored as
    nil, meaning "use the reason's sound, or the global one"), syncing both
    the listedPlayer mirror and its backing listedPlayers[] entry.
]]
function PersonalPlayerNotes:SetListedPlayerSound(info, value)
    if value == "__inherit__" then
        value = nil
    end
    self.db.profile.listedPlayer.sound = value
    local player = PersonalPlayerNotes:GetListedPlayers()[self.db.profile.listedPlayer.id]
    player.sound = value
end

--#endregion
