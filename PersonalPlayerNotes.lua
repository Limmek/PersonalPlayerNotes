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

--[[
    Renders `icon` (a texture path or fileID) as an inline tooltip icon
    glyph (WoW's "|T...|t" escape sequence) followed by a trailing space,
    or an empty string if no icon is set - used to prefix the reason/note
    lines GameTooltip() adds for a listed player.
]]
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
    -- the Changelog is an inline panel on the main Info page (alongside
    -- Commands/About), not its own Blizzard options category, so these just
    -- open the same Info page
    self:RegisterChatCommand("ppnc", function()
        PersonalPlayerNotes:OpenBlizzardOptions()
    end)
    self:RegisterChatCommand("ppnchangelog", function()
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
    self:Print(
        L["PPN_CONFIG_VERSION"],
        _G["ORANGE_FONT_COLOR_CODE"] .. self:GetVersion() .. _G["FONT_COLOR_CODE_CLOSE"],
        "|",
        L["PPN_CONFIG_REASONS"],
        _G["GREEN_FONT_COLOR_CODE"] .. #self:GetReasons() .. _G["FONT_COLOR_CODE_CLOSE"],
        "|",
        L["PPN_CONFIG_LISTEDPLAYERS"],
        _G["GREEN_FONT_COLOR_CODE"] .. #self:GetListedPlayers() .. _G["FONT_COLOR_CODE_CLOSE"]
    )

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
    Resolves the player name/realm a modern Menu API contextData refers to,
    whether it carries a real unit token (Target/Party/Raid/nameplate/etc.
    frames) or not (Friends List entries, chat player-name links, and
    channel/community/guild roster clicks only ever provide contextData.name,
    see UnitPopupManager:OpenMenu() in Blizzard_UnitPopupShared). Returns
    nil, nil if no usable player name could be determined.
]]
function PersonalPlayerNotes:ResolveContextDataPlayer(contextData)
    if contextData.unit ~= nil then
        if not UnitIsPlayer(contextData.unit) then
            return nil, nil
        end
        local name, realm = UnitName(contextData.unit)
        -- if the unit is from the same realm then realm is empty, use current realm instead
        if realm == nil then
            realm = GetRealmName()
        end
        return name, realm
    end

    local name = contextData.name
    if type(name) ~= "string" or name == "" then
        return nil, nil
    end

    -- Cross-realm names already come as "Name-Realm" (e.g. cross-realm chat
    -- or BGs); contextData never carries a separate realm field when there's
    -- no unit token, so split it the same way legacy Shitlist keys are.
    local parsedName, parsedRealm = self:ParseLegacyPlayerKey(name)
    if parsedName and parsedRealm then
        return parsedName, parsedRealm
    end

    return name, GetRealmName()
end

--[[
    True when a MENU_UNIT_FRIEND(_OFFLINE) contextData came from a chat
    player-name click rather than an actual Friends list entry - Blizzard
    funnels both through the same menu tag, distinguished only by the
    chat-specific fields that only chat clicks set.
]]
local function IsChatContextData(contextData)
    return contextData.chatType ~= nil or contextData.chatFrame ~= nil or contextData.lineID ~= nil
end

--[[
    Registers the modern Menu API (Retail 11.0.0+) unit-menu entries for
    player units, via Menu.ModifyMenu(). Only called from OnEnable() when
    HasModernMenuAPI() is true; shares the same Add/Edit logic as the
    legacy UnitPopup_ShowMenu() fallback below.

    Menu tags fire based on the *relationship* between the player and the
    right-clicked unit, not the frame clicked - e.g. right-clicking the
    Target frame while targeting a party member fires MENU_UNIT_PARTY, the
    same tag the Party frame itself uses, hence one contextMenu.party toggle
    covers both.
]]
function PersonalPlayerNotes:DropDownMenuInitialize()
    local function BuildMenu(ownerRegion, rootDescription, contextData)
        local name, realm = PersonalPlayerNotes:ResolveContextDataPlayer(contextData)
        if not name then
            return
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

    -- Always available: ordinary world/nameplate players, friendly or
    -- hostile, that aren't currently in your party/raid.
    Menu.ModifyMenu("MENU_UNIT_PLAYER", function(...)
        BuildMenu(...)
    end)
    Menu.ModifyMenu("MENU_UNIT_ENEMY_PLAYER", function(...)
        BuildMenu(...)
    end)

    -- Party/raid group members - also covers the Target/Focus frame's menu
    -- while it's showing a group member, since Blizzard tags that the same
    -- way (see the module doc comment above).
    local function PartyGatedMenu(ownerRegion, rootDescription, contextData)
        if not PersonalPlayerNotes.db.profile.contextMenu.party then
            return
        end
        BuildMenu(ownerRegion, rootDescription, contextData)
    end
    Menu.ModifyMenu("MENU_UNIT_PARTY", PartyGatedMenu)
    Menu.ModifyMenu("MENU_UNIT_RAID_PLAYER", PartyGatedMenu)

    -- Friends list entries and chat player-name links both use the same
    -- "FRIEND"/"FRIEND_OFFLINE" menu tags, so they're told apart here via
    -- contextData instead of via tag (see IsChatContextData() above).
    local function FriendOrChatGatedMenu(ownerRegion, rootDescription, contextData)
        local contextMenu = PersonalPlayerNotes.db.profile.contextMenu
        local enabled
        if IsChatContextData(contextData) then
            enabled = contextMenu.chat
        else
            enabled = contextMenu.friends
        end
        if not enabled then
            return
        end
        BuildMenu(ownerRegion, rootDescription, contextData)
    end
    Menu.ModifyMenu("MENU_UNIT_FRIEND", FriendOrChatGatedMenu)
    Menu.ModifyMenu("MENU_UNIT_FRIEND_OFFLINE", FriendOrChatGatedMenu)

    -- Channel/community/guild chat roster right-clicks.
    Menu.ModifyMenu("MENU_UNIT_CHAT_ROSTER", function(ownerRegion, rootDescription, contextData)
        if not PersonalPlayerNotes.db.profile.contextMenu.chat then
            return
        end
        BuildMenu(ownerRegion, rootDescription, contextData)
    end)
end

-- Classic Deprecated
--[[
    Legacy pre-Menu-API unit-menu handler, SecureHooked onto Blizzard's
    global UnitPopup_ShowMenu() when HasModernMenuAPI() is false. Adds an
    Add/submenu entry at the dropdown root, and an Edit button one level
    down for already-listed players.

    Unlike DropDownMenuInitialize(), this hooks one global function called
    for every menu tag, so `target` is checked manually instead of
    registering per-tag. Chat and Friends-list can't be told apart on this
    legacy API, so contextMenu.chat/friends are treated as one toggle here.
]]
function PersonalPlayerNotes:UnitPopup_ShowMenu(target, unit, menuList)
    PersonalPlayerNotes:PrintDebug("Unit: ", unit, ", Target: ", target)
    -- verify the target
    if target == "SELF" or target == "COMMUNITIES_GUILD_MEMBER" then
        return
    end
    local contextMenu = PersonalPlayerNotes.db.profile.contextMenu
    if (target == "PARTY" or target == "RAID_PLAYER") and not contextMenu.party then
        return
    end
    if
        (target == "FRIEND" or target == "FRIEND_OFFLINE" or target == "CHAT_ROSTER")
        and not (contextMenu.friends or contextMenu.chat)
    then
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
    Tooltip hook body, registered from OnEnable() via
    TooltipDataProcessor.AddTooltipPostCall() or GameTooltip's OnTooltipSetUnit
    script. Called with the real tooltip frame as `self`. Adds reason/note
    lines for a listed player being hovered, and plays an alert sound the
    first time one with alerts enabled is seen - repeating every alert.delay
    seconds unless alert.sessionOnly is set (then only once per session,
    see LoadConfig()).
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
    -- Alert can be enabled independently on the reason and on the listed
    -- player (e.g. a player can alert even when their reason is "None",
    -- which always defaults to alert = false). If either one is enabled,
    -- the player alerts; only a single sound ever plays, and the player's
    -- alert (and its sound inheritance chain) takes priority over the
    -- reason's when both are enabled, so we never play two warning sounds.
    if alert.enabled and (reason.alert or listedPlayer.alert) and not alert.last[name] then
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
        local sound
        if listedPlayer.alert then
            -- Player-specific sound wins, then the reason's, then the global default.
            sound = listedPlayer.sound or reason.sound or alert.sound
        else
            -- Player's alert is off; only the reason (and its own
            -- inherited fallback) triggered this, so ignore any leftover
            -- player-specific sound the player didn't opt into.
            sound = reason.sound or alert.sound
        end
        PersonalPlayerNotes:PlayAlertSoundEffect(sound)
    end
end

--[[
    ScheduleTimer callback (see GameTooltip()'s alert.delay handling) that
    clears a player's alert cooldown once it expires, letting their alert
    sound play again the next time their tooltip is shown.
]]
function PersonalPlayerNotes:AlertDelayTimer(name)
    PersonalPlayerNotes:PrintDebug("|cffff0000<ALERT>|cffffffff Sound effect is now enabled for player", name)
    PersonalPlayerNotes.db.profile.alert.last[name] = nil
end

--[[
    Builds the LibDataBroker-1.1 data object for the minimap launcher icon
    (see https://github.com/tekkub/libdatabroker-1-1/wiki/How-to-provide-a-dataobject),
    registered with LibDBIcon-1.0 in OnInitialize(). OnClick routes
    left/right-click and shift/ctrl-modified left-clicks to the Blizzard
    options fallback or one of the three custom option windows;
    OnTooltipShow renders its hover tooltip.
]]
function PersonalPlayerNotes:MiniMapIcon()
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
                    AceConfigDialog:SetDefaultSize("PersonalPlayerNotesSettings Options", 500, 550)
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
