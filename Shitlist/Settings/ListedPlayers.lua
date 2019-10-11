local _, config = ...

-- Shitlist Settings Listed Players

-- Make a child panel
ShitlistSettings.listedPlayersPanel = CreateFrame( "Frame", "ShitlistSettingsListedPlayers", ShitlistSettings.panel)
ShitlistSettings.listedPlayersPanel.name = "Listed Players" -- Add localization

-- Specify childness of this panel (this puts it under the little red [+], instead of giving it a normal AddOn category)
ShitlistSettings.listedPlayersPanel.parent = ShitlistSettings.panel.name
-- Add the child to the Interface Options
InterfaceOptions_AddCategory(ShitlistSettings.listedPlayersPanel)

-- Listed Players tabb
local TabbListedPlayersTitle = ShitlistSettings.listedPlayersPanel:CreateFontString("SettingsTabbListedPlayersTitle", "OVERLAY", "GameFontNormal")
TabbListedPlayersTitle:SetPoint("TOPLEFT", ShitlistSettings.listedPlayersPanel, 10, -10)
TabbListedPlayersTitle:SetFont(config.Font, 18)
TabbListedPlayersTitle:SetTextColor(getConfigColors("Gold"))
TabbListedPlayersTitle:SetText("Shitlist - Listed Players") -- Add localization

-- Listed Players settings
local ListedPlayersFrame = CreateFrame("Frame", "SettingsListedPlayersFrame", ShitlistSettings.listedPlayersPanel)
ListedPlayersFrame:SetPoint("TOPLEFT", ShitlistSettings.listedPlayersPanel, 10, -35)
ListedPlayersFrame:SetSize(250, 295)
--ListedPlayersFrame:SetBackdrop(config.Backdrop)
--ListedPlayersFrame:SetBackdropBorderColor(getConfigColors("Black"))

-- Title
local ListedPlayerTitle = ListedPlayersFrame:CreateFontString("SettingsListedPlayerTitle", "OVERLAY", "GameFontNormal")
ListedPlayerTitle:SetPoint("TOPLEFT", ListedPlayersFrame, 10, -10)
ListedPlayerTitle:SetFont(config.Font, 14)
ListedPlayerTitle:SetText("Listed Players") -- Add localization

-- Info
local ListedPlayerInfo = ListedPlayersFrame:CreateFontString("SettingsListedPlayerInfo", "OVERLAY", "GameFontWhite")
ListedPlayerInfo:SetPoint("TOPLEFT", ListedPlayersFrame, 30, -30)
ListedPlayerInfo:SetTextColor(getConfigColors("White"))
ListedPlayerInfo:SetText("Edit or Remove a player") -- Add localization

-- Listed player
local ListedPlayerDropDown = CreateFrame("Button", "SettingsListedPlayerDropDown", ListedPlayersFrame, "UIDropDownMenuTemplate")
ListedPlayerDropDown:SetPoint("TOPLEFT", ListedPlayersFrame, 15, -50)

local function OnClick(self)
    UIDropDownMenu_SetSelectedID(ListedPlayerDropDown, self:GetID())
    SettingsListedPlayerEditBox:SetText(self:GetText())
    SettingsListedPlayerDescriptionEditBox:SetText(config.ListedPlayers[self:GetText()][2])   
    local index={}
    for k,v in pairs(config.Reasons) do
        index[v]=k
    end
    local a = config.ListedPlayers[self:GetText()][1]
    
    UIDropDownMenu_Initialize(SettingsListedPlayerReasonDropDown, initializeReason)
    UIDropDownMenu_SetSelectedID(SettingsListedPlayerReasonDropDown, index[a])        
end

function initializePlayer(self)
    local info = UIDropDownMenu_CreateInfo()
    for k,v in pairs(config.ListedPlayers) do
        info = UIDropDownMenu_CreateInfo()
        info.text = k
        info.value = v
        info.func = OnClick
        UIDropDownMenu_AddButton(info)
    end
end

UIDropDownMenu_Initialize(ListedPlayerDropDown, initializePlayer)
UIDropDownMenu_SetWidth(ListedPlayerDropDown, 170)
UIDropDownMenu_SetButtonWidth(ListedPlayerDropDown, 195)
UIDropDownMenu_SetSelectedID(ListedPlayerDropDown, 1)
UIDropDownMenu_JustifyText(ListedPlayerDropDown, "LEFT")


-- Player
local ListedPlayerEditBox = CreateFrame("EditBox", "SettingsListedPlayerEditBox", ListedPlayersFrame)
ListedPlayerEditBox:SetPoint("TOPLEFT", ListedPlayersFrame, 25, -85)
ListedPlayerEditBox:SetSize(200, 30)
ListedPlayerEditBox:SetTextInsets(10, 0, 0, 0) 
ListedPlayerEditBox:SetBackdrop(config.Backdrop)
ListedPlayerEditBox:SetBackdropBorderColor(getConfigColors("White"))
ListedPlayerEditBox:SetMultiLine(false)
ListedPlayerEditBox:SetMaxLetters(255)
ListedPlayerEditBox:SetAutoFocus(false) -- dont automatically focus
ListedPlayerEditBox:SetFontObject(GameFontWhite)
ListedPlayerEditBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
end)
ListedPlayerEditBox:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
end)

-- Title Reason
local ListedPlayerReasonDropDownTitle = ListedPlayersFrame:CreateFontString("SettingsListedPlayerReasonDropDownTitle", "OVERLAY", "GameFontNormal")
ListedPlayerReasonDropDownTitle:SetPoint("TOPLEFT", ListedPlayersFrame, 35, -125)
ListedPlayerReasonDropDownTitle:SetFont(config.Font, 14)
ListedPlayerReasonDropDownTitle:SetText("Reason") -- Add localization

-- Reason
local ListedPlayerReasonDropDown = CreateFrame("Button", "SettingsListedPlayerReasonDropDown", ListedPlayersFrame, "UIDropDownMenuTemplate")
ListedPlayerReasonDropDown:SetPoint("TOPLEFT", ListedPlayersFrame, 15, -140)

local function OnClick(self)
    UIDropDownMenu_SetSelectedID(ListedPlayerReasonDropDown, self:GetID())
end

function initializeReason(self)
    local info = UIDropDownMenu_CreateInfo()
    for k,v in pairs(config.Reasons) do
        info = UIDropDownMenu_CreateInfo()
        info.text = v
        info.value = v
        info.func = OnClick
        UIDropDownMenu_AddButton(info)
    end
end

UIDropDownMenu_Initialize(ListedPlayerReasonDropDown, initializeReason)
UIDropDownMenu_SetWidth(ListedPlayerReasonDropDown, 170)
UIDropDownMenu_SetButtonWidth(ListedPlayerReasonDropDown, 195)
UIDropDownMenu_SetSelectedID(ListedPlayerReasonDropDown, 1)
UIDropDownMenu_JustifyText(ListedPlayerReasonDropDown, "LEFT")

-- Title
local ListedPlayerEditBoxTitle = ListedPlayersFrame:CreateFontString("SettingsListedPlayerEditBoxTitle", "OVERLAY", "GameFontNormal")
ListedPlayerEditBoxTitle:SetPoint("TOPLEFT", ListedPlayersFrame, 35, -180)
ListedPlayerEditBoxTitle:SetFont(config.Font, 14)
ListedPlayerEditBoxTitle:SetText("Description") -- Add localization

-- Info
local ListedPlayerEditBoxInfo = ListedPlayersFrame:CreateFontString("SettingsListedPlayerEditBoxInfo", "OVERLAY", "GameFontWhite")
ListedPlayerEditBoxInfo:SetPoint("TOPLEFT", ListedPlayersFrame, 170, -180)
ListedPlayerEditBoxInfo:SetFont(config.Font, 11)
ListedPlayerEditBoxInfo:SetText("Optional") -- Add localization

-- Player Description EditBox
local ListedPlayerDescriptionEditBox = CreateFrame("EditBox", "SettingsListedPlayerDescriptionEditBox", ListedPlayersFrame)
ListedPlayerDescriptionEditBox:SetPoint("TOPLEFT", ListedPlayersFrame, 25, -195)
ListedPlayerDescriptionEditBox:SetSize(200, 30)
ListedPlayerDescriptionEditBox:SetTextInsets(10, 0, 0, 0) 
ListedPlayerDescriptionEditBox:SetBackdrop(config.Backdrop)
ListedPlayerDescriptionEditBox:SetBackdropBorderColor(getConfigColors("White"))
ListedPlayerDescriptionEditBox:SetMultiLine(false)
ListedPlayerDescriptionEditBox:SetMaxLetters(255)
ListedPlayerDescriptionEditBox:SetAutoFocus(false) -- dont automatically focus
ListedPlayerDescriptionEditBox:SetFontObject(GameFontWhite)
ListedPlayerDescriptionEditBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
end)
ListedPlayerDescriptionEditBox:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
end)

-- Button save player data
local ListedPlayerSaveBtn = CreateFrame("Button", "SettingsListedPlayerSaveBtn", ListedPlayersFrame, "OptionsButtonTemplate")
ListedPlayerSaveBtn:SetPoint("TOPLEFT", ListedPlayersFrame, 40, -230)
ListedPlayerSaveBtn:SetSize(80, 30)
ListedPlayerSaveBtn:SetText("Save") -- Add localization
ListedPlayerSaveBtn:SetNormalFontObject(GameFontNormal)
ListedPlayerSaveBtn:SetHighlightFontObject(GameFontHighlight)
ListedPlayerSaveBtn:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and SettingsListedPlayerEditBox:GetText() ~= "" then
        if config.ListedPlayers[SettingsListedPlayerEditBox:GetText()] then
            config.ListedPlayers[SettingsListedPlayerEditBox:GetText()] = {SettingsListedPlayerReasonDropDown.Text:GetText(), SettingsListedPlayerDescriptionEditBox:GetText()}
            print("Added player: " .. SettingsListedPlayerEditBox:GetText()) -- Add localization
        else
            config.ListedPlayers[SettingsListedPlayerDropDown.Text:GetText()] = {SettingsListedPlayerReasonDropDown.Text:GetText() or "", SettingsListedPlayerDescriptionEditBox:GetText() or ""}
        end
        
        SettingsListedPlayerEditBox:SetText("")
        SettingsListedPlayerDescriptionEditBox:SetText("")
        UIDropDownMenu_Initialize(SettingsListedPlayerDropDown, initializePlayer)
        UIDropDownMenu_SetSelectedID(SettingsListedPlayerDropDown, 1) 
        UIDropDownMenu_Initialize(SettingsListedPlayerReasonDropDown, initializeReason)
        UIDropDownMenu_SetSelectedID(SettingsListedPlayerReasonDropDown, 1) 
    end
end)

-- Button remove player
local ListedPlayerRemoveBtn = CreateFrame("Button", "SettingsListedPlayerRemoveBtn", ListedPlayersFrame, "OptionsButtonTemplate")
ListedPlayerRemoveBtn:SetPoint("TOPLEFT", ListedPlayersFrame, 130, -230)
ListedPlayerRemoveBtn:SetSize(80, 30)
ListedPlayerRemoveBtn:SetText("Remove") -- Add localization
ListedPlayerRemoveBtn:SetNormalFontObject(GameFontNormal)
ListedPlayerRemoveBtn:SetHighlightFontObject(GameFontHighlight)
ListedPlayerRemoveBtn:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        for k,v in pairs(config.ListedPlayers) do
            if SettingsListedPlayerDropDown.Text:GetText() == k then
                config.ListedPlayers[k] = nil
                print("Removed player: " .. k) -- Add localization
                UIDropDownMenu_Initialize(SettingsListedPlayerDropDown, initializePlayer)
                UIDropDownMenu_SetSelectedID(SettingsListedPlayerDropDown, 1)
                UIDropDownMenu_Initialize(SettingsListedPlayerReasonDropDown, initializeReason)
                UIDropDownMenu_SetSelectedID(SettingsListedPlayerReasonDropDown, 1) 
                SettingsListedPlayerEditBox:SetText("")
                SettingsListedPlayerDescriptionEditBox:SetText("")
                break
            end
        end
    end
end)
