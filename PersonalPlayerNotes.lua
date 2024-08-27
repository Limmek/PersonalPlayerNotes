local personalPlayerNotes    = ...
PersonalPlayerNotes          = LibStub("AceAddon-3.0"):NewAddon(personalPlayerNotes, "AceConsole-3.0", "AceEvent-3.0",
    "AceHook-3.0",
    "AceTimer-3.0"
    , "AceSerializer-3.0")
local L                      = LibStub("AceLocale-3.0"):GetLocale(personalPlayerNotes, true)
local AceConfig              = LibStub("AceConfig-3.0")
local AceConfigDialog        = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry      = LibStub("AceConfigRegistry-3.0")
local LibDataBroker          = LibStub("LibDataBroker-1.1")
local LibDBIcon              = LibStub("LibDBIcon-1.0")

local IS_RETAIL              = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE or false;
local IS_WRATH               = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC or false;

PersonalPlayerNotes.IsRetail = IS_RETAIL;
PersonalPlayerNotes.IsWrath = IS_WRATH;

function PersonalPlayerNotes:OnInitialize()
    -- uses the "Default" profile instead of character-specific profiles
    -- https://www.wowace.com/projects/ace3/pages/api/ace-db-3-0
    self.db = LibStub("AceDB-3.0"):New("PersonalPlayerNotesDB", self.defaults, true)
    self.db.RegisterCallback(self, "OnNewProfile", "LoadConfig")
    self.db.RegisterCallback(self, "OnProfileChanged", "LoadConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "LoadConfig")
    self.db.RegisterCallback(self, "OnProfileReset", "LoadConfig")

    -- registers an options table and adds it to the Blizzard options window
    -- https://www.wowace.com/projects/ace3/pages/api/ace-config-3-0
    AceConfig:RegisterOptionsTable("PersonalPlayerNotesSettings Info", self.options.Info)
    AceConfigDialog:AddToBlizOptions("PersonalPlayerNotesSettings Info", personalPlayerNotes)

    AceConfig:RegisterOptionsTable("PersonalPlayerNotesSettings Options", self.options.Settings, { "ppno", "ppnoptions" })
    AceConfigDialog:AddToBlizOptions("PersonalPlayerNotesSettings Options", L["PPN_MENU_SETTINGS"], personalPlayerNotes)

    AceConfig:RegisterOptionsTable("PersonalPlayerNotesSettings Reasons", self.options.Reasons, { "ppnr", "ppnreasons" })
    AceConfigDialog:AddToBlizOptions("PersonalPlayerNotesSettings Reasons", L["PPN_MENU_REASONS"], personalPlayerNotes)

    AceConfig:RegisterOptionsTable("PersonalPlayerNotesSettings Listed_Players", self.options.ListedPlayers,
        { "ppnp", "ppnplayers" })
    AceConfigDialog:AddToBlizOptions("PersonalPlayerNotesSettings Listed_Players", L["PPN_MENU_LISTED_PLAYERS"],
        personalPlayerNotes)

    local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    AceConfig:RegisterOptionsTable("PersonalPlayerNotesSettings Profiles", profiles)
    AceConfigDialog:AddToBlizOptions("PersonalPlayerNotesSettings Profiles", L["PPN_MENU_PROFILES"], personalPlayerNotes)

    LibDBIcon:Register(personalPlayerNotes, self:MiniMapIcon(), self.db.profile.minimap)

    self:RegisterChatCommand("ppn", function()
        Settings.OpenToCategory(personalPlayerNotes)
    end)
    self:RegisterChatCommand("ppnm", "ToggleMiniMapIcon")
    self:RegisterChatCommand("ppnminimap", "ToggleMiniMapIcon")
    self:RegisterChatCommand("ppndebug", "ToggleDebug")

    local loaded = nil
    if (self.IsWrath) then
        loaded, reason = LoadAddOn("Shitlist")
    else
        loaded, reason = C_AddOns.LoadAddOn("Shitlist")
    end

    if loaded then
        self:GetOldConfigData()
    end
    self:LoadConfig()
end

function PersonalPlayerNotes:OnEnable()
    self:Print(L["PPN_CONFIG_LOADING"])
    self:Print(L["PPN_CONFIG_VERSION"], _G["ORANGE_FONT_COLOR_CODE"], self:GetVersion())
    self:Print(L["PPN_CONFIG_REASONS"], _G["GREEN_FONT_COLOR_CODE"], #self:GetReasons())
    self:Print(L["PPN_CONFIG_LISTEDPLAYERS"], _G["GREEN_FONT_COLOR_CODE"], #self:GetListedPlayers())

    if (self.IsRetail) then
        -- New Menu System in Retail 11.0.0
        -- https://warcraft.wiki.gg/wiki/Patch_11.0.0/API_changes
        -- https://www.townlong-yak.com/framexml/latest/Blizzard_Menu/11_0_0_MenuImplementationGuide.lua
        self:DropDownMenuInitialize()
        -- Retail 10.0.2 https://wowpedia.fandom.com/wiki/Patch_10.0.2/API_changes#Tooltip_Changes
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, self.GameTooltip)
    else
        -- Backwards compatibility Classic
        if not self:IsHooked("UnitPopup_ShowMenu") then
            self:SecureHook("UnitPopup_ShowMenu", self.UnitPopup_ShowMenu)
        end
        GameTooltip:HookScript("OnTooltipSetUnit", self.GameTooltip)
    end
    self:Print(L["PPN_CONFIG_LOADED"])
end

function PersonalPlayerNotes:OnDisable()
    self:Print(L["PPN_DISABLE"])
end

function PersonalPlayerNotes:LoadConfig()
    self.db.profile.alert.last = {}

    if self.db.profile.minimap.hide then
        LibDBIcon:Hide(personalPlayerNotes)
    else
        LibDBIcon:Show(personalPlayerNotes)
    end

    self:PrintDebug(L["PPN_CONFIG_REFRESH"])
    self:PrintDebug("Debug mode:", _G["GREEN_FONT_COLOR_CODE"], self.db.profile.debug)
    self:PrintDebug("Mini Map Icon:", _G["GREEN_FONT_COLOR_CODE"], not self.db.profile.minimap.hide)
end

function PersonalPlayerNotes:GetOldConfigData()
    local reasons = self:GetReasons()
    local listedPlayers = self:GetListedPlayers()
    -- Check if old data exist pre addon 2.0.0 version
    if ShitlistDB.Reasons ~= nil and ShitlistDB.ListedPlayers ~= nil then
        self:Print(L["PPN_CONFIG_CHECK_OLD_DATA"])

        local oldListedPlayers = ShitlistDB.ListedPlayers
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

                        self:Print(L["PPN_CONFIG_ADDED_OLD_DATA"], name .. "-" .. realm)
                    else
                        self:Print(L["PPN_CONFIG_DUPLICATE_DATA"], name .. "-" .. realm)
                    end
                end
            end

            -- remove the old listed players from the database
            ShitlistDB.ListedPlayers = nil
            ShitlistDB.Reasons = nil
        end
    end

    -- Move old shitlist profiles data to new Personal Player Notes database
    if ShitlistDB and ShitlistDB.profiles then
        self:Print(L["PPN_CONFIG_MIGRATE_OLD_DATA"])
        StaticPopupDialogs["MIGRATE_PROFILES"] = {
            text = L["PPN_CONFIG_MIGRATE"],
            button1 = L["PPN_CONFIG_MIGRATE_YES"],
            button2 = L["PPN_CONFIG_MIGRATE_NO"],
            OnAccept = function()
                for profileName, profileData in pairs(ShitlistDB.profiles) do
                    PersonalPlayerNotes.db.profiles[profileName] = profileData
                end
                self:Print(L["PPN_CONFIG_REASONS"], _G["GREEN_FONT_COLOR_CODE"], #self:GetReasons())
                self:Print(L["PPN_CONFIG_LISTEDPLAYERS"], _G["GREEN_FONT_COLOR_CODE"], #self:GetListedPlayers())
                PersonalPlayerNotes:Print(L["PPN_CONFIG_MIGRATE_DONE"])
                self.db:SetProfile("Default")
                if (self.IsWrath) then
                    DisableAddOn("Shitlist")
                    ReloadUI()
                else
                    C_AddOns.DisableAddOn("Shitlist")
                    C_UI.Reload()
                end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("MIGRATE_PROFILES")
    end
end

function PersonalPlayerNotes:DropDownMenuInitialize()
    local DropDownMenu = function(ownerRegion, rootDescription, contextData)
        -- verify the unit
        if contextData.unit == nil or not UnitIsPlayer(contextData.unit) then
            return
        end
        -- retrieve name and realm from wow api
        local name, realm = UnitName(contextData.unit)
        -- if the unit is from the same realm then realm is empty, use current realm instead
        if realm == nil then realm = GetRealmName() end

        local listedPlayer = PersonalPlayerNotes:GetListedPlayer(name, realm)
        if (not listedPlayer) then
            rootDescription:CreateDivider()
            rootDescription:CreateTitle(L["PPN"])
            rootDescription:CreateButton(L["PPN_POPUP_ADD"], function()
                PersonalPlayerNotes:Print(L["PPN_POPUP_NEW_ADDED"], name, realm)

                local new_player = PersonalPlayerNotes:NewListedPlayer(name, realm)
                PersonalPlayerNotes.db.profile.listedPlayer.id = new_player.id
                PersonalPlayerNotes.db.profile.listedPlayer.name = new_player.name
                PersonalPlayerNotes.db.profile.listedPlayer.realm = new_player.realm
                PersonalPlayerNotes.db.profile.listedPlayer.reason = new_player.reason
                PersonalPlayerNotes.db.profile.listedPlayer.description = new_player.description
                PersonalPlayerNotes.db.profile.listedPlayer.color = new_player.color
                PersonalPlayerNotes.db.profile.listedPlayer.alert = new_player.alert

                AceConfigDialog:CloseAll()
                local AceGUI = PersonalPlayerNotes:AceGUIDefaults()
                AceGUI:SetTitle(L["PPN_LISTED_PLAYERS_TITLE"])
                AceConfigDialog:SetDefaultSize("PersonalPlayerNotesSettings Listed_Players", 500, 300)
                AceConfigDialog:Open("PersonalPlayerNotesSettings Listed_Players")
            end)
        else
            rootDescription:CreateDivider()
            rootDescription:CreateTitle(L["PPN"])
            rootDescription:CreateButton(L["PPN_POPUP_EDIT"], function()
                PersonalPlayerNotes.db.profile.listedPlayer.id = listedPlayer.id
                PersonalPlayerNotes.db.profile.listedPlayer.name = listedPlayer.name
                PersonalPlayerNotes.db.profile.listedPlayer.realm = listedPlayer.realm
                PersonalPlayerNotes.db.profile.listedPlayer.reason = listedPlayer.reason
                PersonalPlayerNotes.db.profile.listedPlayer.description = listedPlayer.description
                PersonalPlayerNotes.db.profile.listedPlayer.color = listedPlayer.color
                PersonalPlayerNotes.db.profile.listedPlayer.alert = listedPlayer.alert

                AceConfigDialog:CloseAll()
                local AceGUI = PersonalPlayerNotes:AceGUIDefaults()
                AceGUI:SetTitle(L["PPN_LISTED_PLAYERS_TITLE"])
                AceConfigDialog:SetDefaultSize("PersonalPlayerNotesSettings Listed_Players", 500, 300)
                AceConfigDialog:Open("PersonalPlayerNotesSettings Listed_Players")
            end)
        end
    end
    Menu.ModifyMenu("MENU_UNIT_PLAYER", function(...) DropDownMenu(...) end)
    Menu.ModifyMenu("MENU_UNIT_ENEMY_PLAYER", function(...) DropDownMenu(...) end)
    Menu.ModifyMenu("MENU_UNIT_FRIEND", function(...) DropDownMenu(...) end)
end

-- Classic Deprecated
function PersonalPlayerNotes:UnitPopup_ShowMenu(target, unit, menuList)
    PersonalPlayerNotes:PrintDebug("Unit: ", unit, ", Target: ", target)
    -- verify the target
    if target == "SELF" or target == "FRIEND" or target == "COMMUNITIES_GUILD_MEMBER" then
        return
    end
    -- verify the unit
    if unit == nil or not UnitIsPlayer(unit) then
        return
    end
    -- retrieve name and realm from wow api
    local name, realm = UnitName(unit)
    -- if the unit is from the same realm then realm is empty, use current realm instead
    if realm == nil then realm = GetRealmName() end
    local listedPlayer = PersonalPlayerNotes:GetListedPlayer(name, realm)

    PersonalPlayerNotes:PrintDebug("Name: ", name, ", Realm: ", realm)

    -- Check if this is the root level of the dropdown menu
    if UIDROPDOWNMENU_MENU_LEVEL == 1 then
        if (listedPlayer) then
            UIDropDownMenu_AddButton({
                text = personalPlayerNotes,
                notCheckable = true,
                hasArrow = true,
                keepShownOnClick = true,
            }, UIDROPDOWNMENU_MENU_LEVEL)
        else
            UIDropDownMenu_AddButton({
                text = L["PPN_POPUP_ADD"],
                notCheckable = true,
                icon = PersonalPlayerNotes.db.profile.icon,
                value = { name, realm },
                func = function()
                    PersonalPlayerNotes:Print(L["PPN_POPUP_NEW_ADDED"], name, realm)
                    local new_player = PersonalPlayerNotes:NewListedPlayer(name, realm)
                    PersonalPlayerNotes.db.profile.listedPlayer.id = new_player.id
                    PersonalPlayerNotes.db.profile.listedPlayer.name = new_player.name
                    PersonalPlayerNotes.db.profile.listedPlayer.realm = new_player.realm
                    PersonalPlayerNotes.db.profile.listedPlayer.reason = new_player.reason
                    PersonalPlayerNotes.db.profile.listedPlayer.description = new_player.description
                    PersonalPlayerNotes.db.profile.listedPlayer.color = new_player.color
                    PersonalPlayerNotes.db.profile.listedPlayer.alert = new_player.alert

                    AceConfigDialog:CloseAll()
                    local AceGUI = PersonalPlayerNotes:AceGUIDefaults()
                    AceGUI:SetTitle(L["PPN_LISTED_PLAYERS_TITLE"])
                    AceConfigDialog:SetDefaultSize("PersonalPlayerNotesSettings Listed_Players", 500, 300)
                    AceConfigDialog:Open("PersonalPlayerNotesSettings Listed_Players")
                end,
            }, UIDROPDOWNMENU_MENU_LEVEL)
        end
    elseif UIDROPDOWNMENU_MENU_VALUE == personalPlayerNotes then
        -- Add the submenu
        local menuItem = UIDropDownMenu_CreateInfo()
        menuItem.text = personalPlayerNotes
        menuItem.notCheckable = true
        menuItem.keepShownOnClick = true
        menuItem.hasArrow = false
        menuItem.isTitle = true
        menuItem.disabled = true
        menuItem.icon = PersonalPlayerNotes.db.profile.icon
        UIDropDownMenu_AddButton(menuItem, UIDROPDOWNMENU_MENU_LEVEL)

        menuItem = UIDropDownMenu_CreateInfo()
        menuItem.text = L["PPN_POPUP_EDIT"]
        menuItem.notCheckable = true
        menuItem.hasArrow = false
        menuItem.value = listedPlayer
        menuItem.func = function()
            if (listedPlayer) then
                PersonalPlayerNotes.db.profile.listedPlayer.id = listedPlayer.id
                PersonalPlayerNotes.db.profile.listedPlayer.name = listedPlayer.name
                PersonalPlayerNotes.db.profile.listedPlayer.realm = listedPlayer.realm
                PersonalPlayerNotes.db.profile.listedPlayer.reason = listedPlayer.reason
                PersonalPlayerNotes.db.profile.listedPlayer.description = listedPlayer.description
                PersonalPlayerNotes.db.profile.listedPlayer.color = listedPlayer.color
                PersonalPlayerNotes.db.profile.listedPlayer.alert = listedPlayer.alert

                AceConfigDialog:CloseAll()
                local AceGUI = PersonalPlayerNotes:AceGUIDefaults()
                AceGUI:SetTitle(L["PPN_LISTED_PLAYERS_TITLE"])
                AceConfigDialog:SetDefaultSize("PersonalPlayerNotesSettings Listed_Players", 500, 300)
                AceConfigDialog:Open("PersonalPlayerNotesSettings Listed_Players")
            end
        end
        UIDropDownMenu_AddButton(menuItem, UIDROPDOWNMENU_MENU_LEVEL)
    end
end

function PersonalPlayerNotes:GameTooltip()
    local _name, unit = self:GetUnit()
    if not (unit and UnitIsPlayer(unit)) then return end

    local name, realm = UnitFullName(unit)
    if (_name ~= name) then return end

    if (realm == nil) then realm = GetRealmName() end

    local listedPlayer = PersonalPlayerNotes:GetListedPlayer(name, realm)
    if (not listedPlayer) then return end

    local reason = PersonalPlayerNotes:GetReasons()[listedPlayer.reason]
    local _reason = reason
    local _listedPlayer = listedPlayer

    PersonalPlayerNotes:PrintDebug("|cffff0000<GameTooltip>|cffffffff Playername:", name, "Realm:", realm, "Reason:",
        _reason
        .reason,
        "Note:", _listedPlayer.description)

    -- Tooltip
    if not (_reason.reason == "None" and _listedPlayer.description == "") then
        self:AddLine("\n")
        self:AddDoubleLine(_reason.reason:gsub("None", ""), "|T" .. PersonalPlayerNotes.db.profile.icon .. ":0|t",
            _reason.color.r or 1, _reason.color.g or 1, _reason.color.b or 1)
        self:AddLine(_listedPlayer.description, _listedPlayer.color.r or 1, _listedPlayer.color.g or 1,
            _listedPlayer.color.b or 1, false)
    end

    -- Alert
    local time = time()
    local alert = PersonalPlayerNotes.db.profile.alert
    if (alert.enabled and reason.alert) then
        if (listedPlayer.alert and not alert.last[name]) then
            alert.last[name] = time + alert.delay
            PersonalPlayerNotes:ScheduleTimer("AlertDelayTimer", alert.delay, name)
            PersonalPlayerNotes:PlayAlertSoundEffect()
            PersonalPlayerNotes:PrintDebug("|cffff0000<ALERT>|cffffffff Sound effect disabled for player", name, "for",
                alert.delay,
                "seconds.")
        end
    end
end

function PersonalPlayerNotes:AlertDelayTimer(name)
    -- Called within ScheduleTimer and fires when timer ends.
    PersonalPlayerNotes:PrintDebug("|cffff0000<ALERT>|cffffffff Sound effect is now enabled for player", name)
    PersonalPlayerNotes.db.profile.alert.last[name] = nil
end

function PersonalPlayerNotes:MiniMapIcon()
    -- Create minimap launcher
    -- https://github.com/tekkub/libdatabroker-1-1/wiki/How-to-provide-a-dataobject
    return LibDataBroker:NewDataObject(personalPlayerNotes, {
        type = "launcher",
        text = L["PPN"],
        icon = PersonalPlayerNotes.db.profile.icon,
        OnClick = function(clickedframe, button)
            HideUIPanel(SettingsPanel)
            HideUIPanel(GameMenuFrame)
            AceConfigDialog:CloseAll()
            if button == "RightButton" then
                Settings.OpenToCategory(personalPlayerNotes)
            elseif button == "LeftButton" then
                local AceGUI = PersonalPlayerNotes:AceGUIDefaults()
                if IsShiftKeyDown() then
                    AceGUI:SetTitle(L["PPN_REASONS_TITLE"])
                    AceConfigDialog:SetDefaultSize("PersonalPlayerNotesSettings Reasons", 500, 200)
                    AceConfigDialog:Open("PersonalPlayerNotesSettings Reasons")
                elseif IsControlKeyDown() then
                    AceGUI:SetTitle(L["PPN_LISTED_PLAYERS_TITLE"])
                    AceConfigDialog:SetDefaultSize("PersonalPlayerNotesSettings Listed_Players", 500, 300)
                    AceConfigDialog:Open("PersonalPlayerNotesSettings Listed_Players")
                else
                    AceGUI:SetTitle(L["PPN_SETTINGS_TITLE"])
                    AceConfigDialog:SetDefaultSize("PersonalPlayerNotesSettings Options", 500, 350)
                    AceConfigDialog:Open("PersonalPlayerNotesSettings Options")
                end
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddDoubleLine(
                "|T" .. PersonalPlayerNotes.db.profile.icon .. ":0|t " .. L["PPN_MINIMAP_TOOLTIP_TITLE"],
                PersonalPlayerNotes:GetVersion())
            tooltip:AddLine("\n")
            tooltip:AddLine(L["PPN_MINIMAP_TOOLTIP_RIGHT_CLICK"])
            tooltip:AddLine(L["PPN_MINIMAP_TOOLTIP_LEFT_CLICK"])
            tooltip:AddLine(L["PPN_MINIMAP_TOOLTIP_SHIFT_LEFT_CLICK"])
            tooltip:AddLine(L["PPN_MINIMAP_TOOLTIP_CTRL_LEFT_CLICK"])
        end,
    })
end

function PersonalPlayerNotes:ToggleMiniMapIcon()
    self.db.profile.minimap.hide = not self.db.profile.minimap.hide
    self:LoadConfig()
end

function PersonalPlayerNotes:ToggleDebug()
    self.db.profile.debug = not self.db.profile.debug
    self:LoadConfig()
end
