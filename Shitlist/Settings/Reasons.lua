local _, config = ...;

-- Shitlist Settings - Reasons

-- Make a child panel
ShitlistSettings.reasonPanel = CreateFrame( "Frame", "ShitlistSettingsReasons", ShitlistSettings.panel)
ShitlistSettings.reasonPanel.name = "Reasons" -- Add localization

-- Specify childness of this panel (this puts it under the little red [+], instead of giving it a normal AddOn category)
ShitlistSettings.reasonPanel.parent = ShitlistSettings.panel.name

-- Add the child to the Interface Options
InterfaceOptions_AddCategory(ShitlistSettings.reasonPanel)

-- Tabb Title
local TabbReasonTitle = ShitlistSettings.reasonPanel:CreateFontString("SettingsTabbReasonTitle", "OVERLAY", "GameFontNormal");
TabbReasonTitle:SetPoint("TOPLEFT", ShitlistSettings.reasonPanel, 10, -10);
TabbReasonTitle:SetFont(config.Font, 18);
TabbReasonTitle:SetTextColor(getConfigColors("Gold"))
TabbReasonTitle:SetText("Shitlist - Reasons"); -- Add localization

-- Reason settings
local ReasonFrame = CreateFrame("Frame", "SettingsReasonFrame", ShitlistSettings.reasonPanel)
ReasonFrame:SetPoint("TOPLEFT", ShitlistSettings.reasonPanel, 10, -35);
ReasonFrame:SetSize(500, 200)

-- Title
local ReasonTitle = ReasonFrame:CreateFontString("SettingsReasonTitle", "OVERLAY", "GameFontNormal");
ReasonTitle:SetPoint("TOPLEFT", ReasonFrame, 10, -10);
ReasonTitle:SetFont(config.Font, 14);
ReasonTitle:SetText("Reasons"); -- Add localization

-- Info
local ReasonInfo = ReasonFrame:CreateFontString("SettingsReasonInfo", "OVERLAY", "GameFontWhite");
ReasonInfo:SetPoint("TOPLEFT", ReasonFrame, 30, -30);
ReasonInfo:SetTextColor(getConfigColors("White"))
ReasonInfo:SetText("Edit reasons"); -- Add localization

-- Reasons
local ReasonDropDown = CreateFrame("Button", "SettingsReasonDropDown", ReasonFrame, "UIDropDownMenuTemplate")
ReasonDropDown:SetPoint("TOPLEFT", ReasonFrame, 15, -50)

local function OnClick(self)
    UIDropDownMenu_SetSelectedID(ReasonDropDown, self:GetID())
    SettingsReasonEditBox:SetText(self:GetText())
end

function initializeReasons(self)
    local info = UIDropDownMenu_CreateInfo()
    for k,v in pairs(config.Reasons) do
        info = UIDropDownMenu_CreateInfo()
        info.text = v
        info.value = v
        info.func = OnClick
        UIDropDownMenu_AddButton(info)
    end
end

UIDropDownMenu_Initialize(ReasonDropDown, initializeReasons)
UIDropDownMenu_SetWidth(ReasonDropDown, 170);
UIDropDownMenu_SetButtonWidth(ReasonDropDown, 195)
UIDropDownMenu_SetSelectedID(ReasonDropDown, 1)
UIDropDownMenu_JustifyText(ReasonDropDown, "LEFT")

-- Info
local ReasonColorInfo = ReasonFrame:CreateFontString("SettingsReasonColorInfo", "OVERLAY", "GameFontWhite")
ReasonColorInfo:SetPoint("TOPLEFT", ReasonFrame, ReasonDropDown:GetWidth()+65, -30)
ReasonColorInfo:SetTextColor(getConfigColors("White"))
ReasonColorInfo:SetText("Reason text color") -- Add localization

-- Reason Color
local ReasonColorDropDown = CreateFrame("Button", "SettingsReasonColorDropDown", ReasonFrame, "UIDropDownMenuTemplate")
ReasonColorDropDown:SetPoint("TOPLEFT", ReasonFrame, ReasonDropDown:GetWidth()+50, -50)

local function OnClick(self)
    UIDropDownMenu_SetSelectedID(ReasonColorDropDown, self:GetID())
    config.ReasonColor = self:GetText()
    config.ReasonColorID = self:GetID()
end

function initializeReasonColor(self)
    local info = UIDropDownMenu_CreateInfo()
    for k,v in pairs(config.Colors) do
        info = UIDropDownMenu_CreateInfo()
        info.text = k
        info.value = getConfigColors(v)
        info.func = OnClick
        UIDropDownMenu_AddButton(info)
    end
end

UIDropDownMenu_Initialize(ReasonColorDropDown, initializeReasonColor)
UIDropDownMenu_SetWidth(ReasonColorDropDown, 100)
UIDropDownMenu_SetButtonWidth(ReasonColorDropDown, 115)
UIDropDownMenu_SetSelectedID(ReasonColorDropDown, 1)
UIDropDownMenu_JustifyText(ReasonColorDropDown, "LEFT")

-- Reason Text EditBox
local ReasonEditBox = CreateFrame("EditBox", "SettingsReasonEditBox", ReasonFrame, BackdropTemplateMixin and "BackdropTemplate")
ReasonEditBox:SetPoint("TOPLEFT", ReasonFrame, 25, -85)
ReasonEditBox:SetSize(200, 30)
ReasonEditBox:SetTextInsets(10, 0, 0, 0) 
ReasonEditBox:SetBackdrop(config.Backdrop)
ReasonEditBox:SetBackdropBorderColor(getConfigColors("White"))
ReasonEditBox:SetMultiLine(false)
ReasonEditBox:SetMaxLetters(255)
ReasonEditBox:SetAutoFocus(false) -- dont automatically focus
ReasonEditBox:SetFontObject(GameFontWhite)
ReasonEditBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
end)
ReasonEditBox:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
end)

-- Button save new reason
local ReasonAddBtn = CreateFrame("Button", "SettingsReasonAddBtn", ReasonFrame, "OptionsButtonTemplate");
ReasonAddBtn:SetPoint("TOPLEFT", ReasonFrame, 40, -120)
ReasonAddBtn:SetSize(80, 30);
ReasonAddBtn:SetText("Add"); -- Add localization
ReasonAddBtn:SetNormalFontObject(GameFontNormal);
ReasonAddBtn:SetHighlightFontObject(GameFontHighlight);
ReasonAddBtn:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        table.insert(config.Reasons, ReasonEditBox:GetText())
        ReasonEditBox:SetText("")
        UIDropDownMenu_Initialize(ReasonDropDown, initializeReasons)
        UIDropDownMenu_SetSelectedID(ReasonDropDown, 1)
    end
end)

-- Button remove reason
local ReasonRemoveBtn = CreateFrame("Button", "SettingsReasonRemoveBtn", ReasonFrame, "OptionsButtonTemplate");
ReasonRemoveBtn:SetPoint("TOPLEFT", ReasonFrame, 130, -120)
ReasonRemoveBtn:SetSize(80, 30);
ReasonRemoveBtn:SetText("Remove"); -- Add localization
ReasonRemoveBtn:SetNormalFontObject(GameFontNormal);
ReasonRemoveBtn:SetHighlightFontObject(GameFontHighlight);
ReasonRemoveBtn:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        for k,v in ipairs(config.Reasons) do
            if ReasonEditBox:GetText() == v then
                print("Removed Reason: " .. v)
                table.remove(config.Reasons, k)
                ReasonEditBox:SetText("")
                UIDropDownMenu_Initialize(ReasonDropDown, initializeReasons)
                UIDropDownMenu_SetSelectedID(ReasonDropDown, 1)
            end
        end
    end
end)
