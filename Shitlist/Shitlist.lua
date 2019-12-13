local _, config = ...

Shitlist = CreateFrame('GameTooltip', 'Shitlist', UIParent, 'DialogBoxFrame')

Shitlist:RegisterEvent("ADDON_LOADED") -- Fired when saved variables are loaded
Shitlist:RegisterEvent("PLAYER_LOGOUT") -- Fired when about to log out

Shitlist:SetScript("OnEvent", function(self, event)
    if event == "ADDON_LOADED" then
        if _G.ShitlistDB["Reasons"] ~= nil then
            config.Reasons = _G.ShitlistDB["Reasons"]
        end
        if _G.ShitlistDB["ListedPlayers"] ~= nil then
            config.ListedPlayers = _G.ShitlistDB["ListedPlayers"]
        end
        if _G.ShitlistDB["TooltipTitle"] ~= nil then
            config.TooltipTitle = _G.ShitlistDB["TooltipTitle"]
        end
        if _G.ShitlistDB["AlertEnable"] ~= nil then
            config.AlertEnable = _G.ShitlistDB["AlertEnable"]
        end
        if _G.ShitlistDB["Sound"] ~= nil then
            config.Sound = _G.ShitlistDB["Sound"]
        end
        if _G.ShitlistDB["SoundID"] ~= nil then
            config.SoundID = _G.ShitlistDB["SoundID"]
        end
        if _G.ShitlistDB["PartyAlertEnable"] ~= nil then
            config.PartyAlertEnable = _G.ShitlistDB["PartyAlertEnable"]
        end
        if _G.ShitlistDB["IgnoreTime"] ~= nil then
            config.IgnoreTime = _G.ShitlistDB["IgnoreTime"]
        end
        if _G.ShitlistDB["PartyAlertEnable"] ~= nil then
            config.PartyAlertEnable = _G.ShitlistDB["PartyAlertEnable"]
        end
        if _G.ShitlistDB["TooltipTitleColor"] ~= nil then
            config.TooltipTitleColor = _G.ShitlistDB["TooltipTitleColor"]
        end
        if _G.ShitlistDB["TooltipTitleColorID"] ~= nil then
            config.TooltipTitleColorID = _G.ShitlistDB["TooltipTitleColorID"]
        end
        if _G.ShitlistDB["ReasonColor"] ~= nil then
            config.ReasonColor = _G.ShitlistDB["ReasonColor"]
        end
        if _G.ShitlistDB["ReasonColorID"] ~= nil then
            config.ReasonColorID = _G.ShitlistDB["ReasonColorID"]
        end
        if _G.ShitlistDB["PopupMenus"] ~= nil then
            config.PopupMenus = _G.ShitlistDB["PopupMenus"]
        end
        if _G.ShitlistDB["MenuOptions"] ~= nil then
            config.MenuOptions = _G.ShitlistDB["MenuOptions"]
        end
                
        -- Set global settings values
        SettingsTooltipTitleEditBox:SetText(config.TooltipTitle)
        SettingsTooltipTitleEditBox:SetCursorPosition(0)
        
        UIDropDownMenu_Initialize(SettingsTooltipTitleColorDropDown, initializeColors)
        UIDropDownMenu_SetSelectedID(SettingsTooltipTitleColorDropDown, config.TooltipTitleColorID)

        SettingsSoundCheckBox:SetChecked(config.AlertEnable)
        SettingsSoundEditBox:SetText(config.IgnoreTime)
        SettingsSoundEditBox:SetCursorPosition(0)
        
        UIDropDownMenu_Initialize(SettingsSoundDropDown, initializeSounds)
        UIDropDownMenu_SetSelectedID(SettingsSoundDropDown, config.SoundID)
        
        SettingsPartyCheckBox:SetChecked(config.PartyAlertEnable)
        SettingsPartyEditBox:SetText(config.PartyIgnoreTime)
        SettingsPartyEditBox:SetCursorPosition(0)

        SettingsTargetCheckBox:SetChecked(config.PopupMenus.target)
        SettingsChatCheckBox:SetChecked(config.PopupMenus.chat)

        SettingsIconCheckBox:SetChecked(config.MenuOptions.icon)

        -- Reason values
        UIDropDownMenu_Initialize(SettingsReasonDropDown, initializeReasons)
        UIDropDownMenu_SetSelectedID(SettingsReasonDropDown, 1)
        UIDropDownMenu_Initialize(SettingsReasonColorDropDown, initializeReasonColor)
        UIDropDownMenu_SetSelectedID(SettingsReasonColorDropDown, config.ReasonColorID)

        -- Listed Player values
        UIDropDownMenu_Initialize(SettingsListedPlayerDropDown, initializePlayer)
        UIDropDownMenu_SetSelectedID(SettingsListedPlayerDropDown, 1)
        SettingsListedPlayerDescriptionEditBox:SetCursorPosition(0)

    elseif event == "PLAYER_LOGOUT" then
        --_G.ShitlistDB = config -- Save whole config to SavedVariables
        _G.ShitlistDB["TooltipTitle"] = config.TooltipTitle
        _G.ShitlistDB["Reasons"] = config.Reasons
        _G.ShitlistDB["ListedPlayers"] = config.ListedPlayers
        _G.ShitlistDB["AlertEnable"] = config.AlertEnable
        _G.ShitlistDB["Sound"] = config.Sound
        _G.ShitlistDB["SoundID"] = config.SoundID
        _G.ShitlistDB["PartyAlertEnable"] = config.PartyAlertEnable
        _G.ShitlistDB["IgnoreTime"] = config.IgnoreTime
        _G.ShitlistDB["PartyAlertEnable"] = config.PartyAlertEnable
        _G.ShitlistDB["TooltipTitleColor"] = config.TooltipTitleColor
        _G.ShitlistDB["TooltipTitleColorID"] = config.TooltipTitleColorID
        _G.ShitlistDB["ReasonColor"] = config.ReasonColor
        _G.ShitlistDB["ReasonColorID"] = config.ReasonColorID
        _G.ShitlistDB["PopupMenus"] = config.PopupMenus
        _G.ShitlistDB["MenuOptions"] = config.MenuOptions
    end
end)

-- Add info to tooltip
function ShowPlayerTooltip(self)
	local name, unit = self:GetUnit()
	if UnitIsPlayer(unit) and not UnitIsUnit(unit, "player") then
		local name, realm = UnitName(unit)
		name = name .. "-" .. (realm or GetRealmName())
		if config.ListedPlayers[name] and type(next(config.ListedPlayers)) ~= "nil" then
            self:AddLine(config.TooltipTitle, config.Colors[config.TooltipTitleColor].red, config.Colors[config.TooltipTitleColor].green, config.Colors[config.TooltipTitleColor].blue, true)
            for i,value in ipairs(config.ListedPlayers[name]) do
                if i == 1 then 
                    self:AddLine(value, config.Colors[config.ReasonColor].red, config.Colors[config.ReasonColor].green, config.Colors[config.ReasonColor].blue, true)
                else
                    self:AddLine(value, config.Colors[config.DefaultColor].red, config.Colors[config.DefaultColor].green, config.Colors[config.DefaultColor].blue, true)
                end
            end
            
            -- Play sound efect
            if config.AlertEnable and time() >= config.Start and config.AlertLastSentName ~= name then
                --PlaySound(8959, "Master", forceNoDuplicates, runFinishCallback)
                PlaySoundFile(config.Sound, config.SoundChannel)
                config.Start = time() + config.IgnoreTime
                config.AlertLastSentName = name
            end

            -- Send party message
            if IsInGroup() and config.PartyAlertEnable and time() >= config.PartyStart and config.PartyAlertLastSentName ~= name then
                SendChatMessage(config.TooltipTitle .. " " .. name, "PARTY", GetDefaultLanguage(unit))
                for k,v in ipairs(config.ListedPlayers[name]) do
                    SendChatMessage(v, "PARTY", GetDefaultLanguage(unit))
                end
                config.PartyStart = time() + config.PartyIgnoreTime
                config.PartyAlertLastSentName = name
            end

        end
	end
end

GameTooltip:HookScript("OnTooltipSetUnit", ShowPlayerTooltip)

-- Add to player context menu
function ShitlistDropdownMenuButtonKlick(self)
    name = self.value
    if not config.ListedPlayers[name] then
        Shitlist:Toggle()
    else
        print("Removed " .. name)
        config.ListedPlayers[name] = nil
    end
end

function ShitlistDropdownMenuButton(name)
    local info = UIDropDownMenu_CreateInfo()
    info.owner = which
    info.notCheckable = 1
    info.func = ShitlistDropdownMenuButtonKlick 
    if config.ListedPlayers[name] then
        info.text = "Remove from Shitlist"
        info.colorCode = config.MenuOptions.remove_color
        info.value = name
    else
        info.text = "Add to Shitlist"
        info.colorCode = config.MenuOptions.add_color
        info.value = name
        if config.MenuOptions.icon then
            info.icon = config.Icon
        end
    end
    UIDropDownMenu_AddButton(info)
end

hooksecurefunc("UnitPopup_ShowMenu", function(self, event)
    if (UIDROPDOWNMENU_MENU_LEVEL > 1) then
        return
    end
    if (config.PopupMenus.target and event ~= "FRIEND" and UnitIsPlayer("target") and not UnitIsUnit("target", "player")) then
        local name, realm = UnitName("target")
        name = name .. "-" .. (realm or GetRealmName())
        ShitlistDropdownMenuButton(name)
    end
    if (config.PopupMenus.chat and event == "FRIEND" and not UnitIsUnit("target", "player")) then
        local name = self.name .. "-" .. (self.realm or GetRealmName())
        ShitlistDropdownMenuButton(name)
    end
end)

-- Shitlist UI
function Shitlist:CreateUI()
    shitlistUI = CreateFrame("Frame", "ShitlistUI", UIParent)
    shitlistUI:ClearAllPoints()
    shitlistUI:SetHeight(180)
    shitlistUI:SetWidth(320)
    shitlistUI:SetPoint("CENTER")
    shitlistUI:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight", -- this one is neat
        edgeSize = 16,
        insets = { left = 8, right = 6, top = 8, bottom = 8 },
    })
    shitlistUI:SetBackdropBorderColor(getConfigColors("Light_Blue")) -- darkblue
    shitlistUI:SetMovable(true)
    shitlistUI:EnableMouse(true)
    shitlistUI:RegisterForDrag("LeftButton")
    shitlistUI:SetScript("OnDragStart", shitlistUI.StartMoving)
    shitlistUI:SetScript("OnDragStop", shitlistUI.StopMovingOrSizing)

    local title = shitlistUI:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    --title:SetFontObject("GameFontHighlight")
    title:SetPoint("CENTER", shitlistUI, "TOP", 0, -20)
    title:SetFont("Interface\\AddOns\\Shitlist\\Fonts\\Inconsolata-Bold.ttf", 12)
    title:SetTextColor(getConfigColors("White"))
    title:SetText("Add new player notice")

    -- Title
    playerText = shitlistUI:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
    playerText:SetPoint("TOP", shitlistUI, 0, -35)
    playerText:SetFont("Interface\\AddOns\\Shitlist\\Fonts\\Inconsolata-Bold.ttf", 16)
    playerText:SetTextColor(getConfigColors("Gold"))
    playerText:SetText(name)

    -- Reasons drop-down menu
    reasons = CreateFrame("Button", nil, shitlistUI, "UIDropDownMenuTemplate")
    reasons:SetPoint("TOP", 0, -60)

    local function OnClick(self)
        UIDropDownMenu_SetSelectedID(reasons, self:GetID())
    end

    local function initialize(self)
        local info = UIDropDownMenu_CreateInfo()
        for k,v in pairs(config.Reasons) do
            info = UIDropDownMenu_CreateInfo()
            info.text = v
            info.value = v
            info.func = OnClick
            UIDropDownMenu_AddButton(info)
        end
    end

    UIDropDownMenu_Initialize(reasons, initialize)
    UIDropDownMenu_SetWidth(reasons, 160)
    UIDropDownMenu_SetButtonWidth(reasons, 184)
    UIDropDownMenu_SetSelectedID(reasons, 1)
    UIDropDownMenu_JustifyText(reasons, "LEFT")

    -- EditBox
    noticeEditBox = CreateFrame("EditBox", "TooltipTitleEditBox", shitlistUI)
    noticeEditBox:SetPoint("CENTER", 0, -15)
    noticeEditBox:SetSize(250, 30)
    noticeEditBox:SetTextInsets(4, 0, 0, 0) 
    noticeEditBox:SetBackdrop({
		bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile="Interface\\PVPFrame\\UI-Character-PVP-Highlight", 
		tile = false, tileSize = 0, edgeSize = 8,
		insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    noticeEditBox:SetBackdropBorderColor(getConfigColors("Light_Blue"))
    noticeEditBox:SetMultiLine(false)
    noticeEditBox:SetMaxLetters(255)
    noticeEditBox:SetAutoFocus(false) -- dont automatically focus
    noticeEditBox:SetFontObject(GameFontWhite)
    noticeEditBox:SetScript("OnEscapePressed", function(self) Shitlist:Toggle() end)
	noticeEditBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

    local saveBtn = CreateFrame("Button", nil, shitlistUI, "OptionsButtonTemplate")
    saveBtn:SetPoint("CENTER", shitlistUI, "BOTTOM", -55, 35)
    saveBtn:SetSize(100, 30)
    saveBtn:SetText("Save")
    saveBtn:SetNormalFontObject("GameFontNormal")
    saveBtn:SetHighlightFontObject("GameFontHighlight")
    saveBtn:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            local reason = reasons.Text:GetText()
            local desc = noticeEditBox:GetText()
            print("Added " .. name .. "\n" .. reason .. "\n" .. desc)
            config.ListedPlayers[name] = {reason, desc}
            HideParentPanel(self)
            Shitlist:Reset()
        end
    end)

    local cancelBtn = CreateFrame("Button", nil, shitlistUI, "OptionsButtonTemplate")
    cancelBtn:SetPoint("CENTER", shitlistUI, "BOTTOM", 55, 35)
    cancelBtn:SetSize(100, 30)
    cancelBtn:SetText("Cancel")
    cancelBtn:SetNormalFontObject(GameFontNormal)
    cancelBtn:SetHighlightFontObject(GameFontHighlight)
    cancelBtn:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            HideParentPanel(self)
            Shitlist:Reset()
        end
    end)
    shitlistUI:Hide()
    return shitlistUI
end

function Shitlist:Reset()
    UIDropDownMenu_SetSelectedID(reasons, 1)
    noticeEditBox:SetText("")
end

function Shitlist:Toggle()
    local shitlist = shitlistUI or Shitlist:CreateUI()
    shitlist:SetShown(not shitlist:IsShown())
    playerText:SetText(name)
end
