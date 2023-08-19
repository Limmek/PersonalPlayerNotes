local addonName = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

Shitlist.defaults = {
    profile = {
        debug = false,
        minimap = { hide = false, minimapPos = 245 },
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
            { id = 1, reason = "None",          color = { r = 1, g = 1, b = 1 }, alert = false, },
            { id = 2, reason = "Kill Stealing", color = { r = 0, g = 0, b = 1 }, alert = true, },
            { id = 3, reason = "Ninja Looting", color = { r = 1, g = 0, b = 0 }, alert = true, },
            { id = 4, reason = "Spamming",      color = { r = 0, g = 1, b = 0 }, alert = true, },
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
Shitlist.options = {
    Info = {
        type = "group",
        order = 0,
        name = Shitlist:GetTitle(), --L["SHITLIST_MENU_TITLE"],
        inline = true,
        args = {
            Notes = {
                order = 1,
                type = "description",
                fontSize = "medium",
                name = "" .. Shitlist:GetNotes() .. "\n\n\n",
                cmdHidden = true,
            },
            Commands = {
                name = L["SHITLIST_INFO_COMMANDS_TITLE"],
                desc = L["SHITLIST_INFO_COMMANDS_DESC"],
                order = 2,
                type = "group",
                inline = true,
                args = {
                    minimap = {
                        order = 1,
                        type = "description",
                        fontSize = "medium",
                        name = L["SHITLIST_INFO_COMMANDS"],
                    },
                },
            },
            About = {
                name = L["SHITLIST_INFO_ABOUT_TITLE"],
                order = 3,
                type = "group",
                inline = true,
                cmdHidden = true,
                args = {
                    version = {
                        type = "description",
                        order = 0,
                        width = "full",
                        fontSize = "medium",
                        name = "|cffffd700" .. L["SHITLIST_INFO_ABOUT_VERSION"] ..
                            ": |cffff8c00" .. Shitlist:GetVersion()
                    },
                    author = {
                        type = "description",
                        order = 1,
                        width = "full",
                        fontSize = "medium",
                        name = "|cffffd700" .. L["SHITLIST_INFO_ABOUT_AUTHOR"] ..
                            ": |cffffffff" .. Shitlist:GetAuthor()
                    },
                    category = {
                        type = "description",
                        order = 2,
                        width = "full",
                        fontSize = "medium",
                        name = "|cffffd700" .. L["SHITLIST_INFO_ABOUT_CATEGORY"] ..
                            ": |cffffffff" .. Shitlist:GetCategory()
                    },
                    localizations = {
                        type = "description",
                        order = 3,
                        width = "full",
                        fontSize = "medium",
                        name = "|cffffd700" .. L["SHITLIST_INFO_ABOUT_LOCALIZATION"] ..
                            ": |cffffffff" .. Shitlist:GetLocalizations()
                    },
                    license = {
                        type = "description",
                        order = 4,
                        width = "full",
                        fontSize = "medium",
                        name = "|cffffd700" .. L["SHITLIST_INFO_ABOUT_LICENSE"] ..
                            ": |cffffffff" .. Shitlist:GetLicense()
                    },
                    website = {
                        type = "description",
                        order = 5,
                        width = "full",
                        fontSize = "medium",
                        name = "|cffffd700" .. L["SHITLIST_INFO_ABOUT_WEB"] ..
                            ": |cffffffff" .. Shitlist:GetWebsite()
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
        handler = Shitlist,
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
                            return Shitlist.db.profile.minimap.hide;
                        end,
                        set = function(info, value)
                            Shitlist.db.profile.minimap.hide = value;
                            Shitlist:RefreshConfig();
                        end
                    },
                    minimapPos = {
                        type = "range",
                        order = 1,
                        name = L["SHITLIST_SETTINGS_MINIMAP_POS"],
                        desc = L["SHITLIST_SETTINGS_MINIMAP_POS_DESC"],
                        width = 1.5,
                        get = function(info)
                            return Shitlist.db.profile.minimap.minimapPos;
                        end,
                        set = function(info, value)
                            Shitlist.db.profile.minimap.minimapPos = value;
                            Shitlist:RefreshConfig();
                        end,
                        min = 0,
                        max = 360,
                        step = 1,
                    },
                },
            },
            announcement = {
                name = L["SHITLIST_SETTINGS_ANNOUNCEMENT"],
                order = 2,
                type = "group",
                inline = true,
                width = 0.5,
                get = "GetAnnouncement",
                set = "SetAnnouncement",
                args = {
                    description = {
                        type = "description",
                        order = 0,
                        name = L["SHITLIST_SETTINGS_ANNOUNCEMENT_DESC"],
                    },
                    guild = {
                        type = "toggle",
                        order = 1,
                        name = L["SHITLIST_SETTINGS_ANNOUNCEMENT_GUILD"],
                        desc = L["SHITLIST_SETTINGS_ANNOUNCEMENT_GUILD_DESC"],
                        width = 0.65
                    },
                    party = {
                        type = "toggle",
                        order = 2,
                        name = L["SHITLIST_SETTINGS_ANNOUNCEMENT_PARY"],
                        desc = L["SHITLIST_SETTINGS_ANNOUNCEMENT_PARY_DESC"],
                        width = 0.65
                    },
                    raid = {
                        type = "toggle",
                        order = 3,
                        name = L["SHITLIST_SETTINGS_ANNOUNCEMENT_RAID"],
                        desc = L["SHITLIST_SETTINGS_ANNOUNCEMENT_RAID_DESC"],
                        width = 0.65
                    },
                    instance = {
                        type = "toggle",
                        order = 4,
                        name = L["SHITLIST_SETTINGS_ANNOUNCEMENT_INSTANCE"],
                        desc = L["SHITLIST_SETTINGS_ANNOUNCEMENT_INSTANCE_DESC"],
                        width = 0.75
                    },
                    delay = {
                        type = "range",
                        order = 5,
                        min = 1,
                        max = 60,
                        step = 1,
                        name = L["SHITLIST_SETTINGS_ANNOUNCEMENT_DELAY"],
                        desc = L["SHITLIST_SETTINGS_ANNOUNCEMENT_DELAY_DESC"],
                        width = 0.8
                    }
                }
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
                        width = 1.5
                    },
                    sounds = {
                        type = "select",
                        order = 2,
                        name = L["SHITLIST_SETTINGS_ALERT_SOUNDS"],
                        desc = L["SHITLIST_SETTINGS_ALERT_SOUNDS_DESC"],
                        values = function()
                            return Shitlist.db.profile.alert.sounds
                        end,
                        width = 1.2,
                        set = "SetSound",
                        get = "GetSound",
                    },
                    delay = {
                        type = "range",
                        order = 3,
                        min = 1,
                        max = 60,
                        step = 1,
                        name = L["SHITLIST_SETTINGS_ALERT_DELAY"],
                        desc = L["SHITLIST_SETTINGS_ALERT_DELAY_DESC"],
                        width = 0.8
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
        handler = Shitlist,
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
                width = "double",
                name = L["SHITLIST_REASONS"],
                values = function()
                    local _return = {}
                    for key, value in pairs(Shitlist.db.profile.reasons) do
                        _return[key] = value.reason
                    end
                    return _return
                end,
                get = "GetReasonSelected",
                set = "SetReasonSelected",
            },
            remove = {
                type = "execute",
                order = 2,
                width = 0.8,
                cmdHidden = true,
                name = L["SHITLIST_REASON_REMOVE"],
                confirm = function()
                    return L["SHITLIST_REASON_REMOVE_CONFIRMATION"] .. Shitlist.db.profile.reason.reason .. "|cffffffff?";
                end,
                func = "RemoveReason",
                disabled = function()
                    if (Shitlist.db.profile.reason.id <= #Shitlist.defaults.profile.reasons) then
                        return true
                    end
                    return false
                end
            },
            reason = {
                type = "input",
                order = 3,
                name = L["SHITLIST_REASON"],
                width = "double",
                get = "GetReason",
                set = "SetReason",
            },
            color = {
                type = "color",
                order = 4,
                name = L["SHITLIST_REASON_COLOR"],
                hasAlpha = false,
                get = "GetReasonColor",
                set = "SetReasonColor",
            },
            alert = {
                type = "toggle",
                order = 5,
                name = L["SHITLIST_REASON_ALERT_ENABLED"],
                desc = L["SHITLIST_REASON_ALERT_ENABLED_DESC"],
                width = 1.5,
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
        handler = Shitlist,
        args = {
            id = {
                type = "select",
                order = 1,
                width = "double",
                name = L["SHITLIST_LISTED_PLAYERS"],
                values = function()
                    local _return = {}
                    for key, value in pairs(Shitlist:GetListedPlayers()) do
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
                width = 0.8,
                cmdHidden = true,
                name = L["SHITLIST_LISTED_PLAYER_REMOVE"],
                confirm = function()
                    return L["SHITLIST_LISTED_PLAYER_REMOVE_CONFIRMATION"] ..
                        Shitlist.db.profile.listedPlayer.name ..
                        "-" .. Shitlist.db.profile.listedPlayer.realm .. "|cffffffff?";
                end,
                func = "RemoveListedPlayer",
            },
            name = {
                type = "input",
                order = 3,
                name = L["SHITLIST_LISTED_PLAYER_NAME"],
                width = 1.2,
                get = "GetListedPlayerName",
                set = "SetListedPlayerName",
            },
            realm = {
                type = "input",
                order = 4,
                name = L["SHITLIST_LISTED_PLAYER_REALM"],
                width = 1.2,
                get = "GetListedPlayerRealm",
                set = "SetListedPlayerRealm",
            },
            reason = {
                type = "select",
                order = 5,
                width = 2.4,
                name = L["SHITLIST_LISTED_PLAYER_REASON"],
                values = function()
                    local _return = {}
                    for key, value in pairs(Shitlist:GetReasons()) do
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
                width = 2.4,
                get = "GetListedPlayerSelectedDescription",
                set = "SetListedPlayerSelectedDescription",
            },
            color = {
                type = "color",
                order = 7,
                width = 0.8,
                name = L["SHITLIST_LISTED_PLAYER_COLOR"],
                hasAlpha = false,
                get = "GetListedPlayerColor",
                set = "SetListedPlayerColor",
            },
            alert = {
                type = "toggle",
                order = 8,
                name = L["SHITLIST_LISTED_PLAYER_ALERT_ENABLED"],
                desc = L["SHITLIST_LISTED_PLAYER_ALERT_ENABLED_DESC"],
                width = 1.5,
                get = "GetListedPlayerAlert",
                set = "SetListedPlayerAlert",
            },
        }
    }
}


--#region Announcement

function Shitlist:GetAnnouncement(info)
    return self.db.profile.announcement[info[#info]]
end

function Shitlist:SetAnnouncement(info, value)
    self.db.profile.announcement[info[#info]] = value
end

--#endregion


--#region Sound

function Shitlist:GetAlert(info)
    return self.db.profile.alert[info[#info]]
end

function Shitlist:SetAlert(info, value)
    self.db.profile.alert[info[#info]] = value
end

--#endregion


--#region Reasons

--[[
    Returns all reasons
]]
--
function Shitlist:GetReasons()
    return self.db.profile.reasons
end

function Shitlist:GetReasonSelected(info)
    return self.db.profile.reason[info[#info]]
end

function Shitlist:SetReasonSelected(info, value)
    local r = self.db.profile.reasons[value]
    if (not r) then
        return
    end
    self.db.profile.reason[info[#info]] = value
    self.db.profile.reason.reason = r.reason
    self.db.profile.reason.color = r.color
    self.db.profile.reason.alert = r.alert
end

function Shitlist:GetReason(info)
    return self.db.profile.reason[info[#info]]
end

function Shitlist:SetReason(info, value)
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
        -- self.db.profile.reason.color = { r = 1, g = 1, b = 1 }
        -- self.db.profile.reason.alert = { r = 1, g = 1, b = 1 }
        self:SetReasonSelected(info, self.db.profile.reason.id)
        self:GetReasonSelected(info)
    end
end

function Shitlist:RemoveReason()
    tremove(Shitlist.db.profile.reasons, Shitlist.db.profile.reason.id)
    --Shitlist.db.profile.reasons[Shitlist.db.profile.reason.id] = nil
    local reasons = Shitlist:GetReasons()
    Shitlist.db.profile.reason.id = #reasons
    Shitlist.db.profile.reason.reason = reasons[#reasons].reason
    Shitlist.db.profile.reason.color = reasons[#reasons].color
    Shitlist.db.profile.reason.alert = reasons[#reasons].alert
    return true;
end

function Shitlist:GetReasonColor(info)
    local c = self.db.profile.reason[info[#info]]
    return c.r or 1, c.g or 1, c.b or 1
end

function Shitlist:SetReasonColor(info, r, g, b)
    local c = self.db.profile.reason[info[#info]]
    c.r, c.g, c.b = r or 1, g or 1, b or 1
end

function Shitlist:GetReasonAlert(info)
    return self.db.profile.reason[info[#info]]
end

function Shitlist:SetReasonAlert(info, value)
    self.db.profile.reason[info[#info]] = value
    local reason = self:GetReasons()[self.db.profile.reason.id]
    reason.alert = value
end

--#endregion


--#region Listed Players

--[[
    Returns all listed players
]]
--
function Shitlist:GetListedPlayers()
    return self.db.profile.listedPlayers
end

function Shitlist:GetListedPlayer(name, realm)
    for index, value in pairs(self.db.profile.listedPlayers) do
        if (name == value.name and realm == value.realm) then
            return self.db.profile.listedPlayers[index]
        end
    end
    return nil
end

function Shitlist:GetListedPlayerSelected(info)
    return self.db.profile.listedPlayer[info[#info]]
end

function Shitlist:SetListedPlayerSelected(info, value)
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

function Shitlist:GetListedPlayerRealm(info)
    return self.db.profile.listedPlayer[info[#info]]
end

function Shitlist:SetListedPlayerRealm(info, value)
    self.db.profile.listedPlayer[info[#info]] = value
    local player = Shitlist:GetListedPlayers()[self.db.profile.listedPlayer.id]
    --local player = Shitlist:GetListedPlayer(self.db.profile.listedPlayer.name, value)
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

function Shitlist:GetListedPlayerName(info)
    return self.db.profile.listedPlayer[info[#info]]
end

function Shitlist:SetListedPlayerName(info, value)
    self.db.profile.listedPlayer[info[#info]] = value
    --local player = Shitlist:GetListedPlayers()[self.db.profile.listedPlayer.id]
    local player = Shitlist:GetListedPlayer(value, self.db.profile.listedPlayer.realm)
    if (player) then
        player.id = self.db.profile.listedPlayer.id
        player.name = value
        player.realm = self.db.profile.listedPlayer.realm
        player.reason = self.db.profile.listedPlayer.reason
        player.description = self.db.profile.listedPlayer.description
        player.color = self.db.profile.listedPlayer.color
        player.alert = self.db.profile.listedPlayer.alert
    else
        local new = Shitlist:NewListedPlayer(value, self.db.profile.listedPlayer.realm)
        Shitlist:SetListedPlayerSelected(info, new.id)
        Shitlist:GetListedPlayerSelected(info)
    end
end

function Shitlist:RemoveListedPlayer()
    tremove(self.db.profile.listedPlayers, self.db.profile.listedPlayer.id)
    local listedPlayers = Shitlist:GetListedPlayers()
    self.db.profile.listedPlayer.id = #listedPlayers
    self.db.profile.listedPlayer.name = listedPlayers[#listedPlayers].name
    self.db.profile.listedPlayer.realm = listedPlayers[#listedPlayers].realm
    self.db.profile.listedPlayer.reason = listedPlayers[#listedPlayers].reason
    self.db.profile.listedPlayer.description = listedPlayers[#listedPlayers].description
    self.db.profile.listedPlayer.color = listedPlayers[#listedPlayers].color
    self.db.profile.listedPlayer.alert = listedPlayers[#listedPlayers].alert
    return true
end

function Shitlist:GetListedPlayerSelectedReason(info)
    return self.db.profile.listedPlayer[info[#info]]
end

function Shitlist:SetListedPlayerSelectedReason(info, value)
    self.db.profile.listedPlayer[info[#info]] = value
    local player = Shitlist:GetListedPlayers()[self.db.profile.listedPlayer.id]
    player.reason = value
end

function Shitlist:GetListedPlayerSelectedDescription(info)
    return self.db.profile.listedPlayer[info[#info]]
end

function Shitlist:SetListedPlayerSelectedDescription(info, value)
    self.db.profile.listedPlayer[info[#info]] = value
    local player = Shitlist:GetListedPlayers()[self.db.profile.listedPlayer.id]
    player.description = value
end

function Shitlist:GetListedPlayerColor(info)
    local c = self.db.profile.listedPlayer[info[#info]]
    return c.r or 1, c.g or 1, c.b or 1
end

function Shitlist:SetListedPlayerColor(info, r, g, b)
    local c = self.db.profile.listedPlayer[info[#info]]
    c.r, c.g, c.b = r or 1, g or 1, b or 1
end

function Shitlist:NewListedPlayer(name, realm, reason, description)
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

function Shitlist:GetListedPlayerAlert(info)
    return self.db.profile.listedPlayer[info[#info]]
end

function Shitlist:SetListedPlayerAlert(info, value)
    self.db.profile.listedPlayer[info[#info]] = value
    local player = Shitlist:GetListedPlayers()[self.db.profile.listedPlayer.id]
    player.alert = value
end

--#endregion

function Shitlist:GetSound(info)
    return self.db.profile.alert.sound
end

function Shitlist:SetSound(info, value)
    self:PlayAlert(value)
    self.db.profile.alert.sound = value
end

function Shitlist:PlayAlert(value, channel)
    _G.PlaySoundFile(
        "Interface\\AddOns\\" ..
        addonName .. "\\Sounds\\" .. Shitlist.db.profile.alert.sounds[value or self:GetSound()] .. ".ogg",
        channel or "master"
    )
end
