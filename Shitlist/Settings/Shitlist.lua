local _, config = ...

-- Shitlist Settings - General

ShitlistSettings.panel = CreateFrame( "Frame", "ShitlistSettingsPanel", UIParent )

-- Register in the Interface Addon Options GUI
-- Set the name for the Category for the Options Panel
ShitlistSettings.panel.name = "Shitlist"

-- Add the panel to the Interface Options
InterfaceOptions_AddCategory(ShitlistSettings.panel)

-- Tabb Title
local GeneralTabbTitle = ShitlistSettings.panel:CreateFontString("SettingsGeneralTabbTitle", "OVERLAY", "GameFontNormal")
GeneralTabbTitle:SetPoint("TOPLEFT", ShitlistSettings.panel, 10, -10)
GeneralTabbTitle:SetFont(config.Font, 18)
GeneralTabbTitle:SetTextColor(getConfigColors("Gold"))
GeneralTabbTitle:SetText("Shitlist - General") -- Add localization

-- Version
local version = ShitlistSettings.panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
version:SetPoint("BOTTOMRIGHT", ShitlistSettings.panel, -5, 5)
version:SetFont(config.Font, 11)
version:SetTextColor(getConfigColors("White"))
version:SetText("Version: " .. GetAddOnMetadata("Shitlist", "Version")) -- Add localization

---------

-- Tooltip settings
local TooltipFrame = CreateFrame("Frame", "SettingsTooltipFrame", ShitlistSettings.panel)
TooltipFrame:SetPoint("TOPLEFT", ShitlistSettings.panel, 10, -35)
TooltipFrame:SetSize(500, 125)

-- Title
local TooltipTitle = TooltipFrame:CreateFontString("SettingsTooltipTitle", "OVERLAY", "GameFontNormal")
TooltipTitle:SetPoint("TOPLEFT", TooltipFrame, 10, -10)
TooltipTitle:SetFont(config.Font, 14)
TooltipTitle:SetText("Tooltip") -- Add localization

-- Info
local TooltipInfo = TooltipFrame:CreateFontString("SettingsTooltipInfo", "OVERLAY", "GameFontWhite")
TooltipInfo:SetPoint("TOPLEFT", TooltipFrame, 15, -30)
TooltipInfo:SetTextColor(getConfigColors("White"))
TooltipInfo:SetText("Set title in the Tooltip message. #Shitlist") -- Add localization

-- Tooltip text
local TooltipTitleEditBox = CreateFrame("EditBox", "SettingsTooltipTitleEditBox", TooltipFrame)
TooltipTitleEditBox:SetPoint("TOPLEFT", 15, -50)
TooltipTitleEditBox:SetSize(200, 30)
TooltipTitleEditBox:SetTextInsets(10, 0, 0, 0) 
TooltipTitleEditBox:SetBackdrop(config.Backdrop)
TooltipTitleEditBox:SetBackdropBorderColor(getConfigColors("White"))
TooltipTitleEditBox:SetMultiLine(false)
TooltipTitleEditBox:SetMaxLetters(50)
TooltipTitleEditBox:SetAutoFocus(false)
TooltipTitleEditBox:SetFontObject(GameFontWhite)
TooltipTitleEditBox:SetScript("OnEscapePressed", function(self)
    config.TooltipTitle = self:GetText()
    self:ClearFocus()
end)
TooltipTitleEditBox:SetScript("OnEnterPressed", function(self) 
    config.TooltipTitle = self:GetText()
    self:ClearFocus()
end)
TooltipTitleEditBox:SetScript("OnMouseDown", function(self) 
    self:SetText(config.TooltipTitle)
end)

-- Info
local TooltipTitleColorInfo = TooltipFrame:CreateFontString("SettingsTooltipTitleColorInfo", "OVERLAY", "GameFontWhite")
TooltipTitleColorInfo:SetPoint("TOPLEFT", TooltipFrame, TooltipTitleEditBox:GetWidth()+85, -30)
TooltipTitleColorInfo:SetTextColor(getConfigColors("White"))
TooltipTitleColorInfo:SetText("Title color") -- Add localization

-- Title color
local TooltipTitleColorDropDown = CreateFrame("Button", "SettingsTooltipTitleColorDropDown", TooltipFrame, "UIDropDownMenuTemplate")
TooltipTitleColorDropDown:SetPoint("TOPLEFT", TooltipFrame, TooltipTitleEditBox:GetWidth()+70, -50)

local function OnClick(self)
    UIDropDownMenu_SetSelectedID(TooltipTitleColorDropDown, self:GetID())
    config.TooltipTitleColor = self:GetText()
    config.TooltipTitleColorID = self:GetID()
end

function initializeColors(self)
    local info = UIDropDownMenu_CreateInfo()
    for k,v in pairs(config.Colors) do
        info = UIDropDownMenu_CreateInfo()
        info.text = k
        info.value = getConfigColors(v)
        info.func = OnClick
        UIDropDownMenu_AddButton(info)
    end
end

UIDropDownMenu_Initialize(TooltipTitleColorDropDown, initializeColors)
UIDropDownMenu_SetWidth(TooltipTitleColorDropDown, 100)
UIDropDownMenu_SetButtonWidth(TooltipTitleColorDropDown, 115)
UIDropDownMenu_SetSelectedID(TooltipTitleColorDropDown, 1)
UIDropDownMenu_JustifyText(TooltipTitleColorDropDown, "LEFT")

-----------------

-- Audio settings
local AudioFrame = CreateFrame("Frame", "SettingsAudioFrame", ShitlistSettings.panel)
AudioFrame:SetPoint("TOPLEFT", ShitlistSettings.panel, 10, -TooltipFrame:GetHeight())
AudioFrame:SetSize(450, 140)

-- Title
local SoundTitle = AudioFrame:CreateFontString("SettingsSoundTitle", "OVERLAY", "GameFontNormal")
SoundTitle:SetPoint("TOPLEFT", AudioFrame, 10, -10)
SoundTitle:SetFont(config.Font, 14)
SoundTitle:SetText("Sound") -- Add localization

-- Info
local SoundInfo = AudioFrame:CreateFontString("SettingsSoundInfo", "OVERLAY", "GameFontWhite")
SoundInfo:SetPoint("TOPLEFT", AudioFrame, 15, -30)
SoundInfo:SetTextColor(getConfigColors("White"))
SoundInfo:SetText("Is not played if the player is the same since last warning was played and wait time is passed.") -- Add localization

-- Sound
local SoundCheckBox = CreateFrame("CheckButton", "SettingsSoundCheckBox", AudioFrame, "ChatConfigCheckButtonTemplate")
SoundCheckBox:SetPoint("TOPLEFT", 25, -60)
getglobal(SoundCheckBox:GetName().."Text"):SetText("Enable Audio"); -- Add localization
SoundCheckBox.tooltip = "Plays sound efect when a listed player is found" -- Add localization
SoundCheckBox:SetScript("OnClick", function(self)
    if config.AlertEnable == false then 
        config.AlertEnable = true
        self:SetChecked(config.AlertEnable)
    else
        config.AlertEnable = false
        self:SetChecked(config.AlertEnable)
    end
end)

-- Info
local SoundEditBoxInfo = AudioFrame:CreateFontString("SettingsSoundEditBoxInfo", "OVERLAY", "GameFontWhite")
SoundEditBoxInfo:SetPoint("TOPLEFT", AudioFrame, 280, -65)
SoundEditBoxInfo:SetTextColor(getConfigColors("White"))
SoundEditBoxInfo:SetText("Sleep for x seconds") -- Add localization

-- Ignore time
local SoundEditBox = CreateFrame("EditBox", "SettingsSoundEditBox", AudioFrame)
SoundEditBox:SetPoint("TOPLEFT", 280, -90)
SoundEditBox:SetSize(80, 30)
SoundEditBox:SetTextInsets(10, 0, 0, 0) 
SoundEditBox:SetBackdrop(config.Backdrop)
SoundEditBox:SetBackdropBorderColor(getConfigColors("White"))
SoundEditBox:SetMultiLine(false)
SoundEditBox:SetMaxLetters(5)
SoundEditBox:SetAutoFocus(false)
SoundEditBox:SetFontObject(GameFontWhite)
SoundEditBox:SetScript("OnEscapePressed", function(self)
    config.IgnoreTime = self:GetText()
    self:ClearFocus()
end)
SoundEditBox:SetScript("OnEnterPressed", function(self) 
    config.IgnoreTime = self:GetText()
    self:ClearFocus()
end)
SoundEditBox:SetScript("OnMouseDown", function(self) 
    self:SetText(config.IgnoreTime)
end)

-- Sounds
local SoundDropDown = CreateFrame("Button", "SettingsSoundDropDown", AudioFrame, "UIDropDownMenuTemplate")
SoundDropDown:SetPoint("TOPLEFT", AudioFrame, 10, -90)

local function OnClick(self)
    UIDropDownMenu_SetSelectedID(SoundDropDown, self:GetID())
    PlaySoundFile(config.Sounds[self:GetText()], config.Channel)
    config.Sound = config.Sounds[self:GetText()]
    config.SoundID = self:GetID()
end

function initializeSounds(self)
    local info = UIDropDownMenu_CreateInfo()
    for k,v in pairs(config.Sounds) do
        info = UIDropDownMenu_CreateInfo()
        info.text = k
        info.value = v
        info.func = OnClick
        UIDropDownMenu_AddButton(info)
    end
end

UIDropDownMenu_Initialize(SoundDropDown, initializeSounds)
UIDropDownMenu_SetWidth(SoundDropDown, 160)
UIDropDownMenu_SetButtonWidth(SoundDropDown, 185)
UIDropDownMenu_SetSelectedID(SoundDropDown, 1)
UIDropDownMenu_JustifyText(SoundDropDown, "LEFT")

--------------------

-- Party settings
local PartyFrame = CreateFrame("Frame", "SettingsPartyFrame", ShitlistSettings.panel)
PartyFrame:SetPoint("TOPLEFT", ShitlistSettings.panel, 10, -AudioFrame:GetHeight()+-TooltipFrame:GetHeight())
PartyFrame:SetSize(450, 100)

-- Title
local PartyTitle = PartyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
PartyTitle:SetPoint("TOPLEFT", PartyFrame, 10, -10)
PartyTitle:SetFont(config.Font, 14)
PartyTitle:SetText("Party") -- Add localization

-- Info
local PartyInfo = PartyFrame:CreateFontString("SettingsPartyInfo", "OVERLAY", "GameFontWhite")
PartyInfo:SetPoint("TOPLEFT", PartyFrame, 15, -30)
PartyInfo:SetTextColor(getConfigColors("White"))
PartyInfo:SetText("Message is not sent if the player is the same since last message was sent and wait time is passed.") -- Add localization

-- Party
local PartyCheckBox = CreateFrame("CheckButton", "SettingsPartyCheckBox", PartyFrame, "ChatConfigCheckButtonTemplate")
PartyCheckBox:SetPoint("TOPLEFT", 25, -60)
getglobal(PartyCheckBox:GetName().."Text"):SetText("Enable Party Message"); -- Add localization
PartyCheckBox.tooltip = "Send party message" -- Add localization
PartyCheckBox:SetScript("OnClick", function(self)
    if config.PartyAlertEnable == false then 
        config.PartyAlertEnable = true
        self:SetChecked(config.PartyAlertEnable)
    else
        config.PartyAlertEnable = false
        self:SetChecked(config.PartyAlertEnable)
    end
end)

-- Info
local PartyEditBoxInfo = PartyFrame:CreateFontString("SettingsPartyEditBoxInfo", "OVERLAY", "GameFontWhite")
PartyEditBoxInfo:SetPoint("TOPLEFT", PartyFrame, 280, -65)
PartyEditBoxInfo:SetTextColor(getConfigColors("White"))
PartyEditBoxInfo:SetText("Sleep for x seconds") -- Add localization

-- Ignore time
local PartyEditBox = CreateFrame("EditBox", "SettingsPartyEditBox", PartyFrame)
PartyEditBox:SetPoint("TOPLEFT", 280, -90)
PartyEditBox:SetSize(80, 30)
PartyEditBox:SetTextInsets(10, 0, 0, 0) 
PartyEditBox:SetBackdrop(config.Backdrop)
PartyEditBox:SetBackdropBorderColor(getConfigColors("White"))
PartyEditBox:SetMultiLine(false)
PartyEditBox:SetMaxLetters(5)
PartyEditBox:SetAutoFocus(false)
PartyEditBox:SetFontObject(GameFontWhite)
PartyEditBox:SetScript("OnEscapePressed", function(self)
    config.PartyIgnoreTime = self:GetText()
    self:ClearFocus()
end)
PartyEditBox:SetScript("OnEnterPressed", function(self) 
    config.PartyIgnoreTime = self:GetText()
    self:ClearFocus()
end)
PartyEditBox:SetScript("OnMouseDown", function(self) 
    self:SetText(config.PartyIgnoreTime)
end)

-----

local PopupMenusFrame = CreateFrame("Frame", "SettingsPopupMenusFrame", ShitlistSettings.panel)
PopupMenusFrame:SetPoint("TOPLEFT", ShitlistSettings.panel, 10, -AudioFrame:GetHeight()+-TooltipFrame:GetHeight()+-PartyFrame:GetHeight())
PopupMenusFrame:SetSize(450, 100)

-- Title
local PopupMenusTitle = PopupMenusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
PopupMenusTitle:SetPoint("TOPLEFT", PopupMenusFrame, 10, -10)
PopupMenusTitle:SetFont(config.Font, 14)
PopupMenusTitle:SetText("Menus") -- Add localization

-- Info
local PopupMenusInfo = PopupMenusFrame:CreateFontString("SettingsPopupMenusInfo", "OVERLAY", "GameFontWhite")
PopupMenusInfo:SetPoint("TOPLEFT", PopupMenusFrame, 15, -30)
PopupMenusInfo:SetTextColor(getConfigColors("White"))
PopupMenusInfo:SetText("Add to popup menus") -- Add localization

local TargetCheckBox = CreateFrame("CheckButton", "SettingsTargetCheckBox", PopupMenusFrame, "ChatConfigCheckButtonTemplate")
TargetCheckBox:SetPoint("TOPLEFT", 30, -45)
getglobal(TargetCheckBox:GetName().."Text"):SetText("Target"); -- Add localization
TargetCheckBox.tooltip = "Add to player Target frame" -- Add localization
TargetCheckBox:SetScript("OnClick", function(self)
    if config.PopupMenus.target == false then 
        config.PopupMenus.target = true
        self:SetChecked(config.PopupMenus.target)
    else
        config.PopupMenus.target = false
        self:SetChecked(config.PopupMenus.target)
    end
end)

local ChatCheckBox = CreateFrame("CheckButton", "SettingsChatCheckBox", PopupMenusFrame, "ChatConfigCheckButtonTemplate")
ChatCheckBox:SetPoint("TOPLEFT", 30, -60)
getglobal(ChatCheckBox:GetName().."Text"):SetText("Chat"); -- Add localization
ChatCheckBox.tooltip = "Add to player Chat frame" -- Add localization
ChatCheckBox:SetScript("OnClick", function(self)
    if config.PopupMenus.chat == false then 
        config.PopupMenus.chat = true
        self:SetChecked(config.PopupMenus.chat)
    else
        config.PopupMenus.chat = false
        self:SetChecked(config.PopupMenus.chat)
    end
end)