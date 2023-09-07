local addonName = ...
Shitlist = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0", "AceTimer-3.0"
, "AceSerializer-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local LibDataBroker = LibStub("LibDataBroker-1.1")
local LibDBIcon = LibStub("LibDBIcon-1.0")

function Shitlist:OnInitialize()
    self:PrintDebug("Initializeing...")

    -- uses the "Default" profile instead of character-specific profiles
    -- https://www.wowace.com/projects/ace3/pages/api/ace-db-3-0
    self.db = LibStub("AceDB-3.0"):New("ShitlistDB", self.defaults, true)
    self.db.RegisterCallback(self, "OnNewProfile", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

    -- registers an options table and adds it to the Blizzard options window
    -- https://www.wowace.com/projects/ace3/pages/api/ace-config-3-0
    AceConfig:RegisterOptionsTable("ShitlistSettings Info", self.options.Info, { "shitlist" })
    AceConfigDialog:AddToBlizOptions("ShitlistSettings Info", addonName)

    AceConfig:RegisterOptionsTable("ShitlistSettings Options", self.options.Settings, { "slopt" })
    AceConfigDialog:AddToBlizOptions("ShitlistSettings Options", L["SHITLIST_MENU_SETTINGS"], addonName)

    AceConfig:RegisterOptionsTable("ShitlistSettings Reasons", self.options.Reasons, { "slr" })
    AceConfigDialog:AddToBlizOptions("ShitlistSettings Reasons", L["SHITLIST_MENU_REASONS"], addonName)

    AceConfig:RegisterOptionsTable("ShitlistSettings Listed_Players", self.options.ListedPlayers, { "sllp" })
    AceConfigDialog:AddToBlizOptions("ShitlistSettings Listed_Players", L["SHITLIST_MENU_LISTED_PLAYERS"], addonName)

    -- adds a child options table, in this case our profiles panel
    local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    AceConfig:RegisterOptionsTable("ShitlistSettings Profiles", profiles, { "slp" })
    AceConfigDialog:AddToBlizOptions("ShitlistSettings Profiles", L["SHITLIST_MENU_PROFILES"], addonName)

    LibDBIcon:Register(addonName, self:MiniMapIcon(), self.db.profile.minimap)

    -- https://www.wowace.com/projects/ace3/pages/api/ace-console-3-0
    self:RegisterChatCommand("slminimap", "ToggleMiniMapIcon")
    self:RegisterChatCommand("sldebug", "ToggleDebug")
    self:RegisterChatCommand("sltest", "Test")

    self:GetOldConfigData()
    self:RefreshConfig()
end

function Shitlist:OnEnable()
    self:Print("Loading...")
    self:Print(
        "Found " .. #self:GetReasons() .. " Reasons and " .. #self:GetListedPlayers() .. " Players in database."
    )

    if not self:IsHooked("UnitPopup_ShowMenu") then
        self:SecureHook("UnitPopup_ShowMenu", self.UnitPopup_ShowMenu)
    end

    -- Retail 10.0.2 https://wowpedia.fandom.com/wiki/Patch_10.0.2/API_changes#Tooltip_Changes
    if (TooltipDataProcessor) then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, self.GameTooltip)
    else
        -- Backwards compatibility WOTLK, Classic
        GameTooltip:HookScript("OnTooltipSetUnit", self.GameTooltip)
    end
    self:Print("Done!")
end

function Shitlist:OnDisable()
    self:PrintDebug("OnDisable()")
end

function Shitlist:RefreshConfig()
    self:Print("Reloading config...")

    self.db.profile.alert.last = {}

    if self.db.profile.minimap.hide then
        LibDBIcon:Hide(addonName)
    else
        LibDBIcon:Show(addonName)
    end
end

function Shitlist:GetOldConfigData()
    self:Print("Checking for old player data.")

    local oldReasons = _G.ShitlistDB.Reasons
    local oldListedPlayers = _G.ShitlistDB.ListedPlayers
    local reasons = self:GetReasons()
    local listedPlayers = self:GetListedPlayers()
    local newPlayers = {}

    -- Check old listed player list
    if oldListedPlayers ~= nil then
        for _, player in pairs(listedPlayers) do
            newPlayers[player.name .. "-" .. player.realm] = true
        end

        for key, value in pairs(oldListedPlayers) do
            local name, realm = key:match("([^-]+)-([^-]+)")
            if name and realm then
                if not newPlayers[name .. "-" .. realm] then
                    local reason = value[1]
                    local description = value[2]

                    -- Check if the reason exist already and get it's id.
                    local reasonId = nil
                    for _, r in ipairs(reasons) do
                        if r.reason == reason then
                            reasonId = r.id
                            break
                        end
                    end
                    -- If the reason do not exist add it to the reason data.
                    if not reasonId then
                        reasonId = #reasons + 1
                        reasons[reasonId] = {
                            id = reasonId,
                            reason = reason,
                            color = { r = 1, g = 1, b = 1 },
                            alert = true,
                        }
                    end

                    -- Add the old player to the new listed players
                    listedPlayers[#listedPlayers + 1] = {
                        id = #listedPlayers + 1,
                        name = name,
                        realm = realm,
                        reason = reasonId,
                        description = description,
                        color = { r = 1, g = 1, b = 1 },
                        alert = true,
                    }

                    self:Print("Added old player:", name .. "-" .. realm)
                else
                    self:Print("Found duplicate:", name .. "-" .. realm)
                end
            end
        end

        -- remove the old listed players from the database
        _G.ShitlistDB.ListedPlayers = nil
        _G.ShitlistDB.Reasons = nil
    end
end

function Shitlist:UnitPopup_ShowMenu(target, unit)
    local name, realm = self.name, GetRealmName()
    local listedPlayer = Shitlist:GetListedPlayer(name, realm)
    Shitlist:PrintDebug("UnitPopup_ShowMenu:", name, realm, listedPlayer or nil)

    -- Check if this is the root level of the dropdown menu
    if UIDROPDOWNMENU_MENU_LEVEL == 1 and UnitIsPlayer(unit) and target ~= "SELF" then
        if (listedPlayer) then
            UIDropDownMenu_AddButton({
                text = L["SHITLIST"],
                notCheckable = true,
                hasArrow = true,
                keepShownOnClick = true,
            }, UIDROPDOWNMENU_MENU_LEVEL)
        else
            UIDropDownMenu_AddButton({
                text = L["SHITLIST_POPUP_ADD_PLAYER"],
                notCheckable = true,
                icon = "Interface\\AddOns\\" .. addonName .. "\\Icon\\shitlist.png",
                value = { name, realm },
                func = function()
                    Shitlist:Print("Adding new player: " .. name .. "-" .. realm)
                    local new_player = Shitlist:NewListedPlayer(name, realm)
                    Shitlist.db.profile.listedPlayer.id = new_player.id
                    Shitlist.db.profile.listedPlayer.name = new_player.name
                    Shitlist.db.profile.listedPlayer.realm = new_player.realm
                    Shitlist.db.profile.listedPlayer.reason = new_player.reason
                    Shitlist.db.profile.listedPlayer.description = new_player.description
                    Shitlist.db.profile.listedPlayer.color = new_player.color
                    Shitlist.db.profile.listedPlayer.alert = new_player.alert

                    AceConfigDialog:CloseAll()
                    local AceGUI = Shitlist:AceGUIDefaults()
                    AceGUI:SetTitle(L["SHITLIST_LISTED_PLAYERS_TITLE"])
                    AceConfigDialog:SetDefaultSize("ShitlistSettings Listed_Players", 600, 300)
                    AceConfigDialog:Open("ShitlistSettings Listed_Players")
                end,
            }, UIDROPDOWNMENU_MENU_LEVEL)
        end
    elseif UIDROPDOWNMENU_MENU_LEVEL == 2 and UIDROPDOWNMENU_MENU_VALUE == L["SHITLIST"] then
        Shitlist:AddToContextMenu(listedPlayer)
    end
end

function Shitlist:AddToContextMenu(player)
    local menuItem = UIDropDownMenu_CreateInfo()
    menuItem.text = L["SHITLIST"]
    menuItem.notCheckable = true
    menuItem.keepShownOnClick = true
    menuItem.hasArrow = false
    menuItem.isTitle = true
    menuItem.disabled = true
    menuItem.icon = "Interface\\AddOns\\" .. addonName .. "\\Icon\\shitlist.png"
    UIDropDownMenu_AddButton(menuItem, UIDROPDOWNMENU_MENU_LEVEL)

    menuItem = UIDropDownMenu_CreateInfo()
    menuItem.text = "Edit Player"
    menuItem.notCheckable = true
    menuItem.hasArrow = false
    menuItem.value = player
    menuItem.func = function()
        if (player) then
            Shitlist.db.profile.listedPlayer.id = player.id
            Shitlist.db.profile.listedPlayer.name = player.name
            Shitlist.db.profile.listedPlayer.realm = player.realm
            Shitlist.db.profile.listedPlayer.reason = player.reason
            Shitlist.db.profile.listedPlayer.description = player.description
            Shitlist.db.profile.listedPlayer.color = player.color
            Shitlist.db.profile.listedPlayer.alert = player.alert

            AceConfigDialog:CloseAll()
            local AceGUI = Shitlist:AceGUIDefaults()
            AceGUI:SetTitle(L["SHITLIST_LISTED_PLAYERS_TITLE"])
            AceConfigDialog:SetDefaultSize("ShitlistSettings Listed_Players", 600, 300)
            AceConfigDialog:Open("ShitlistSettings Listed_Players")
        end
    end
    UIDropDownMenu_AddButton(menuItem, UIDROPDOWNMENU_MENU_LEVEL)

    menuItem = UIDropDownMenu_CreateInfo()
    menuItem.text = "Announcement"
    menuItem.notCheckable = true
    menuItem.isTitle = true
    local a = Shitlist.db.profile.announcement
    if a.guild or a.party or a.instance or a.raid then
        UIDropDownMenu_AddButton(menuItem, UIDROPDOWNMENU_MENU_LEVEL)
    end

    local function _SendChatMessage(chat)
        _G.SendChatMessage("Player: " .. player.name .. "-" .. player.realm, chat, nil, nil)
        if self.db.profile.reasons[player.reason].reason ~= "None" then
            _G.SendChatMessage("Reason: " .. self.db.profile.reasons[player.reason].reason, chat, nil, nil)
        end
        if player.description ~= "" then
            _G.SendChatMessage("Description: " .. player.description, chat, nil, nil)
        end
    end
    local options = {
        {
            text = "Guild",
            notCheckable = true,
            func = function() _SendChatMessage("GUILD") end,
            disabled = not self.db.profile.announcement.guild
        },
        {
            text = "Party",
            notCheckable = true,
            func = function() _SendChatMessage("PARTY") end,
            disabled = not self.db.profile.announcement.party
        },
        {
            text = "Instance",
            notCheckable = true,
            func = function() _SendChatMessage("INSTANCE_CHAT") end,
            disabled = not self.db.profile.announcement.instance
        },
        {
            text = "Raid",
            notCheckable = true,
            func = function() _SendChatMessage("RAID") end,
            disabled = not self.db.profile.announcement.raid
        },
    }

    for _, option in ipairs(options) do
        if not option.disabled then
            _G.UIDropDownMenu_AddButton(option, _G.UIDROPDOWNMENU_MENU_LEVEL)
        end
    end
end

function Shitlist:GameTooltip()
    local name, unit = self:GetUnit()

    if (unit and not UnitIsPlayer(unit)) then return end

    local _name, realm = _G.UnitName(unit)
    name, realm = _name or name, _G.GetRealmName() or realm

    Shitlist:PrintDebug("GameTooltip:", name, realm)

    local listedPlayer = Shitlist:GetListedPlayer(tostring(name), realm)
    if (not listedPlayer) then return end

    local reason = Shitlist:GetReasons()[listedPlayer.reason]
    local _reason = reason.reason

    Shitlist:PrintDebug("GameTooltip:", listedPlayer, _reason)

    if (_reason == "None") then _reason = "" end

    -- Tooltip
    self:AddLine("\n")
    self:AddDoubleLine(_reason, L["SHITLIST"], reason.color.r or 1, reason.color.g or 1, reason.color.b or 1,
        1.0, 0.82, 0.0)
    self:AddLine(listedPlayer.description, listedPlayer.color.r or 1, listedPlayer.color.g or 1,
        listedPlayer.color.b or 1, false)

    -- Alert
    local time = time()
    local alert = Shitlist.db.profile.alert
    if (listedPlayer.alert and alert.enabled and not alert.last[name]) then
        if (reason.alert and alert.enabled and not alert.last[name]) then
            alert.last[name] = time + alert.delay
            Shitlist:PrintDebug("ALERT: ", name, alert.last[name])
            Shitlist:ScheduleTimer("TimerFeedback", alert.delay, name)
            Shitlist:PlayAlert()
        end
    end
end

function Shitlist:TimerFeedback(name)
    Shitlist:PrintDebug("ALERT:", name, "removed.")
    Shitlist.db.profile.alert.last[name] = nil
end

function Shitlist:MiniMapIcon()
    self:PrintDebug("MiniMapIcon()")
    -- Create minimap launcher
    -- https://github.com/tekkub/libdatabroker-1-1/wiki/How-to-provide-a-dataobject
    return LibDataBroker:NewDataObject(addonName, {
        type = "launcher",
        text = L["SHITLIST"],
        --icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8.png",
        icon = "Interface\\AddOns\\" .. addonName .. "\\Icon\\shitlist.png",
        OnClick = function(clickedframe, button)
            AceConfigDialog:CloseAll()
            local AceGUI = Shitlist:AceGUIDefaults()
            if button == "LeftButton" then
                InterfaceOptionsFrame_OpenToCategory(addonName)
            elseif not (IsControlKeyDown() or IsShiftKeyDown()) and button == "RightButton" then
                AceGUI:SetTitle(L["SHITLIST_SETTINGS_TITLE"])
                AceConfigDialog:SetDefaultSize("ShitlistSettings Options", 700, 400)
                AceConfigDialog:Open("ShitlistSettings Options")
            elseif IsControlKeyDown() and button == "RightButton" then
                AceGUI:SetTitle(L["SHITLIST_REASONS_TITLE"])
                AceConfigDialog:SetDefaultSize("ShitlistSettings Reasons", 550, 200)
                AceConfigDialog:Open("ShitlistSettings Reasons")
            elseif IsShiftKeyDown() and button == "RightButton" then
                AceGUI:SetTitle(L["SHITLIST_LISTED_PLAYERS_TITLE"])
                AceConfigDialog:SetDefaultSize("ShitlistSettings Listed_Players", 600, 300)
                AceConfigDialog:Open("ShitlistSettings Listed_Players")
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:SetText(L["SHITLIST_MINIMAP_TOOLTIP_TITLE"])
            tooltip:AddLine(L["SHITLIST_MINIMAP_TOOLTIP_LEFT_CLICK"])
            tooltip:AddLine(L["SHITLIST_MINIMAP_TOOLTIP_RIGHT_CLICK"])
            tooltip:AddLine(L["SHITLIST_MINIMAP_TOOLTIP_SHIFT_RIGHT_CLICK"])
            tooltip:AddLine(L["SHITLIST_MINIMAP_TOOLTIP_CTRL_RIGHT_CLICK"])
        end,
    })
end

function Shitlist:ToggleMiniMapIcon()
    self:PrintDebug("ToggleMiniMapIcon()")
    self.db.profile.minimap.hide = not self.db.profile.minimap.hide
    self:RefreshConfig()
end

function Shitlist:ToggleDebug()
    self.db.profile.debug = not self.db.profile.debug
    self:PrintDebug("Debug=", self.db.profile.debug)
    self:RefreshConfig()
end
