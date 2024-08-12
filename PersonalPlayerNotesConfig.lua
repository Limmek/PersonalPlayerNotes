local personalPlayerNotes = ...
local L = LibStub("AceLocale-3.0"):GetLocale(personalPlayerNotes, true)

PersonalPlayerNotes.defaults = {
    profile = {
        icon = "Interface\\AddOns\\" .. personalPlayerNotes .. "\\Images\\icon.png",
        debug = false,
        minimap = { hide = false, minimapPos = 240 },
        announcement = { delay = 10, guild = true, party = true, raid = true, instance = true },
        alert = {
            delay = 10,
            enabled = true,
            sound = 1,
            sounds = { "alarmbeep", "alarmbuzz", "alarmbuzzer", "alarmdouble" },
            last = {},
            time = 0
        },
        reasons = {
            { id = 1, reason = "None", color = { r = 1, g = 1, b = 1 }, alert = false, },
        },
        reason = { id = 1, reason = "None", color = { r = 1, g = 1, b = 1 } },
        listedPlayer = {
            id = 1,
            name = "Example",
            realm = "Silvermoon",
            reason = 1,
            description = "Example Description",
            color = { r = 1, g = 1, b = 1 },
            alert = true,
        },
        listedPlayers = {
            {
                id = 1,
                name = "Example",
                realm = "Silvermoon",
                reason = 1,
                description = "Example Description",
                color = { r = 0, g = 0, b = 0 },
                alert = true,
            },
        }
    }
}

-- https://www.wowace.com/projects/ace3/pages/ace-config-3-0-options-tables
PersonalPlayerNotes.options = {
    Info = {
        type = "group",
        order = 0,
        name = L["SHITLIST_MENU_TITLE"],
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
                name = L["SHITLIST_INFO_COMMANDS_TITLE"],
                desc = L["SHITLIST_INFO_COMMANDS_DESC"],
                order = 2,
                type = "group",
                inline = true,
                args = {
                    options = {
                        order = 1,
                        type = "description",
                        fontSize = "medium",
                        name = L["SHITLIST_INFO_COMMANDS_2"],
                    },
                    reasons = {
                        order = 2,
                        type = "description",
                        fontSize = "medium",
                        name = L["SHITLIST_INFO_COMMANDS_3"],
                    },
                    players = {
                        order = 3,
                        type = "description",
                        fontSize = "medium",
                        name = L["SHITLIST_INFO_COMMANDS_4"],
                    },
                    minimap = {
                        order = 4,
                        type = "description",
                        fontSize = "medium",
                        name = L["SHITLIST_INFO_COMMANDS_5"],
                    },
                },
            },
            About = {
                name = L["SHITLIST_INFO_ABOUT_TITLE"],
                order = 3,
                type = "group",
                inline = true,
                args = {
                    version = {
                        type = "description",
                        order = 0,
                        width = "full",
                        fontSize = "medium",
                        name = "|cffffd700" .. L["SHITLIST_INFO_ABOUT_VERSION"] ..
                            ": |cffff8c00" .. PersonalPlayerNotes:GetVersion()
                    },
                    author = {
                        type = "description",
                        order = 1,
                        width = "full",
                        fontSize = "medium",
                        name = "|cffffd700" .. L["SHITLIST_INFO_ABOUT_AUTHOR"] ..
                            ": |cffffffff" .. PersonalPlayerNotes:GetAuthor()
                    },
                    category = {
                        type = "description",
                        order = 2,
                        width = "full",
                        fontSize = "medium",
                        name = "|cffffd700" .. L["SHITLIST_INFO_ABOUT_CATEGORY"] ..
                            ": |cffffffff" .. PersonalPlayerNotes:GetCategory()
                    },
                    localizations = {
                        type = "description",
                        order = 3,
                        width = "full",
                        fontSize = "medium",
                        name = "|cffffd700" .. L["SHITLIST_INFO_ABOUT_LOCALIZATION"] ..
                            ": |cffffffff" .. PersonalPlayerNotes:GetLocalizations()
                    },
                    license = {
                        type = "description",
                        order = 4,
                        width = "full",
                        fontSize = "medium",
                        name = "|cffffd700" .. L["SHITLIST_INFO_ABOUT_LICENSE"] ..
                            ": |cffffffff" .. PersonalPlayerNotes:GetLicense()
                    },
                    website = {
                        type = "description",
                        order = 5,
                        width = "full",
                        fontSize = "medium",
                        name = "|cffffd700" .. L["SHITLIST_INFO_ABOUT_WEB"] ..
                            ": |cffffffff" .. PersonalPlayerNotes:GetWebsite()
                    },
                }
            }
        }
    },
    Settings = {
        type = "group",
        order = 1,
        name = L["SHITLIST_SETTINGS_TITLE"],
        inline = true,
        childGroups = "tab",
        handler = PersonalPlayerNotes,
        args = {
            minimap = {
                name = L["SHITLIST_SETTINGS_MINIMAP"],
                order = 1,
                type = "group",
                inline = true,
                args = {
                    minimapToggle = {
                        type = "toggle",
                        order = 0,
                        name = L["SHITLIST_SETTINGS_MINIMAP_ICON"],
                        desc = L["SHITLIST_SETTINGS_MINIMAP_ICON_DESC"],
                        get = function(info)
                            return PersonalPlayerNotes.db.profile.minimap.hide;
                        end,
                        set = function(info, value)
                            PersonalPlayerNotes.db.profile.minimap.hide = value;
                            PersonalPlayerNotes:LoadConfig();
                        end
                    },
                    minimapPos = {
                        type = "range",
                        order = 1,
                        name = L["SHITLIST_SETTINGS_MINIMAP_POS"],
                        desc = L["SHITLIST_SETTINGS_MINIMAP_POS_DESC"],
                        width = 1.5,
                        get = function(info)
                            return PersonalPlayerNotes.db.profile.minimap.minimapPos;
                        end,
                        set = function(info, value)
                            PersonalPlayerNotes.db.profile.minimap.minimapPos = value;
                            PersonalPlayerNotes:LoadConfig();
                        end,
                        min = 0,
                        max = 360,
                        step = 1,
                    },
                },
            },
            alert = {
                name = L["SHITLIST_SETTINGS_ALERT"],
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
                        name = L["SHITLIST_SETTINGS_ALERT_DESC"]
                    },
                    enabled = {
                        type = "toggle",
                        order = 1,
                        name = L["SHITLIST_SETTINGS_ALERT_ENABLED"],
                        desc = L["SHITLIST_SETTINGS_ALERT_ENABLED_DESC"],
                        width = 0.5
                    },
                    sounds = {
                        type = "select",
                        order = 2,
                        name = L["SHITLIST_SETTINGS_ALERT_SOUNDS"],
                        desc = L["SHITLIST_SETTINGS_ALERT_SOUNDS_DESC"],
                        values = function()
                            return PersonalPlayerNotes.db.profile.alert.sounds
                        end,
                        width = 1,
                        set = "SetAlertSoundEffect",
                        get = "GetAlertSoundEffect",
                    },
                    delay = {
                        type = "range",
                        order = 3,
                        min = 1,
                        max = 60,
                        step = 1,
                        name = L["SHITLIST_SETTINGS_ALERT_DELAY"],
                        desc = L["SHITLIST_SETTINGS_ALERT_DELAY_DESC"],
                        width = 1
                    }
                }
            }
        }
    },
    Reasons = {
        type = "group",
        order = 2,
        name = L["SHITLIST_REASONS_TITLE"],
        inline = false,
        handler = PersonalPlayerNotes,
        args = {
            description = {
                type = "description",
                order = 0,
                width = "full",
                name = L["SHITLIST_REASON_DESCRIPTION"]
            },
            id = {
                type = "select",
                order = 1,
                width = 1.6,
                name = L["SHITLIST_REASONS"],
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
                name = L["SHITLIST_REASON_REMOVE"],
                confirm = function()
                    return L["SHITLIST_REASON_REMOVE_CONFIRMATION"] ..
                    PersonalPlayerNotes.db.profile.reason.reason .. "|cffffffff?";
                end,
                func = "RemoveReason",
                disabled = function()
                    if (PersonalPlayerNotes.db.profile.reason.id <= #PersonalPlayerNotes.defaults.profile.reasons) then
                        return true
                    end
                    return false
                end
            },
            reason = {
                type = "input",
                order = 3,
                name = L["SHITLIST_REASON"],
                width = 2.6,
                get = "GetReason",
                set = "SetReason",
            },
            color = {
                type = "color",
                order = 4,
                width = 1.5,
                name = L["SHITLIST_REASON_COLOR"],
                hasAlpha = false,
                get = "GetReasonColor",
                set = "SetReasonColor",
            },
            alert = {
                type = "toggle",
                order = 5,
                width = 1,
                name = L["SHITLIST_REASON_ALERT_ENABLED"],
                desc = L["SHITLIST_REASON_ALERT_ENABLED_DESC"],
                get = "GetReasonAlert",
                set = "SetReasonAlert",
            },
        }
    },
    ListedPlayers = {
        type = "group",
        order = 3,
        name = L["SHITLIST_LISTED_PLAYERS_TITLE"],
        inline = true,
        handler = PersonalPlayerNotes,
        args = {
            id = {
                type = "select",
                order = 1,
                width = 1.6,
                name = L["SHITLIST_LISTED_PLAYERS"],
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
                name = L["SHITLIST_LISTED_PLAYER_REMOVE"],
                confirm = function()
                    return L["SHITLIST_LISTED_PLAYER_REMOVE_CONFIRMATION"] ..
                        PersonalPlayerNotes.db.profile.listedPlayer.name ..
                        "-" .. PersonalPlayerNotes.db.profile.listedPlayer.realm .. "|cffffffff?";
                end,
                func = "RemoveListedPlayer",
            },
            name = {
                type = "input",
                order = 3,
                name = L["SHITLIST_LISTED_PLAYER_NAME"],
                width = 1.25,
                get = "GetListedPlayerName",
                set = "SetListedPlayerName",
            },
            realm = {
                type = "input",
                order = 4,
                name = L["SHITLIST_LISTED_PLAYER_REALM"],
                width = 1.25,
                get = "GetListedPlayerRealm",
                set = "SetListedPlayerRealm",
            },
            reason = {
                type = "select",
                order = 5,
                width = 2.6,
                name = L["SHITLIST_LISTED_PLAYER_REASON"],
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
                name = L["SHITLIST_LISTED_PLAYER_DESCRIPTION"],
                width = 2.6,
                get = "GetListedPlayerSelectedDescription",
                set = "SetListedPlayerSelectedDescription",
            },
            color = {
                type = "color",
                order = 7,
                width = 1.5,
                name = L["SHITLIST_LISTED_PLAYER_COLOR"],
                hasAlpha = false,
                get = "GetListedPlayerColor",
                set = "SetListedPlayerColor",
            },
            alert = {
                type = "toggle",
                order = 8,
                width = 1,
                name = L["SHITLIST_LISTED_PLAYER_ALERT_ENABLED"],
                desc = L["SHITLIST_LISTED_PLAYER_ALERT_ENABLED_DESC"],
                get = "GetListedPlayerAlert",
                set = "SetListedPlayerAlert",
                disabled = function()
                    return not PersonalPlayerNotes.db.profile.reasons
                    [PersonalPlayerNotes.db.profile.listedPlayer.reason].alert
                end,
            },
        }
    }
}

--#region Sound

function PersonalPlayerNotes:GetAlert(info)
    return self.db.profile.alert[info[#info]]
end

function PersonalPlayerNotes:SetAlert(info, value)
    self.db.profile.alert[info[#info]] = value
end

function PersonalPlayerNotes:GetAlertSoundEffect(info)
    return self.db.profile.alert.sound
end

function PersonalPlayerNotes:SetAlertSoundEffect(info, value)
    self:PlayAlertSoundEffect(value)
    self.db.profile.alert.sound = value
end

function PersonalPlayerNotes:PlayAlertSoundEffect(effect, channel)
    PlaySoundFile(
        "Interface\\AddOns\\" ..
        personalPlayerNotes ..
        "\\Sounds\\" .. PersonalPlayerNotes.db.profile.alert.sounds[effect or self:GetAlertSoundEffect()] .. ".ogg",
        channel or "master"
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

function PersonalPlayerNotes:GetReason(info)
    return self.db.profile.reason[info[#info]]
end

function PersonalPlayerNotes:SetReason(info, value)
    self.db.profile.reason[info[#info]] = value
    if (self.db.profile.reasons[self.db.profile.reason.id].reason == value) then
        return
    else
        tinsert(self.db.profile.reasons,
            #self.db.profile.reasons + 1,
            {
                id = #self.db.profile.reasons + 1,
                reason = value,
                color = { r = 1, g = 1, b = 1 },
                alert = true
            })
        self.db.profile.reason.id = #self.db.profile.reasons
        self:SelectedReason(info, self.db.profile.reason.id)
        self:GetReason(info)
    end
end

function PersonalPlayerNotes:SelectedReason(info, value)
    local r = self.db.profile.reasons[value]
    if (not r) then
        return
    end
    self.db.profile.reason[info[#info]] = value
    self.db.profile.reason.reason = r.reason
    self.db.profile.reason.color = r.color
    self.db.profile.reason.alert = r.alert
end

function PersonalPlayerNotes:RemoveReason()
    tremove(PersonalPlayerNotes.db.profile.reasons, PersonalPlayerNotes.db.profile.reason.id)
    local reasons = PersonalPlayerNotes:GetReasons()
    PersonalPlayerNotes.db.profile.reason.id = #reasons
    PersonalPlayerNotes.db.profile.reason.reason = reasons[#reasons].reason
    PersonalPlayerNotes.db.profile.reason.color = reasons[#reasons].color
    PersonalPlayerNotes.db.profile.reason.alert = reasons[#reasons].alert
    return true;
end

function PersonalPlayerNotes:GetReasonColor(info)
    local c = self.db.profile.reason[info[#info]]
    return c.r or 1, c.g or 1, c.b or 1
end

function PersonalPlayerNotes:SetReasonColor(info, r, g, b)
    local c = self.db.profile.reason[info[#info]]
    c.r, c.g, c.b = r or 1, g or 1, b or 1
end

function PersonalPlayerNotes:GetReasonAlert(info)
    return self.db.profile.reason[info[#info]]
end

function PersonalPlayerNotes:SetReasonAlert(info, value)
    self.db.profile.reason[info[#info]] = value
    local reason = self:GetReasons()[self.db.profile.reason.id]
    reason.alert = value
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
        if (tostring(name) == value.name and tostring(realm) == value.realm) then
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
    if (player) then
        self.db.profile.listedPlayer.id = value
        self.db.profile.listedPlayer.name = player.name
        self.db.profile.listedPlayer.realm = player.realm
        self.db.profile.listedPlayer.reason = player.reason
        self.db.profile.listedPlayer.description = player.description
        self.db.profile.listedPlayer.color = player.color
        self.db.profile.listedPlayer.alert = player.alert
    end
end

function PersonalPlayerNotes:GetListedPlayerRealm(info)
    return self.db.profile.listedPlayer[info[#info]]
end

function PersonalPlayerNotes:SetListedPlayerRealm(info, value)
    self.db.profile.listedPlayer[info[#info]] = value
    local player = PersonalPlayerNotes:GetListedPlayers()[self.db.profile.listedPlayer.id]
    --local player = PersonalPlayerNotes:GetListedPlayer(self.db.profile.listedPlayer.name, value)
    if (player) then
        player.id = self.db.profile.listedPlayer.id
        player.name = self.db.profile.listedPlayer.name
        player.realm = value
        player.reason = self.db.profile.listedPlayer.reason
        player.description = self.db.profile.listedPlayer.description
        player.color = self.db.profile.listedPlayer.color
        player.alert = self.db.profile.listedPlayer.alert
    end
end

function PersonalPlayerNotes:GetListedPlayerName(info)
    return self.db.profile.listedPlayer[info[#info]]
end

function PersonalPlayerNotes:SetListedPlayerName(info, value)
    self.db.profile.listedPlayer[info[#info]] = value
    --local player = PersonalPlayerNotes:GetListedPlayers()[self.db.profile.listedPlayer.id]
    local player = PersonalPlayerNotes:GetListedPlayer(value, self.db.profile.listedPlayer.realm)
    if (player) then
        player.id = self.db.profile.listedPlayer.id
        player.name = value
        player.realm = self.db.profile.listedPlayer.realm
        player.reason = self.db.profile.listedPlayer.reason
        player.description = self.db.profile.listedPlayer.description
        player.color = self.db.profile.listedPlayer.color
        player.alert = self.db.profile.listedPlayer.alert
    else
        local new = PersonalPlayerNotes:NewListedPlayer(value, self.db.profile.listedPlayer.realm)
        PersonalPlayerNotes:SetListedPlayerSelected(info, new.id)
        PersonalPlayerNotes:GetListedPlayerSelected(info)
    end
end

function PersonalPlayerNotes:RemoveListedPlayer()
    tremove(self.db.profile.listedPlayers, self.db.profile.listedPlayer.id)
    local listedPlayers = PersonalPlayerNotes:GetListedPlayers()
    self.db.profile.listedPlayer.id = #listedPlayers
    self.db.profile.listedPlayer.name = listedPlayers[#listedPlayers].name
    self.db.profile.listedPlayer.realm = listedPlayers[#listedPlayers].realm
    self.db.profile.listedPlayer.reason = listedPlayers[#listedPlayers].reason
    self.db.profile.listedPlayer.description = listedPlayers[#listedPlayers].description
    self.db.profile.listedPlayer.color = listedPlayers[#listedPlayers].color
    self.db.profile.listedPlayer.alert = listedPlayers[#listedPlayers].alert
    return true
end

function PersonalPlayerNotes:GetListedPlayerSelectedReason(info)
    return self.db.profile.listedPlayer[info[#info]]
end

function PersonalPlayerNotes:SetListedPlayerSelectedReason(info, value)
    self.db.profile.listedPlayer[info[#info]] = value
    local player = PersonalPlayerNotes:GetListedPlayers()[self.db.profile.listedPlayer.id]
    player.reason = value
end

function PersonalPlayerNotes:GetListedPlayerSelectedDescription(info)
    return self.db.profile.listedPlayer[info[#info]]
end

function PersonalPlayerNotes:SetListedPlayerSelectedDescription(info, value)
    self.db.profile.listedPlayer[info[#info]] = value
    local player = PersonalPlayerNotes:GetListedPlayers()[self.db.profile.listedPlayer.id]
    player.description = value
end

function PersonalPlayerNotes:GetListedPlayerColor(info)
    local c = self.db.profile.listedPlayer[info[#info]]
    return c.r or 1, c.g or 1, c.b or 1
end

function PersonalPlayerNotes:SetListedPlayerColor(info, r, g, b)
    local c = self.db.profile.listedPlayer[info[#info]]
    c.r, c.g, c.b = r or 1, g or 1, b or 1
end

function PersonalPlayerNotes:NewListedPlayer(name, realm, reason, description)
    self.db.profile.listedPlayer.id = #self.db.profile.listedPlayers + 1
    local newPlayer = {
        id = self.db.profile.listedPlayer.id,
        name = name or self.db.profile.listedPlayer.name,
        realm = realm or self.db.profile.listedPlayer.realm,
        reason = reason or 1,
        description = description or "",
        color = { r = 1, g = 1, b = 1 },
        alert = true
    }
    tinsert(self.db.profile.listedPlayers, self.db.profile.listedPlayer.id, newPlayer)
    return newPlayer
end

function PersonalPlayerNotes:GetListedPlayerAlert(info)
    return self.db.profile.listedPlayer[info[#info]]
end

function PersonalPlayerNotes:SetListedPlayerAlert(info, value)
    self.db.profile.listedPlayer[info[#info]] = value
    local player = PersonalPlayerNotes:GetListedPlayers()[self.db.profile.listedPlayer.id]
    player.alert = value
end

--#endregion
