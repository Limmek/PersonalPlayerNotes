local personalPlayerNotes = ...
PersonalPlayerNotes = LibStub("AceAddon-3.0"):NewAddon(
    personalPlayerNotes,
    "AceConsole-3.0",
    "AceEvent-3.0",
    "AceHook-3.0",
    "AceTimer-3.0",
    "AceSerializer-3.0"
)
local L = LibStub("AceLocale-3.0"):GetLocale(personalPlayerNotes, true)
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local LibDataBroker = LibStub("LibDataBroker-1.1")
local LibDBIcon = LibStub("LibDBIcon-1.0")

local IS_RETAIL = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE or false
PersonalPlayerNotes.IsRetail = IS_RETAIL

local function IconPrefix(icon)
    if not icon or icon == "" then
        return ""
    end
    return "|T" .. icon .. ":0|t "
end

--[[
    Ace3 lifecycle callback, fired once when the addon's SavedVariables have
    been loaded and it's about to be enabled. Sets up the AceDB profile,
    registers all Ace3 config panels/chat commands, migrates legacy Shitlist
    data if present, and does the initial LoadConfig().
]]
function PersonalPlayerNotes:OnInitialize()
    -- uses the "Default" profile instead of character-specific profiles
    -- https://www.wowace.com/projects/ace3/pages/api/ace-db-3-0
    self.db = LibStub("AceDB-3.0"):New("PersonalPlayerNotesDB", self.defaults, true)
    self.db.RegisterCallback(self, "OnNewProfile", "LoadConfig")
    self.db.RegisterCallback(self, "OnProfileChanged", "LoadConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "LoadConfig")
    self.db.RegisterCallback(self, "OnProfileReset", "LoadConfig")

    -- fills in any missing SavedVariables fields and runs schema migrations, if needed
    self:MigrateSavedVariablesSchema()

    -- registers an options table and adds it to the Blizzard options window
    -- https://www.wowace.com/projects/ace3/pages/api/ace-config-3-0
    AceConfig:RegisterOptionsTable("PersonalPlayerNotesSettings Info", self.options.Info)
    -- the 2nd return value is the registered category ID Settings.OpenToCategory()
    -- expects (a numeric ID/category object on modern clients) - the addon name
    -- string itself is NOT a valid argument, see OpenBlizzardOptions() below
    local _, blizOptionsCategoryID =
        AceConfigDialog:AddToBlizOptions("PersonalPlayerNotesSettings Info", personalPlayerNotes)
    self.blizOptionsCategoryID = blizOptionsCategoryID

    AceConfig:RegisterOptionsTable(
        "PersonalPlayerNotesSettings Options",
        self.options.Settings,
        { "ppno", "ppnoptions" }
    )
    AceConfigDialog:AddToBlizOptions("PersonalPlayerNotesSettings Options", L["PPN_MENU_SETTINGS"], personalPlayerNotes)

    AceConfig:RegisterOptionsTable(
        "PersonalPlayerNotesSettings Reasons",
        self.options.Reasons,
        { "ppnr", "ppnreasons" }
    )
    AceConfigDialog:AddToBlizOptions("PersonalPlayerNotesSettings Reasons", L["PPN_MENU_REASONS"], personalPlayerNotes)

    AceConfig:RegisterOptionsTable(
        "PersonalPlayerNotesSettings Listed_Players",
        self.options.ListedPlayers,
        { "ppnp", "ppnplayers" }
    )
    AceConfigDialog:AddToBlizOptions(
        "PersonalPlayerNotesSettings Listed_Players",
        L["PPN_MENU_LISTED_PLAYERS"],
        personalPlayerNotes
    )

    local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    AceConfig:RegisterOptionsTable("PersonalPlayerNotesSettings Profiles", profiles)
    AceConfigDialog:AddToBlizOptions(
        "PersonalPlayerNotesSettings Profiles",
        L["PPN_MENU_PROFILES"],
        personalPlayerNotes
    )

    LibDBIcon:Register(personalPlayerNotes, self:MiniMapIcon(), self.db.profile.minimap)

    self:RegisterChatCommand("ppn", function()
        PersonalPlayerNotes:OpenBlizzardOptions()
    end)
    self:RegisterChatCommand("ppnm", "ToggleMiniMapIcon")
    self:RegisterChatCommand("ppnminimap", "ToggleMiniMapIcon")
    self:RegisterChatCommand("ppndebug", "ToggleDebug")

    local loaded
    if self:HasModernAddOnAPI() then
        loaded = C_AddOns.LoadAddOn("Shitlist")
    else
        -- Some Classic clients don't expose the C_AddOns namespace yet.
        loaded = LoadAddOn("Shitlist")
    end
    if loaded then
        self:GetOldConfigData()
    end
    self:LoadConfig()
end

--[[
    Ace3 lifecycle callback, fired after OnInitialize() once the addon is
    actually enabled. Prints the startup banner and hooks whichever unit-menu
    and tooltip APIs this client actually supports (see the feature-detection
    helpers in PersonalPlayerNotesUtils.lua).
]]
function PersonalPlayerNotes:OnEnable()
    self:Print(L["PPN_CONFIG_LOADING"])
    self:Print(L["PPN_CONFIG_VERSION"], _G["ORANGE_FONT_COLOR_CODE"], self:GetVersion())
    self:Print(L["PPN_CONFIG_REASONS"], _G["GREEN_FONT_COLOR_CODE"], #self:GetReasons())
    self:Print(L["PPN_CONFIG_LISTEDPLAYERS"], _G["GREEN_FONT_COLOR_CODE"], #self:GetListedPlayers())

    -- Feature detection instead of a hardcoded Retail/Classic branch: some Classic
    -- clients have already picked up the modern Menu/Tooltip APIs, and future
    -- clients may too, so we check for the actual API surface instead.
    if self:HasModernMenuAPI() then
        -- New Menu System, introduced in Retail 11.0.0
        -- https://warcraft.wiki.gg/wiki/Patch_11.0.0/API_changes
        -- https://www.townlong-yak.com/framexml/latest/Blizzard_Menu/11_0_0_MenuImplementationGuide.lua
        self:DropDownMenuInitialize()
    elseif UnitPopup_ShowMenu then
        -- Legacy dropdown menu, still used on some Classic clients
        if not self:IsHooked("UnitPopup_ShowMenu") then
            self:SecureHook("UnitPopup_ShowMenu", self.UnitPopup_ShowMenu)
        end
    else
        self:PrintDebug("No supported unit menu API was found on this client.")
    end

    if self:HasModernTooltipAPI() then
        -- Retail 10.0.2 https://wowpedia.fandom.com/wiki/Patch_10.0.2/API_changes#Tooltip_Changes
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, self.GameTooltip)
    else
        GameTooltip:HookScript("OnTooltipSetUnit", self.GameTooltip)
    end
    self:Print(L["PPN_CONFIG_LOADED"])
end

--[[
    Ace3 lifecycle callback, fired when the addon is disabled (e.g. via
    /reload with the addon unchecked, or a manual :Disable() call).
]]
function PersonalPlayerNotes:OnDisable()
    self:Print(L["PPN_DISABLE"])
end

--[[
    Refreshes runtime state from the (possibly just-changed) AceDB profile:
    clears the alert cooldown table and shows/hides the minimap icon.
    Registered as the callback for AceDB's OnNewProfile/OnProfileChanged/
    OnProfileCopied/OnProfileReset events, and also called directly whenever
    a minimap-related setting changes.
]]
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

--[[
    One-time migration from the old "Shitlist" addon's SavedVariables
    (ShitlistDB) into this addon's reasons/listedPlayers tables. Called from
    OnInitialize() only after Shitlist itself was successfully loaded.
    Migrates the legacy Reasons/ListedPlayers tables directly, and offers a
    MIGRATE_PROFILES popup to copy over Shitlist's full AceDB profiles if
    ShitlistDB.profiles exists.
]]
function PersonalPlayerNotes:GetOldConfigData()
    -- Shitlist may be loadable without ever having saved any data (e.g. a fresh account).
    if not ShitlistDB then
        return
    end

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
                local name, realm = self:ParseLegacyPlayerKey(key)
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
                                icon = nil,
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
                            icon = nil,
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
    if ShitlistDB.profiles then
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
                if self:HasModernAddOnAPI() then
                    C_AddOns.DisableAddOn("Shitlist")
                else
                    -- Some Classic clients don't expose the C_AddOns namespace yet.
                    DisableAddOn("Shitlist")
                end
                if self:HasModernUIReloadAPI() then
                    C_UI.Reload()
                else
                    -- Some Classic clients don't expose the C_UI namespace yet.
                    ReloadUI()
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

--[[
    Copies a listedPlayers[] entry's fields onto the self.db.profile.listedPlayer
    mirror table and opens the "Listed Players" AceConfig dialog focused on it.
    Shared by the Add/Edit menu actions in both DropDownMenuInitialize() (modern
    Menu API) and UnitPopup_ShowMenu() (legacy dropdown API) to avoid
    duplicating this sync-then-open sequence in 4 separate closures.
]]
function PersonalPlayerNotes:SelectListedPlayerAndOpenDialog(player)
    self.db.profile.listedPlayer.id = player.id
    self.db.profile.listedPlayer.name = player.name
    self.db.profile.listedPlayer.realm = player.realm
    self.db.profile.listedPlayer.reason = player.reason
    self.db.profile.listedPlayer.description = player.description
    self.db.profile.listedPlayer.color = player.color
    self.db.profile.listedPlayer.alert = player.alert
    self.db.profile.listedPlayer.sound = player.sound
    self.db.profile.listedPlayer.icon = player.icon

    AceConfigDialog:CloseAll()
    self:CloseAllDialogs()
    AceConfigDialog:SetDefaultSize("PersonalPlayerNotesSettings Listed_Players", 500, 350)
    self:OpenDialog("PersonalPlayerNotesSettings Listed_Players")
end

--[[
    Registers the modern Menu API (Retail 11.0.0+) unit-menu entries for
    player/enemy-player/friend units, via Menu.ModifyMenu(). Only called from
    OnEnable() when HasModernMenuAPI() is true. Shares the same "Add"/"Edit"
    decision logic as the legacy UnitPopup_ShowMenu() fallback below, just
    driven by a rootDescription:CreateButton() menu instead of
    UIDropDownMenu_AddButton().
]]
function PersonalPlayerNotes:DropDownMenuInitialize()
    local DropDownMenu = function(ownerRegion, rootDescription, contextData)
        -- verify the unit
        if contextData.unit == nil or not UnitIsPlayer(contextData.unit) then
            return
        end
        -- retrieve name and realm from wow api
        local name, realm = UnitName(contextData.unit)
        -- if the unit is from the same realm then realm is empty, use current realm instead
        if realm == nil then
            realm = GetRealmName()
        end

        local listedPlayer = PersonalPlayerNotes:GetListedPlayer(name, realm)
        if not listedPlayer then
            rootDescription:CreateDivider()
            rootDescription:CreateTitle(L["PPN"])
            rootDescription:CreateButton(L["PPN_POPUP_ADD"], function()
                PersonalPlayerNotes:Print(L["PPN_POPUP_NEW_ADDED"], name, realm)

                local new_player = PersonalPlayerNotes:NewListedPlayer(name, realm)
                PersonalPlayerNotes:SelectListedPlayerAndOpenDialog(new_player)
            end)
        else
            rootDescription:CreateDivider()
            rootDescription:CreateTitle(L["PPN"])
            rootDescription:CreateButton(L["PPN_POPUP_EDIT"], function()
                PersonalPlayerNotes:SelectListedPlayerAndOpenDialog(listedPlayer)
            end)
        end
    end
    Menu.ModifyMenu("MENU_UNIT_PLAYER", function(...)
        DropDownMenu(...)
    end)
    Menu.ModifyMenu("MENU_UNIT_ENEMY_PLAYER", function(...)
        DropDownMenu(...)
    end)
    Menu.ModifyMenu("MENU_UNIT_FRIEND", function(...)
        DropDownMenu(...)
    end)
end

-- Classic Deprecated
--[[
    Legacy pre-Menu-API unit-menu handler, SecureHooked onto Blizzard's
    global UnitPopup_ShowMenu() from OnEnable() when HasModernMenuAPI() is
    false. Adds an "Add"/submenu entry for the targeted unit at the dropdown
    root, and an "Edit" button one level down for already-listed players.
]]
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
    if realm == nil then
        realm = GetRealmName()
    end
    local listedPlayer = PersonalPlayerNotes:GetListedPlayer(name, realm)

    PersonalPlayerNotes:PrintDebug("Name: ", name, ", Realm: ", realm)

    -- Check if this is the root level of the dropdown menu
    if UIDROPDOWNMENU_MENU_LEVEL == 1 then
        if listedPlayer then
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
                    PersonalPlayerNotes:SelectListedPlayerAndOpenDialog(new_player)
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
            if listedPlayer then
                PersonalPlayerNotes:SelectListedPlayerAndOpenDialog(listedPlayer)
            end
        end
        UIDropDownMenu_AddButton(menuItem, UIDROPDOWNMENU_MENU_LEVEL)
    end
end

--[[
    Tooltip hook body, registered via TooltipDataProcessor.AddTooltipPostCall()
    or GameTooltip:HookScript("OnTooltipSetUnit", ...) from OnEnable(). Called
    with the real tooltip frame as `self`. Adds the reason/description lines
    for a listed player being hovered, and plays an alert sound the first
    time a player with alerts enabled is seen. Unless alert.sessionOnly is
    set, an AlertDelayTimer cooldown lets the alert repeat every alert.delay
    seconds for the same player; with alert.sessionOnly, it only ever plays
    once per player until /reload or a profile change (see LoadConfig()).
]]
function PersonalPlayerNotes:GameTooltip()
    local _name, unit = self:GetUnit()
    if not unit or PersonalPlayerNotes:IsSecretUnit(unit) then
        return
    end

    if not UnitIsPlayer(unit) then
        return
    end

    local name, realm = UnitFullName(unit)
    if _name ~= name then
        return
    end

    if realm == nil then
        realm = GetRealmName()
    end

    local listedPlayer = PersonalPlayerNotes:GetListedPlayer(name, realm)
    if not listedPlayer then
        return
    end

    local reason = PersonalPlayerNotes:GetReasons()[listedPlayer.reason]
    local _reason = reason
    local _listedPlayer = listedPlayer

    PersonalPlayerNotes:PrintDebug(
        "|cffff0000<GameTooltip>|cffffffff Playername:",
        name,
        "Realm:",
        realm,
        "Reason:",
        _reason.reason,
        "Note:",
        _listedPlayer.description
    )

    -- Tooltip
    if not (_reason.reason == "None" and _listedPlayer.description == "") then
        local reasonText = IconPrefix(_reason.icon) .. _reason.reason:gsub("None", "")
        local noteText = IconPrefix(_listedPlayer.icon) .. _listedPlayer.description
        self:AddLine("\n")
        self:AddLine(reasonText, _reason.color.r or 1, _reason.color.g or 1, _reason.color.b or 1)
        self:AddLine(
            noteText,
            _listedPlayer.color.r or 1,
            _listedPlayer.color.g or 1,
            _listedPlayer.color.b or 1,
            false
        )
    end

    -- Alert
    local time = time()
    local alert = PersonalPlayerNotes.db.profile.alert
    if alert.enabled and reason.alert then
        if listedPlayer.alert and not alert.last[name] then
            if alert.sessionOnly then
                -- Never cleared until LoadConfig() resets alert.last on
                -- /reload or profile change, so this player won't alert
                -- again for the rest of the session.
                alert.last[name] = true
                PersonalPlayerNotes:PrintDebug(
                    "|cffff0000<ALERT>|cffffffff Sound effect disabled for player",
                    name,
                    "for the rest of the session."
                )
            else
                alert.last[name] = time + alert.delay
                PersonalPlayerNotes:ScheduleTimer("AlertDelayTimer", alert.delay, name)
                PersonalPlayerNotes:PrintDebug(
                    "|cffff0000<ALERT>|cffffffff Sound effect disabled for player",
                    name,
                    "for",
                    alert.delay,
                    "seconds."
                )
            end
            -- Player-specific sound wins, then the reason's, then the global default.
            PersonalPlayerNotes:PlayAlertSoundEffect(listedPlayer.sound or reason.sound or alert.sound)
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
    -- OnClick: right-click opens the Blizzard options fallback; left-click
    -- opens Settings/Reasons/Listed Players depending on shift/ctrl held.
    -- OnTooltipShow: renders the minimap icon's hover tooltip.
    return LibDataBroker:NewDataObject(personalPlayerNotes, {
        type = "launcher",
        text = L["PPN"],
        icon = PersonalPlayerNotes.db.profile.icon,
        OnClick = function(clickedframe, button)
            if SettingsPanel then
                HideUIPanel(SettingsPanel)
            end
            if GameMenuFrame then
                HideUIPanel(GameMenuFrame)
            end
            AceConfigDialog:CloseAll()
            PersonalPlayerNotes:CloseAllDialogs()
            if button == "RightButton" then
                PersonalPlayerNotes:OpenBlizzardOptions()
            elseif button == "LeftButton" then
                if IsShiftKeyDown() then
                    AceConfigDialog:SetDefaultSize("PersonalPlayerNotesSettings Reasons", 500, 250)
                    PersonalPlayerNotes:OpenDialog("PersonalPlayerNotesSettings Reasons")
                elseif IsControlKeyDown() then
                    AceConfigDialog:SetDefaultSize("PersonalPlayerNotesSettings Listed_Players", 500, 340)
                    PersonalPlayerNotes:OpenDialog("PersonalPlayerNotesSettings Listed_Players")
                else
                    AceConfigDialog:SetDefaultSize("PersonalPlayerNotesSettings Options", 500, 540)
                    PersonalPlayerNotes:OpenDialog("PersonalPlayerNotesSettings Options")
                end
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddDoubleLine(
                "|T" .. PersonalPlayerNotes.db.profile.icon .. ":0|t " .. L["PPN_MINIMAP_TOOLTIP_TITLE"],
                PersonalPlayerNotes:GetVersion()
            )
            tooltip:AddLine("\n")
            tooltip:AddLine(L["PPN_MINIMAP_TOOLTIP_RIGHT_CLICK"])
            tooltip:AddLine(L["PPN_MINIMAP_TOOLTIP_LEFT_CLICK"])
            tooltip:AddLine(L["PPN_MINIMAP_TOOLTIP_SHIFT_LEFT_CLICK"])
            tooltip:AddLine(L["PPN_MINIMAP_TOOLTIP_CTRL_LEFT_CLICK"])
        end,
    })
end

--[[
    Toggles the minimap icon's visibility (bound to /ppnm and /ppnminimap)
    and refreshes it via LoadConfig().
]]
function PersonalPlayerNotes:ToggleMiniMapIcon()
    self.db.profile.minimap.hide = not self.db.profile.minimap.hide
    self:LoadConfig()
end

--[[
    Toggles debug logging (bound to /ppndebug) and refreshes via LoadConfig().
]]
function PersonalPlayerNotes:ToggleDebug()
    self.db.profile.debug = not self.db.profile.debug
    self:LoadConfig()
end
