local _, config = ...;

Shitlist = CreateFrame('GameTooltip', 'Shitlist', UIParent, 'GameTooltipTemplate')

Shitlist:RegisterEvent("ADDON_LOADED"); -- Fired when saved variables are loaded
Shitlist:RegisterEvent("PLAYER_LOGOUT"); -- Fired when about to log out

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
    elseif event == "PLAYER_LOGOUT" then
        --_G.ShitlistDB = config -- Save whole config to SavedVariables
        _G.ShitlistDB["TooltipTitle"] = config.TooltipTitle
        _G.ShitlistDB["Reasons"] = config.Reasons
        _G.ShitlistDB["ListedPlayers"] = config.ListedPlayers
    end
end)

-- Add info to tooltip
function ShowPlayerTooltip(self)
	local name, unit = self:GetUnit()
	if UnitIsPlayer(unit) and not UnitIsUnit(unit, "player") then
		local name, realm = UnitName(unit)
		name = name .. "-" .. (realm or GetRealmName())
		if config.ListedPlayers[name] and type(next(config.ListedPlayers)) ~= "nil" then
            self:AddLine(config.TooltipTitle, 1, 0, 0, true)
            for i,value in ipairs(config.ListedPlayers[name]) do
                self:AddLine(value, 1, 1, 1, true)
            end
        end
	end
end

GameTooltip:HookScript("OnTooltipSetUnit", ShowPlayerTooltip)

-- Add to player context menu
function ShitlistDropdownMenuButton(self)
    name = self.value
    if not config.ListedPlayers[name] then
        Shitlist:Toggle()
    else
        print("Removed " .. name)
        config.ListedPlayers[name] = nil
    end
end

hooksecurefunc("UnitPopup_ShowMenu", function(self)
    if (UIDROPDOWNMENU_MENU_LEVEL > 1) then
        return
    end
    if UnitIsPlayer("target") and not UnitIsUnit("target", "player") then
        local name, realm = UnitName("target")
        name = name .. "-" .. (realm or GetRealmName())
        local info = UIDropDownMenu_CreateInfo()
        info.owner = which
        info.notCheckable = 1
        info.func = ShitlistDropdownMenuButton 
        if config.ListedPlayers[name] then
            info.text = "Remove from Shitlist"
            info.colorCode = "|cff00ff00"
            info.value = name
        else
            info.text = "Add to Shitlist"
            info.colorCode = "|cffff0000"
            info.value = name
            info.icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8.png"
        end   
        UIDropDownMenu_AddButton(info)
    end
end)

-- Shitlist UI
function Shitlist:CreateUI()
    shitlistUI = CreateFrame("Frame", "ShitlistUI", UIParent)
    shitlistUI:ClearAllPoints()
    shitlistUI:SetHeight(180)
    shitlistUI:SetWidth(320)
    shitlistUI:SetPoint("CENTER");
    shitlistUI:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight", -- this one is neat
        edgeSize = 16,
        insets = { left = 8, right = 6, top = 8, bottom = 8 },
    })
    shitlistUI:SetBackdropBorderColor(getConfigColors("Dark_Blue")) -- darkblue
    shitlistUI:SetMovable(true);
    shitlistUI:EnableMouse(true);
    shitlistUI:RegisterForDrag("LeftButton");
    shitlistUI:SetScript("OnDragStart", shitlistUI.StartMoving);
    shitlistUI:SetScript("OnDragStop", shitlistUI.StopMovingOrSizing);

    local title = shitlistUI:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    --title:SetFontObject("GameFontHighlight");
    title:SetPoint("CENTER", shitlistUI, "TOP", 0, -20);
    title:SetFont("Interface\\AddOns\\Shitlist\\Fonts\\Inconsolata-Bold.ttf", 12)
    title:SetTextColor(getConfigColors("White"))
    title:SetText("Add new player notice");

    -- Title
    playerText = shitlistUI:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
    playerText:SetPoint("TOP", shitlistUI, 0, -35)
    playerText:SetFont("Interface\\AddOns\\Shitlist\\Fonts\\Inconsolata-Bold.ttf", 16)
    playerText:SetTextColor(getConfigColors("Yellow"))
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
    UIDropDownMenu_SetWidth(reasons, 160);
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
    noticeEditBox:SetBackdropBorderColor(getConfigColors("Dark_Blue"))
    noticeEditBox:SetMultiLine(false)
    noticeEditBox:SetMaxLetters(255)
    noticeEditBox:SetAutoFocus(false) -- dont automatically focus
    noticeEditBox:SetFontObject(GameFontWhite)
    noticeEditBox:SetScript("OnEscapePressed", function(self) Shitlist:Toggle() end)
	noticeEditBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

    local saveBtn = CreateFrame("Button", nil, shitlistUI, "OptionsButtonTemplate");
    saveBtn:SetPoint("CENTER", shitlistUI, "BOTTOM", -55, 35);
    saveBtn:SetSize(100, 30);
    saveBtn:SetText("Save");
    saveBtn:SetNormalFontObject("GameFontNormal");
    saveBtn:SetHighlightFontObject("GameFontHighlight");
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

    local cancelBtn = CreateFrame("Button", nil, shitlistUI, "OptionsButtonTemplate");
    cancelBtn:SetPoint("CENTER", shitlistUI, "BOTTOM", 55, 35);
    cancelBtn:SetSize(100, 30);
    cancelBtn:SetText("Cancel");
    cancelBtn:SetNormalFontObject(GameFontNormal);
    cancelBtn:SetHighlightFontObject(GameFontHighlight);
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
    local shitlist = shitlistUI or Shitlist:CreateUI();
    shitlist:SetShown(not shitlist:IsShown());
    playerText:SetText(name)
end

-- Settings --
function Shitlist:Settings()
    MyAddon = {};
    MyAddon.panel = CreateFrame( "Frame", "MyAddonPanel", UIParent );
    -- Register in the Interface Addon Options GUI
    -- Set the name for the Category for the Options Panel
    MyAddon.panel.name = "Shitlist";
    -- Add the panel to the Interface Options
    InterfaceOptions_AddCategory(MyAddon.panel);
    
    -- Shitlist panel
    -- Shitlist - General
    -- Title
    local title = MyAddon.panel:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    title:SetPoint("TOPLEFT", MyAddon.panel, 10, -10);
    title:SetFont("Interface\\AddOns\\Shitlist\\Fonts\\Inconsolata-Bold.ttf", 18);
    title:SetTextColor(getConfigColors("Yellow"))
    title:SetText("Shitlist - General");

    -- Version
    local version = MyAddon.panel:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    version:SetPoint("BOTTOMRIGHT", MyAddon.panel, -5, 5);
    version:SetFont("Interface\\AddOns\\Shitlist\\Fonts\\Inconsolata-Bold.ttf", 11);
    version:SetTextColor(getConfigColors("White"))
    version:SetText("Version: " .. GetAddOnMetadata("Shitlist", "Version"));

    -- Tooltip settings
    tooltipFrame = CreateFrame("Frame", "TooltipFrame", MyAddon.panel)
    tooltipFrame:SetPoint("TOPLEFT", MyAddon.panel, 10, -35);
    tooltipFrame:SetSize(250, 125)
    tooltipFrame:SetBackdrop({
		bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile="Interface\\PVPFrame\\UI-Character-PVP-Highlight", 
		tile = false, tileSize = 0, edgeSize = 8,
		insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    tooltipFrame:SetBackdropBorderColor(getConfigColors("Black"))
    
    -- Title
    local tptTitle = tooltipFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    tptTitle:SetPoint("TOPLEFT", tooltipFrame, 10, -10);
    tptTitle:SetFont("Interface\\AddOns\\Shitlist\\Fonts\\Inconsolata-Bold.ttf", 14);
    tptTitle:SetText("Tooltip Title");
    
    -- Info
    local tptInfo = tooltipFrame:CreateFontString(nil, "OVERLAY", "GameFontWhite");
    tptInfo:SetPoint("TOPLEFT", tooltipFrame, 15, -30);
    tptInfo:SetTextColor(getConfigColors("White"))
    tptInfo:SetText("Set title in the Tooltip message. #Shitlist");

    -- EditBox
    tptEditBox = CreateFrame("EditBox", "TooltipTitleEditBox", tooltipFrame)
    tptEditBox:SetPoint("TOPLEFT", 15, -50)
    tptEditBox:SetSize(220, 30)
    tptEditBox:SetTextInsets(10, 0, 0, 0) 
    tptEditBox:SetBackdrop({
		bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile="Interface\\PVPFrame\\UI-Character-PVP-Highlight", 
		tile = false, tileSize = 0, edgeSize = 8,
		insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    tptEditBox:SetBackdropBorderColor(getConfigColors("Dark_Blue"))
    tptEditBox:SetMultiLine(false)
    tptEditBox:SetMaxLetters(50)
    tptEditBox:SetAutoFocus(false)
    tptEditBox:SetFontObject(GameFontWhite)
    tptEditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	tptEditBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    tptEditBox:SetScript("OnMouseDown", function(self) self:SetText(config.TooltipTitle) end)
    
    -- Button save new reason
    local tptSaveBtn = CreateFrame("Button", nil, tooltipFrame, "OptionsButtonTemplate");
    tptSaveBtn:SetPoint("TOPLEFT", tooltipFrame, 85, -85)
    tptSaveBtn:SetSize(80, 30);
    tptSaveBtn:SetText("Save");
    tptSaveBtn:SetNormalFontObject(GameFontNormal);
    tptSaveBtn:SetHighlightFontObject(GameFontHighlight);
    tptSaveBtn:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            config.TooltipTitle = tptEditBox:GetText();
        end
    end)
    
    
    -- Shitlist Settings Reasons Frame
    -- Make a child panel
    MyAddon.reasonPanel = CreateFrame( "Frame", "ShitlistSettingsReasons", MyAddon.panel);
    MyAddon.reasonPanel.name = "Reasons";
    -- Specify childness of this panel (this puts it under the little red [+], instead of giving it a normal AddOn category)
    MyAddon.reasonPanel.parent = MyAddon.panel.name;
    -- Add the child to the Interface Options
    InterfaceOptions_AddCategory(MyAddon.reasonPanel);
    
    -- Reasons tabb
    local title = MyAddon.reasonPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    title:SetPoint("TOPLEFT", MyAddon.reasonPanel, 10, -10);
    title:SetFont("Interface\\AddOns\\Shitlist\\Fonts\\Inconsolata-Bold.ttf", 18);
    title:SetTextColor(getConfigColors("Yellow"))
    title:SetText("Shitlist - Reasons");

    reasonFrame = CreateFrame("Frame", "ReasonsFrame", MyAddon.reasonPanel)
    reasonFrame:SetPoint("TOPLEFT", MyAddon.reasonPanel, 10, -35);
    reasonFrame:SetSize(250, 160)
    reasonFrame:SetBackdrop({
		bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile="Interface\\PVPFrame\\UI-Character-PVP-Highlight", 
		tile = false, tileSize = 0, edgeSize = 8,
		insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    reasonFrame:SetBackdropBorderColor(getConfigColors("Black"))
    
    -- Title
    local reasonTitle = reasonFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    reasonTitle:SetPoint("TOPLEFT", reasonFrame, 10, -10);
    reasonTitle:SetFont("Interface\\AddOns\\Shitlist\\Fonts\\Inconsolata-Bold.ttf", 14);
    reasonTitle:SetText("Reasons");

    -- Info
    local tptInfo = reasonFrame:CreateFontString(nil, "OVERLAY", "GameFontWhite");
    tptInfo:SetPoint("TOPLEFT", reasonFrame, 15, -30);
    tptInfo:SetTextColor(getConfigColors("White"))
    tptInfo:SetText("Edit reasons");

    local reasonDropDown = CreateFrame("Button", nil, reasonFrame, "UIDropDownMenuTemplate")
    reasonDropDown:SetPoint("TOPLEFT", reasonFrame, 15, -50)

    local function OnClick(self)
        UIDropDownMenu_SetSelectedID(reasonDropDown, self:GetID())
        reasonEditBox:SetText(self:GetText())
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

    UIDropDownMenu_Initialize(reasonDropDown, initialize)
    UIDropDownMenu_SetWidth(reasonDropDown, 170);
    UIDropDownMenu_SetButtonWidth(reasonDropDown, 195)
    UIDropDownMenu_SetSelectedID(reasonDropDown, 1)
    UIDropDownMenu_JustifyText(reasonDropDown, "LEFT")

    -- Reason Text EditBox
    reasonEditBox = CreateFrame("EditBox", "DescriptionEditBox", reasonFrame)
    reasonEditBox:SetPoint("TOPLEFT", reasonFrame, 25, -85)
    reasonEditBox:SetSize(200, 30)
    reasonEditBox:SetTextInsets(10, 0, 0, 0) 
    reasonEditBox:SetBackdrop({
		bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile="Interface\\PVPFrame\\UI-Character-PVP-Highlight", 
		tile = false, tileSize = 0, edgeSize = 8,
		insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    reasonEditBox:SetBackdropBorderColor(getConfigColors("Dark_Blue"))
    reasonEditBox:SetMultiLine(false)
    reasonEditBox:SetMaxLetters(255)
    reasonEditBox:SetAutoFocus(false) -- dont automatically focus
    reasonEditBox:SetFontObject(GameFontNormal)
    reasonEditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	reasonEditBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

    -- Button save new reason
    local reasonAddBtn = CreateFrame("Button", nil, reasonFrame, "OptionsButtonTemplate");
    reasonAddBtn:SetPoint("TOPLEFT", reasonFrame, 40, -120)
    reasonAddBtn:SetSize(80, 30);
    reasonAddBtn:SetText("Add");
    reasonAddBtn:SetNormalFontObject(GameFontNormal);
    reasonAddBtn:SetHighlightFontObject(GameFontHighlight);
    reasonAddBtn:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            table.insert(config.Reasons, reasonEditBox:GetText())
            reasonEditBox:SetText("")
            UIDropDownMenu_Initialize(reasonDropDown, initialize)
            UIDropDownMenu_SetSelectedID(reasonDropDown, 1)
        end
    end)
    
    -- Button remove reason
    local reasonRemoveBtn = CreateFrame("Button", nil, reasonFrame, "OptionsButtonTemplate");
    reasonRemoveBtn:SetPoint("TOPLEFT", reasonFrame, 130, -120)
    reasonRemoveBtn:SetSize(80, 30);
    reasonRemoveBtn:SetText("Remove");
    reasonRemoveBtn:SetNormalFontObject(GameFontNormal);
    reasonRemoveBtn:SetHighlightFontObject(GameFontHighlight);
    reasonRemoveBtn:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            --config.Reasons[reasonEditBox:GetText()] = nil
            for k,v in ipairs(config.Reasons) do
                if reasonEditBox:GetText() == v then
                    print("Removed Reason: " .. v)
                    table.remove(config.Reasons, k)
                    reasonEditBox:SetText("")
                    UIDropDownMenu_Initialize(reasonDropDown, initialize)
                    UIDropDownMenu_SetSelectedID(reasonDropDown, 1)
                end
            end
        end
    end)

    -- Shitlist Settings Listed Players
    -- Make a child panel
    MyAddon.listedPlayersPanel = CreateFrame( "Frame", "ShitlistSettingsListedPlayers", MyAddon.panel);
    MyAddon.listedPlayersPanel.name = "Listed Players";
    -- Specify childness of this panel (this puts it under the little red [+], instead of giving it a normal AddOn category)
    MyAddon.listedPlayersPanel.parent = MyAddon.panel.name;
    -- Add the child to the Interface Options
    InterfaceOptions_AddCategory(MyAddon.listedPlayersPanel);
    
    -- Listed Players tabb
    local title = MyAddon.listedPlayersPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    title:SetPoint("TOPLEFT", MyAddon.listedPlayersPanel, 10, -10);
    title:SetFont("Interface\\AddOns\\Shitlist\\Fonts\\Inconsolata-Bold.ttf", 18);
    title:SetTextColor(getConfigColors("Yellow"))
    title:SetText("Shitlist - Listed Players");

    listedPlayersFrame = CreateFrame("Frame", "ReasonsFrame", MyAddon.listedPlayersPanel)
    listedPlayersFrame:SetPoint("TOPLEFT", MyAddon.listedPlayersPanel, 10, -35);
    listedPlayersFrame:SetSize(250, 235)
    listedPlayersFrame:SetBackdrop({
		bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile="Interface\\PVPFrame\\UI-Character-PVP-Highlight", 
		tile = false, tileSize = 0, edgeSize = 8,
		insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    listedPlayersFrame:SetBackdropBorderColor(getConfigColors("Black"))
    
    -- Title
    local title = listedPlayersFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    title:SetPoint("TOPLEFT", listedPlayersFrame, 10, -10);
    title:SetFont("Interface\\AddOns\\Shitlist\\Fonts\\Inconsolata-Bold.ttf", 14);
    title:SetText("Listed Players");

    -- Info
    local tptInfo = listedPlayersFrame:CreateFontString(nil, "OVERLAY", "GameFontWhite");
    tptInfo:SetPoint("TOPLEFT", listedPlayersFrame, 15, -30);
    tptInfo:SetTextColor(getConfigColors("White"))
    tptInfo:SetText("Edit or Remove shitlisted players");

    player = CreateFrame("Button", nil, listedPlayersFrame, "UIDropDownMenuTemplate")
    player:SetPoint("TOPLEFT", listedPlayersFrame, 15, -50)

    local function OnClick(self)
        UIDropDownMenu_SetSelectedID(player, self:GetID())
        playerEditBox:SetText(config.ListedPlayers[self:GetText()][2])    
        local index={}
        for k,v in pairs(config.Reasons) do
            index[v]=k
        end
        local a = config.ListedPlayers[self:GetText()][1]
        
        UIDropDownMenu_Initialize(playerReason, initializeReason)
        UIDropDownMenu_SetSelectedID(playerReason, index[a])        
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

    UIDropDownMenu_Initialize(player, initializePlayer)
    UIDropDownMenu_SetWidth(player, 170);
    UIDropDownMenu_SetButtonWidth(player, 195)
    UIDropDownMenu_SetSelectedID(player, 1)
    UIDropDownMenu_JustifyText(player, "LEFT")

    local playerReasonTitle = listedPlayersFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    playerReasonTitle:SetPoint("TOPLEFT", listedPlayersFrame, 35, -90);
    playerReasonTitle:SetFont("Interface\\AddOns\\Shitlist\\Fonts\\Inconsolata-Bold.ttf", 13);
    playerReasonTitle:SetText("Reason");

    playerReason = CreateFrame("Button", nil, listedPlayersFrame, "UIDropDownMenuTemplate")
    playerReason:SetPoint("TOPLEFT", listedPlayersFrame, 15, -105)

    local function OnClick(self)
        UIDropDownMenu_SetSelectedID(playerReason, self:GetID())
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

    UIDropDownMenu_Initialize(playerReason, initializeReason)
    UIDropDownMenu_SetWidth(playerReason, 170);
    UIDropDownMenu_SetButtonWidth(playerReason, 195)
    UIDropDownMenu_SetSelectedID(playerReason, 1)
    UIDropDownMenu_JustifyText(playerReason, "LEFT")

    local playerEditBoxTitle = listedPlayersFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    playerEditBoxTitle:SetPoint("TOPLEFT", listedPlayersFrame, 30, -145);
    playerEditBoxTitle:SetFont("Interface\\AddOns\\Shitlist\\Fonts\\Inconsolata-Bold.ttf", 13);
    playerEditBoxTitle:SetText("Description");

    -- Info
    local playerEditBoxInfo = listedPlayersFrame:CreateFontString(nil, "OVERLAY", "GameFontWhite");
    playerEditBoxInfo:SetPoint("TOPRIGHT", listedPlayersFrame, -25, -145);
    playerEditBoxInfo:SetFont("Interface\\AddOns\\Shitlist\\Fonts\\Inconsolata-Bold.ttf", 10);
    playerEditBoxInfo:SetTextColor(getConfigColors("White"))
    playerEditBoxInfo:SetText("Optional");

    -- Player Description EditBox
    playerEditBox = CreateFrame("EditBox", "PlayerDescriptionEditBox", listedPlayersFrame)
    playerEditBox:SetPoint("TOPLEFT", listedPlayersFrame, 25, -160)
    playerEditBox:SetSize(200, 30)
    playerEditBox:SetTextInsets(10, 0, 0, 0) 
    playerEditBox:SetBackdrop({
        bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile="Interface\\PVPFrame\\UI-Character-PVP-Highlight", 
        tile = false, tileSize = 0, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    playerEditBox:SetBackdropBorderColor(getConfigColors("Dark_Blue"))
    playerEditBox:SetMultiLine(false)
    playerEditBox:SetMaxLetters(255)
    playerEditBox:SetAutoFocus(false) -- dont automatically focus
    playerEditBox:SetFontObject(GameFontWhite)
    playerEditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	playerEditBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

    -- Button save player data
    local playerSaveBtn = CreateFrame("Button", nil, listedPlayersFrame, "OptionsButtonTemplate");
    playerSaveBtn:SetPoint("BOTTOMLEFT", listedPlayersFrame, 40, 10)
    playerSaveBtn:SetSize(80, 30);
    playerSaveBtn:SetText("Save");
    playerSaveBtn:SetNormalFontObject(GameFontNormal);
    playerSaveBtn:SetHighlightFontObject(GameFontHighlight);
    playerSaveBtn:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            --table.insert(config.Reasons, reasonEditBox:GetText())
            config.ListedPlayers[player.Text:GetText()] = {playerReason.Text:GetText()or"", playerEditBox:GetText()or""}
            playerEditBox:SetText("")
            UIDropDownMenu_Initialize(player, initializePlayer)
            UIDropDownMenu_SetSelectedID(player, 1) 
            UIDropDownMenu_Initialize(playerReason, initializeReason)
            UIDropDownMenu_SetSelectedID(playerReason, 1) 
        end
    end)

    -- Button remove player
    local playerRemoveBtn = CreateFrame("Button", nil, listedPlayersFrame, "OptionsButtonTemplate");
    playerRemoveBtn:SetPoint("BOTTOMLEFT", listedPlayersFrame, 130, 10)
    playerRemoveBtn:SetSize(80, 30);
    playerRemoveBtn:SetText("Remove");
    playerRemoveBtn:SetNormalFontObject(GameFontNormal);
    playerRemoveBtn:SetHighlightFontObject(GameFontHighlight);
    playerRemoveBtn:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            for k,v in pairs(config.ListedPlayers) do
                if player.Text:GetText() == k then
                    --table.remove(config.ListedPlayers, UIDropDownMenu_GetSelectedID(player))
                    config.ListedPlayers[k] = nil
                    print("Removed player: " .. k)
                    UIDropDownMenu_Initialize(player, initializePlayer)
                    UIDropDownMenu_SetSelectedID(player, 1)
                    UIDropDownMenu_Initialize(playerReason, initializeReason)
                    UIDropDownMenu_SetSelectedID(playerReason, 1) 
                    playerEditBox:SetText("")
                    break;
                end
            end
        end
    end)

    -- Add new player window
    listedPlayersNewFrame = CreateFrame("Frame", "ListedPlayersNewPlayerFrame", MyAddon.listedPlayersPanel)
    listedPlayersNewFrame:SetPoint("TOPLEFT", MyAddon.listedPlayersPanel, 10, -280);
    listedPlayersNewFrame:SetSize(250, 130)
    listedPlayersNewFrame:SetBackdrop({
		bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile="Interface\\PVPFrame\\UI-Character-PVP-Highlight", 
		tile = false, tileSize = 0, edgeSize = 8,
		insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    listedPlayersNewFrame:SetBackdropBorderColor(getConfigColors("Black"))
    
    -- Title
    local listedPlayerNewTitle = listedPlayersNewFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    listedPlayerNewTitle:SetPoint("TOPLEFT", listedPlayersNewFrame, 10, -10);
    listedPlayerNewTitle:SetFont("Interface\\AddOns\\Shitlist\\Fonts\\Inconsolata-Bold.ttf", 14);
    listedPlayerNewTitle:SetText("Add new player");

    -- Info
    local listedPlayerInfo = listedPlayersNewFrame:CreateFontString(nil, "OVERLAY", "GameFontWhite");
    listedPlayerInfo:SetPoint("TOPLEFT", listedPlayersNewFrame, 15, -30);
    listedPlayerInfo:SetTextColor(getConfigColors("White"))
    listedPlayerInfo:SetText("name-realm");

    -- Player Description EditBox
    listedPlayerNewEditBox = CreateFrame("EditBox", "ListedPlayerNewEditBox", listedPlayersNewFrame)
    listedPlayerNewEditBox:SetPoint("TOPLEFT", listedPlayersNewFrame, 25, -55)
    listedPlayerNewEditBox:SetSize(200, 30)
    listedPlayerNewEditBox:SetTextInsets(10, 0, 0, 0) 
    listedPlayerNewEditBox:SetBackdrop({
        bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile="Interface\\PVPFrame\\UI-Character-PVP-Highlight", 
        tile = false, tileSize = 0, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    listedPlayerNewEditBox:SetBackdropBorderColor(getConfigColors("Dark_Blue"))
    listedPlayerNewEditBox:SetMultiLine(false)
    listedPlayerNewEditBox:SetMaxLetters(255)
    listedPlayerNewEditBox:SetAutoFocus(false) -- dont automatically focus
    listedPlayerNewEditBox:SetFontObject(GameFontWhite)
    listedPlayerNewEditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    listedPlayerNewEditBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

    -- Button save new player
    local listedPLayersSaveBtn = CreateFrame("Button", nil, listedPlayersNewFrame, "OptionsButtonTemplate");
    listedPLayersSaveBtn:SetPoint("BOTTOMLEFT", listedPlayersNewFrame, 75, 10)
    listedPLayersSaveBtn:SetSize(100, 30);
    listedPLayersSaveBtn:SetText("Save");
    listedPLayersSaveBtn:SetNormalFontObject(GameFontNormal);
    listedPLayersSaveBtn:SetHighlightFontObject(GameFontHighlight);
    listedPLayersSaveBtn:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            --table.insert(config.Reasons, reasonEditBox:GetText())
            config.ListedPlayers[listedPlayerNewEditBox:GetText()] = {playerReason.Text:GetText(), playerEditBox:GetText()}
            print("Added player: " .. listedPlayerNewEditBox:GetText())
            playerEditBox:SetText("")
            listedPlayerNewEditBox:SetText("")
            UIDropDownMenu_Initialize(player, initializePlayer)
            UIDropDownMenu_SetSelectedID(player, 1) 
            UIDropDownMenu_Initialize(playerReason, initializeReason)
            UIDropDownMenu_SetSelectedID(playerReason, 1)
        end
    end)

end
-- Create settings panel
Shitlist:Settings()
