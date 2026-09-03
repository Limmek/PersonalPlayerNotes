local personalPlayerNotes = ...
local L = LibStub("AceLocale-3.0"):GetLocale(personalPlayerNotes, true)
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)

--[[
    Builds the `values` table for an alert-sound-selection dropdown: every
    filename in PersonalPlayerNotes.SoundManifest (the sounds shipped with
    the addon, regenerated from Sounds/ by Tools/generate-sounds-manifest.lua
    - see SoundsManifest.lua), plus every filename the user has added
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

local function NormalizeIconValue(value)
    if value == nil then
        return nil
    end

    local icon = tostring(value):match("^%s*(.-)%s*$")
    if icon == "" then
        return nil
    end

    -- Keep tooltip texture tags safe by only storing a raw file path or fileID.
    if icon:find("|", 1, true) then
        return nil
    end

    local iconFileId = tonumber(icon)
    if iconFileId then
        if iconFileId <= 0 then
            return nil
        end
        return tostring(math.floor(iconFileId))
    end

    return icon
end

local function IconButtonTexture(icon)
    return icon or "Interface\\Buttons\\UI-EmptySlot-Disabled"
end

--[[
    Builds the full texture path for a custom icon filename the user has
    added themselves via AddCustomIcon() (self.db.profile.customIcons) - the
    file itself must be manually dropped into this addon's Images/ folder
    by the user, since the sandboxed WoW client can't list a directory at
    runtime to discover it on its own (same constraint as custom alert
    sounds, see AlertSoundChoices() above).
]]
local function CustomIconTexture(filename)
    return "Interface\\AddOns\\" .. personalPlayerNotes .. "\\Images\\" .. filename
end

local function NotifyIconOptionsChanged()
    if AceConfigRegistry then
        AceConfigRegistry:NotifyChange("PersonalPlayerNotesSettings Reasons")
        AceConfigRegistry:NotifyChange("PersonalPlayerNotesSettings Listed_Players")
    end
    -- AceConfigRegistry:NotifyChange() only auto-refreshes dialogs
    -- AceConfigDialog opened itself; ours are opened via OpenDialog() with
    -- a custom container, which that mechanism can't see - see
    -- RefreshDialog()'s comment in PersonalPlayerNotesUtils.lua.
    PersonalPlayerNotes:RefreshDialog("PersonalPlayerNotesSettings Reasons")
    PersonalPlayerNotes:RefreshDialog("PersonalPlayerNotesSettings Listed_Players")
end

local function CollectAvailableIcons()
    local icons = {}
    local seen = {}

    local function Add(icon)
        if icon and icon ~= "" and not seen[icon] then
            icons[#icons + 1] = icon
            seen[icon] = true
        end
    end

    -- User-added custom icons (see AddCustomIcon()) come first, ahead of
    -- the game's own macro icons, so they're easy to find in the picker.
    for _, file in ipairs(PersonalPlayerNotes.db.profile.customIcons) do
        Add(CustomIconTexture(file))
    end

    if type(GetNumMacroIcons) == "function" and type(GetMacroIconInfo) == "function" then
        local count = GetNumMacroIcons() or 0
        for index = 1, count do
            Add(GetMacroIconInfo(index))
        end
    end

    if type(GetMacroIcons) == "function" then
        local macroIcons = {}
        GetMacroIcons(macroIcons)
        for _, icon in ipairs(macroIcons) do
            Add(icon)
        end
    end

    if type(GetMacroItemIcons) == "function" then
        local macroItemIcons = {}
        GetMacroItemIcons(macroItemIcons)
        for _, icon in ipairs(macroItemIcons) do
            Add(icon)
        end
    end

    if type(GetLooseMacroIcons) == "function" then
        local loose = {}
        GetLooseMacroIcons(loose)
        for _, icon in ipairs(loose) do
            Add(icon)
        end
    end

    if type(GetLooseMacroItemIcons) == "function" then
        local looseItems = {}
        GetLooseMacroItemIcons(looseItems)
        for _, icon in ipairs(looseItems) do
            Add(icon)
        end
    end

    return icons
end

--[[
    Registers "PPNIconLabel", a small custom AceGUI widget used for the
    Reasons/Listed Players "Icon" option below (dialogControl). It's just
    AceGUI's own "InteractiveLabel" (a bare clickable label with no button
    skin/border - see OpenIconPicker's comment for why that's used instead
    of the default "Button" widget) with its font swapped from Label's
    default GameFontHighlightSmall to GameFontHighlight, matching the font
    AceGUI's ColorPicker/CheckBox widgets use for their own label text
    ("Select a color"/"Alert") - without this, "Icon" rendered visibly
    smaller than the color/alert labels right next to it.
]]
do
    local AceGUI = LibStub("AceGUI-3.0")
    local Type = "PPNIconLabel"
    local function Constructor()
        local widget = AceGUI:Create("InteractiveLabel")
        widget.type = Type
        -- InteractiveLabel's OnAcquire (Label's own OnAcquire, called via
        -- AceGUI:Create() above) resets the font to GameFontHighlightSmall
        -- on every acquire (including pooled reuse), so the font override
        -- has to happen *inside* OnAcquire, not just once here.
        local baseOnAcquire = widget.OnAcquire
        widget.OnAcquire = function(self)
            baseOnAcquire(self)
            self:SetFontObject(GameFontHighlight)
        end
        return widget
    end
    AceGUI:RegisterWidgetType(Type, Constructor, 1)
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
            -- from PersonalPlayerNotes.SoundManifest (see SoundsManifest.lua)
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
        -- Filenames the user has added themselves via AddCustomIcon() (see
        -- Settings.args.icons below) - the actual image files must be
        -- dropped into this addon's Images/ folder manually by the user
        -- (the same folder the addon's own icon.png ships in), the same
        -- way custom alert sounds work (see alert.customSounds above).
        -- Kept at the profile's top level (not nested under `alert`, and
        -- not under Reasons/Listed Players) since icons are a shared
        -- resource selectable from both, managed from its own settings
        -- panel instead of bloating either editor form.
        customIcons = {},
        -- Scratch field for the "add a custom icon" text input.
        newCustomIcon = "",
        -- Scratch field: which customIcons[] entry is selected in the Custom
        -- Icons panel's list, i.e. the target for the Remove button there.
        customIconSelected = "",
        reasons = {
            { id = 1, reason = L["PPN_DEFAULT_REASON"], color = { r = 1, g = 1, b = 1 }, alert = false, icon = nil },
        },
        reason = {
            id = 1,
            reason = L["PPN_DEFAULT_REASON"],
            color = { r = 1, g = 1, b = 1 },
            alert = false,
            icon = nil,
        },
        listedPlayer = {
            id = 1,
            name = L["PPN_LISTED_PLAYERS_EXAMPLE_NAME"],
            realm = L["PPN_LISTED_PLAYERS_EXAMPLE_REALM"],
            reason = 1,
            description = L["PPN_DEFAULT_REASON"],
            color = { r = 1, g = 1, b = 1 },
            alert = true,
            icon = nil,
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
                icon = nil,
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
                    changelog = {
                        order = 6,
                        type = "description",
                        fontSize = "medium",
                        name = L["PPN_INFO_COMMANDS_6"],
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
            Changelog = {
                name = L["PPN_MENU_CHANGELOG"],
                order = 4,
                type = "group",
                inline = true,
                args = {
                    text = {
                        type = "description",
                        order = 0,
                        width = "full",
                        fontSize = "medium",
                        name = function()
                            return (PersonalPlayerNotes.Changelog or "") .. "\n"
                        end,
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
            -- A dedicated panel for managing custom icons (add/remove),
            -- kept separate from Reasons/Listed Players so those editor
            -- forms don't get bloated with icon-management widgets - they
            -- only ever show the "Icon" button that opens OpenIconPicker().
            icons = {
                name = L["PPN_SETTINGS_ICONS"],
                order = 4,
                type = "group",
                inline = true,
                width = 0.5,
                args = {
                    description = {
                        type = "description",
                        order = 0,
                        name = L["PPN_SETTINGS_ICONS_DESC"],
                    },
                    row1 = {
                        type = "group",
                        inline = true,
                        name = "",
                        order = 1,
                        args = {
                            newCustomIcon = {
                                type = "input",
                                order = 1,
                                name = L["PPN_SETTINGS_ICON_ADD"],
                                desc = L["PPN_SETTINGS_ICON_ADD_DESC"],
                                width = 1.5,
                                get = function(info)
                                    return PersonalPlayerNotes.db.profile.newCustomIcon
                                end,
                                set = function(info, value)
                                    PersonalPlayerNotes.db.profile.newCustomIcon = value
                                    PersonalPlayerNotes:AddCustomIcon()
                                end,
                            },
                        },
                    },
                    row2 = {
                        type = "group",
                        inline = true,
                        name = "",
                        order = 2,
                        args = {
                            customIconSelected = {
                                type = "select",
                                order = 1,
                                name = L["PPN_SETTINGS_ICON_SELECT"],
                                width = 1.5,
                                values = function()
                                    local choices = {}
                                    for _, file in ipairs(PersonalPlayerNotes.db.profile.customIcons) do
                                        choices[file] = file
                                    end
                                    return choices
                                end,
                                get = function(info)
                                    return PersonalPlayerNotes.db.profile.customIconSelected
                                end,
                                set = function(info, value)
                                    PersonalPlayerNotes.db.profile.customIconSelected = value
                                end,
                                disabled = function()
                                    return #PersonalPlayerNotes.db.profile.customIcons == 0
                                end,
                            },
                            removeCustomIcon = {
                                type = "execute",
                                order = 2,
                                name = L["PPN_ICON_REMOVE_CUSTOM"],
                                desc = L["PPN_ICON_REMOVE_CUSTOM_DESC"],
                                width = 0.5,
                                func = "RemoveCustomIcon",
                                disabled = function()
                                    return not PersonalPlayerNotes:IsCustomIcon(
                                        PersonalPlayerNotes.db.profile.customIconSelected
                                    )
                                end,
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
            -- AceConfigDialog wraps widgets onto a new row purely based on
            -- each widget's pixel width vs. the container's actual pixel
            -- width (see width_multiplier in AceConfigDialog-3.0.lua) - that
            -- differs between the Blizzard options panel (wide) and the
            -- standalone AceGUI window (narrower). Nesting the icon/color/
            -- alert trio in its own unnamed inline group (renders as a
            -- plain, borderless SimpleGroup - see FeedOptions() in
            -- AceConfigDialog-3.0.lua) forces them onto a single hard row
            -- regardless of the container's width (same trick used by
            -- Settings.args.alert.args.row1/row2/row3 above).
            iconColorAlert = {
                type = "group",
                inline = true,
                name = "",
                order = 4,
                args = {
                    icon = {
                        type = "execute",
                        order = 1,
                        width = 0.5,
                        -- Renders as a plain clickable label (icon glyph +
                        -- text, no button skin/border) instead of AceGUI's
                        -- default "Button" widget, so it visually matches
                        -- the Color swatch+text control right next to it.
                        dialogControl = "PPNIconLabel",
                        name = function(info)
                            return "|T"
                                .. PersonalPlayerNotes:GetReasonIconTexture(info)
                                .. ":18|t "
                                .. L["PPN_REASON_ICON"]
                        end,
                        desc = L["PPN_REASON_ICON_DESC"],
                        func = "OpenReasonIconPicker",
                    },
                    color = {
                        type = "color",
                        order = 2,
                        width = 1,
                        name = L["PPN_REASON_COLOR"],
                        hasAlpha = false,
                        get = "GetReasonColor",
                        set = "SetReasonColor",
                    },
                    alert = {
                        type = "toggle",
                        order = 3,
                        width = 1,
                        name = L["PPN_REASON_ALERT_ENABLED"],
                        desc = L["PPN_REASON_ALERT_ENABLED_DESC"],
                        get = "GetReasonAlert",
                        set = "SetReasonAlert",
                    },
                },
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
            -- See the identical comment above Reasons.args.iconColorAlert:
            -- nesting icon/color/alert in their own unnamed inline group
            -- forces them onto a single hard row regardless of container width.
            iconColorAlert = {
                type = "group",
                inline = true,
                name = "",
                order = 7,
                args = {
                    icon = {
                        type = "execute",
                        order = 1,
                        width = 0.5,
                        -- Renders as a plain clickable label (icon glyph +
                        -- text, no button skin/border) instead of AceGUI's
                        -- default "Button" widget, so it visually matches
                        -- the Color swatch+text control right next to it.
                        dialogControl = "PPNIconLabel",
                        name = function(info)
                            return "|T"
                                .. PersonalPlayerNotes:GetListedPlayerIconTexture(info)
                                .. ":18|t "
                                .. L["PPN_LISTED_PLAYER_ICON"]
                        end,
                        desc = L["PPN_LISTED_PLAYER_ICON_DESC"],
                        func = "OpenListedPlayerIconPicker",
                    },
                    color = {
                        type = "color",
                        order = 2,
                        width = 1,
                        name = L["PPN_LISTED_PLAYER_COLOR"],
                        hasAlpha = false,
                        get = "GetListedPlayerColor",
                        set = "SetListedPlayerColor",
                    },
                    alert = {
                        type = "toggle",
                        order = 3,
                        width = 1,
                        name = L["PPN_LISTED_PLAYER_ALERT_ENABLED"],
                        desc = L["PPN_LISTED_PLAYER_ALERT_ENABLED_DESC"],
                        get = "GetListedPlayerAlert",
                        set = "SetListedPlayerAlert",
                        disabled = function()
                            return not PersonalPlayerNotes.db.profile.reasons[PersonalPlayerNotes.db.profile.listedPlayer.reason].alert
                        end,
                    },
                },
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

--#region Custom Icons

--[[
    Returns whether `icon` (a bare filename, e.g. "myicon.png") is one the
    user added themselves via AddCustomIcon().
]]
function PersonalPlayerNotes:IsCustomIcon(icon)
    for _, file in ipairs(self.db.profile.customIcons) do
        if file == icon then
            return true
        end
    end
    return false
end

--[[
    Adds the filename currently typed into customIcons.newCustomIcon as a
    new selectable custom icon - it then shows up in the icon picker's grid
    (see CollectAvailableIcons()) as "Interface\AddOns\...\Images\<filename>",
    and becomes the Custom Icons panel's selected entry - and clears the
    input. No-ops for a blank/whitespace-only name, or one already added.
]]
function PersonalPlayerNotes:AddCustomIcon()
    local name = (self.db.profile.newCustomIcon or ""):match("^%s*(.-)%s*$")
    self.db.profile.newCustomIcon = ""
    if name == "" or self:IsCustomIcon(name) then
        return
    end
    tinsert(self.db.profile.customIcons, name)
    self.db.profile.customIconSelected = name
end

--[[
    Removes the Custom Icons panel's currently selected custom icon
    (self.db.profile.customIconSelected), re-selecting the new last entry
    (or blank if the list is now empty). A no-op if nothing is selected -
    see options.Settings.args.icons.args.row2.args.removeCustomIcon.disabled,
    which disables the button in that case. Reasons/Listed Players that
    already had this icon selected keep it - it just stops being
    selectable/re-addable from the picker until re-added here.
]]
function PersonalPlayerNotes:RemoveCustomIcon()
    local selected = self.db.profile.customIconSelected
    for index, file in ipairs(self.db.profile.customIcons) do
        if file == selected then
            tremove(self.db.profile.customIcons, index)
            local remaining = self.db.profile.customIcons
            self.db.profile.customIconSelected = remaining[#remaining] or ""
            return
        end
    end
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
    self.db.profile.reason.icon = r.icon
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
    self.db.profile.reason.icon = reasons[#reasons].icon
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

function PersonalPlayerNotes:GetReasonIcon(info)
    return self.db.profile.reason.icon or ""
end

function PersonalPlayerNotes:GetReasonIconTexture(info)
    return IconButtonTexture(self.db.profile.reason.icon)
end

function PersonalPlayerNotes:SetReasonIcon(info, value)
    local icon = NormalizeIconValue(value)
    self.db.profile.reason.icon = icon
    local reason = self:GetReasons()[self.db.profile.reason.id]
    reason.icon = icon
    NotifyIconOptionsChanged()
end

function PersonalPlayerNotes:OpenReasonIconPicker()
    self:OpenIconPicker(self.db.profile.reason.icon, function(selectedIcon)
        self:SetReasonIcon(nil, selectedIcon)
    end)
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
        self.db.profile.listedPlayer.icon = player.icon
    end
end

--[[
    Copies every field of the currently selected listedPlayer mirror
    (self.db.profile.listedPlayer) onto a listedPlayers[] entry - shared by
    SetListedPlayerRealm() and SetListedPlayerName(), which each write a
    single field to the mirror first, then need every other mirror field
    re-synced onto the backing entry in place.
]]
local function CopyListedPlayerMirrorToEntry(self, player)
    local mirror = self.db.profile.listedPlayer
    player.id = mirror.id
    player.name = mirror.name
    player.realm = mirror.realm
    player.reason = mirror.reason
    player.description = mirror.description
    player.color = mirror.color
    player.alert = mirror.alert
    player.sound = mirror.sound
    player.icon = mirror.icon
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
    if player then
        CopyListedPlayerMirrorToEntry(self, player)
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
    local player = PersonalPlayerNotes:GetListedPlayer(value, self.db.profile.listedPlayer.realm)
    if player then
        CopyListedPlayerMirrorToEntry(self, player)
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
        self.db.profile.listedPlayer.icon = last.icon
    else
        self.db.profile.listedPlayer.id = 0
        self.db.profile.listedPlayer.name = ""
        self.db.profile.listedPlayer.realm = ""
        self.db.profile.listedPlayer.reason = 1
        self.db.profile.listedPlayer.description = ""
        self.db.profile.listedPlayer.color = { r = 1, g = 1, b = 1 }
        self.db.profile.listedPlayer.alert = true
        self.db.profile.listedPlayer.sound = nil
        self.db.profile.listedPlayer.icon = nil
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
        sound = nil,
        icon = nil,
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

function PersonalPlayerNotes:GetListedPlayerIcon(info)
    return self.db.profile.listedPlayer.icon or ""
end

function PersonalPlayerNotes:GetListedPlayerIconTexture(info)
    return IconButtonTexture(self.db.profile.listedPlayer.icon)
end

function PersonalPlayerNotes:SetListedPlayerIcon(info, value)
    local icon = NormalizeIconValue(value)
    self.db.profile.listedPlayer.icon = icon
    local player = PersonalPlayerNotes:GetListedPlayers()[self.db.profile.listedPlayer.id]
    if player then
        player.icon = icon
    end
    NotifyIconOptionsChanged()
end

function PersonalPlayerNotes:OpenListedPlayerIconPicker()
    self:OpenIconPicker(self.db.profile.listedPlayer.icon, function(selectedIcon)
        self:SetListedPlayerIcon(nil, selectedIcon)
    end)
end

--[[
    Builds (or rebuilds) the icon-picker popup and shows it, populated with
    every icon CollectAvailableIcons() finds, plus a "None"/"Close" button
    row below the grid. Clicking an icon or the None button calls
    `onSelect(icon)` (icon is nil for "None") and closes the popup; Close
    dismisses the popup without changing the current selection.

    Built entirely out of AceGUI-3.0 widgets - a "Frame" container (created
    via AceGUIDefaults(), the exact same helper SelectListedPlayerAndOpenDialog()
    and the minimap icon's menu use to open every other window this addon
    shows) holding a dense "Flow" grid of "Icon" widgets, styled to match
    Blizzard's own macro icon picker - so its border/background/title bar
    are pixel-identical to the addon's other AceConfigDialog windows instead
    of a hand-built CreateFrame popup.

    CollectAvailableIcons() can return several hundred macro icons, and WoW
    aborts a single Lua execution with a "script ran too long" error if it
    creates too many frames/widgets in one go (exactly what happened when
    every icon got its own AceGUI "Icon" widget in a single click handler).
    So instead of a real AceGUI "ScrollFrame" (which would need one widget
    per icon to get a real scrollbar), this builds a small FIXED pool of
    `columns * rows` "Icon" widgets once and reuses them for the picker's
    entire lifetime - a real WoW UI scrollbar (same "UIPanelScrollBarTemplate"
    AceGUI's own ScrollFrame uses) just changes which row of icons.data the
    pool currently displays, reassigning each slot's texture (SetImage)
    instead of creating/destroying widgets. This is the same "virtualized
    list" technique Blizzard's own HybridScrollFrame uses for its long
    scrolling lists.
]]
function PersonalPlayerNotes:OpenIconPicker(currentIcon, onSelect)
    if self.iconPickerFrame then
        self.iconPickerFrame:Release()
        self.iconPickerFrame = nil
    end

    local AceGUI = LibStub("AceGUI-3.0")
    local selectedIcon = NormalizeIconValue(currentIcon)

    local icons = CollectAvailableIcons()

    -- Sized so the pool's tiles (40x38 each, see below) fill the picker's
    -- content area with as little unused space as possible, while still
    -- leaving enough room below the grid for the None/Close button row
    -- without it (or the button row) overlapping the frame's own built-in
    -- bottom-right Close button.
    local columns = 8
    local rows = 8
    local poolSize = columns * rows
    local totalRows = math.max(1, math.ceil(#icons / columns))
    local maxTopRow = math.max(0, totalRows - rows)

    -- Always open scrolled to the very top, never auto-jump to the row
    -- containing the current selection - custom icons (see
    -- CollectAvailableIcons()) are always placed first in `icons`, so this
    -- guarantees they're always the first thing shown, on every open,
    -- regardless of what's currently selected.
    local topRow = 0

    local picker = self:AceGUIDefaults()
    picker:SetTitle(L["PPN_ICON_PICKER_TITLE"])
    picker:SetWidth(400)
    picker:SetHeight(405)
    picker:SetLayout("List")
    -- Fixed-size popup (like Blizzard's own macro icon picker) - letting it
    -- be resized just introduces dead space around the fixed-size pool of
    -- icon tiles below, since they don't reflow to fill a bigger window.
    picker:EnableResize(false)

    -- Every AceGUI "Frame" always builds its own bottom-right Close button
    -- (see AceGUIContainer-Frame.lua's Constructor) and there's no public
    -- method to remove or hide it, since it isn't stored anywhere on the
    -- widget table. With our own None/Close row now below the grid, that
    -- built-in button is redundant and, no matter how much clearance is
    -- left above it, still visibly peeks out at the bottom of the fixed-
    -- size popup. Find it directly (the only "Button"-type direct child of
    -- the frame with the localized CLOSE text) and hide it, restoring it
    -- on close/release so the SAME pooled widget object still shows its
    -- Close button normally if AceGUI later reuses it for a different
    -- "Frame" (e.g. the Reasons/Listed Players dialogs via OpenDialog()).
    local builtinCloseButton
    for _, child in ipairs({ picker.frame:GetChildren() }) do
        if child.GetObjectType and child:GetObjectType() == "Button" and child.GetText and child:GetText() == CLOSE then
            builtinCloseButton = child
            break
        end
    end
    if builtinCloseButton then
        builtinCloseButton:Hide()
    end

    -- Forward-declared so the OnClose handler below (registered before
    -- either of these is actually created) can reach them via closure -
    -- see the handler's own comment for why they need cleaning up here.
    local scrollbar
    local pool = {}

    -- AceGUIDefaults() wires a default OnClose that just Releases the
    -- widget; override it here so self.iconPickerFrame is always cleared
    -- when the frame closes, no matter how it closes (X button, Hide(),
    -- or SelectIcon() below). Without this, closing via the X button left
    -- self.iconPickerFrame pointing at an already-released/pooled widget,
    -- and the guard-clause above would then try to Release it a second
    -- time, triggering "Attempt to Release Widget that is already
    -- released".
    picker:SetCallback("OnClose", function(widget)
        if self.iconPickerFrame == widget then
            self.iconPickerFrame = nil
        end
        if builtinCloseButton then
            builtinCloseButton:Show()
        end
        -- `scrollbar` (+ its scrollbg texture child) and every pooled
        -- icon's `selectedBorder` are plain CreateFrame() frames, not
        -- AceGUI widgets - AceGUI:Release() (triggered by widget:Release()
        -- below) only knows how to reset/reparent the AceGUI widgets
        -- themselves (this Frame, its "SimpleGroup" viewport, the pooled
        -- "Icon" widgets), not arbitrary raw frames we parented onto them.
        -- Those widgets go back into AceGUI's shared per-type pools and can
        -- get handed to a COMPLETELY different dialog next - without this,
        -- the leftover scrollbar/selectedBorder frames (still parented to,
        -- and positioned relative to, the recycled widget's frame) would
        -- silently reappear as stray artifacts in that other dialog.
        -- Reparenting them to UIParent and hiding them fully detaches them
        -- so they never tag along with a reused widget again.
        if scrollbar then
            scrollbar:ClearAllPoints()
            scrollbar:SetParent(UIParent)
            scrollbar:Hide()
        end
        for _, iconWidget in ipairs(pool) do
            local selectedBorder = iconWidget.selectedBorder
            if selectedBorder then
                selectedBorder:ClearAllPoints()
                selectedBorder:SetParent(UIParent)
                selectedBorder:Hide()
            end
        end
        widget:Release()
    end)
    self.iconPickerFrame = picker

    local function SelectIcon(icon)
        if onSelect then
            onSelect(icon)
        end
        picker:Hide()
    end

    local viewport = AceGUI:Create("SimpleGroup")
    viewport:SetLayout("Flow")
    viewport:SetWidth(325)
    viewport:SetHeight(304)
    picker:AddChild(viewport)

    -- A dedicated button row instead of folding "None" into the grid as a
    -- blank first tile: the picker frame always has its own built-in
    -- bottom-right Close button (see AceGUIContainer-Frame.lua), and a
    -- fixed-size grid tall enough to fill the window ended up rendering
    -- underneath it. Explicit buttons here stay safely above that area.
    local buttonRow = AceGUI:Create("SimpleGroup")
    buttonRow:SetLayout("Flow")
    buttonRow:SetWidth(325)
    buttonRow:SetHeight(24)
    picker:AddChild(buttonRow)

    local noneButton = AceGUI:Create("Button")
    noneButton:SetText(L["PPN_ICON_PICKER_NONE"])
    noneButton:SetWidth(160)
    noneButton:SetCallback("OnClick", function()
        SelectIcon(nil)
    end)
    buttonRow:AddChild(noneButton)

    local closeButton = AceGUI:Create("Button")
    closeButton:SetText(CLOSE)
    closeButton:SetWidth(160)
    closeButton:SetCallback("OnClick", function()
        picker:Hide()
    end)
    buttonRow:AddChild(closeButton)

    -- Real WoW UI scrollbar, styled/positioned exactly like the one AceGUI's
    -- own "ScrollFrame" container builds, so it's pixel-consistent with the
    -- rest of the addon's Ace3-based windows. It scrolls the pool one row
    -- at a time - the pool's widgets never move, only their contents do.
    scrollbar = CreateFrame("Slider", nil, viewport.frame, "UIPanelScrollBarTemplate")
    scrollbar:SetPoint("TOPLEFT", viewport.frame, "TOPRIGHT", 4, -16)
    scrollbar:SetPoint("BOTTOMLEFT", viewport.frame, "BOTTOMRIGHT", 4, 16)
    scrollbar:SetWidth(16)
    scrollbar:SetMinMaxValues(0, maxTopRow)
    scrollbar:SetValueStep(1)

    local scrollbg = scrollbar:CreateTexture(nil, "BACKGROUND")
    scrollbg:SetAllPoints(scrollbar)
    scrollbg:SetColorTexture(0, 0, 0, 0.4)

    for i = 1, poolSize do
        local iconWidget = AceGUI:Create("Icon")
        iconWidget:SetWidth(40)
        iconWidget:SetImageSize(28, 28)
        iconWidget:SetLabel(nil)
        iconWidget:SetCallback("OnClick", function(widget)
            SelectIcon(widget.iconValue)
        end)

        -- AceGUI's Icon widget has no built-in "selected" indicator, so add
        -- a small border texture directly on its underlying Button frame -
        -- a normal way to extend an AceGUI widget instance from consuming
        -- code without touching the library itself - and toggle it in
        -- RenderWindow() below.
        local selectedBorder = CreateFrame("Frame", nil, iconWidget.frame, "BackdropTemplate")
        selectedBorder:SetPoint("TOPLEFT", iconWidget.image, -3, 3)
        selectedBorder:SetPoint("BOTTOMRIGHT", iconWidget.image, 3, -3)
        selectedBorder:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12 })
        selectedBorder:SetBackdropBorderColor(0, 1, 0, 1)
        selectedBorder:Hide()
        iconWidget.selectedBorder = selectedBorder

        viewport:AddChild(iconWidget)
        pool[i] = iconWidget
    end

    local function RenderWindow()
        local startIndex = topRow * columns
        for i = 1, poolSize do
            local iconWidget = pool[i]
            local icon = icons[startIndex + i]
            if icon == nil then
                iconWidget.frame:Hide()
            else
                iconWidget.frame:Show()
                iconWidget.iconValue = icon
                iconWidget:SetImage(icon)
                iconWidget.selectedBorder:SetShown(iconWidget.iconValue == selectedIcon)
            end
        end
    end

    scrollbar:SetScript("OnValueChanged", function(_, value)
        topRow = math.floor(value + 0.5)
        RenderWindow()
    end)
    scrollbar:SetValue(topRow)
    scrollbar:SetShown(maxTopRow > 0)

    viewport.frame:EnableMouseWheel(true)
    viewport.frame:SetScript("OnMouseWheel", function(_, delta)
        scrollbar:SetValue(scrollbar:GetValue() - delta)
    end)

    RenderWindow()
    picker:Show()
end

--#endregion
