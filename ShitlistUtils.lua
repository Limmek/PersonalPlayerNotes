local addonName = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function Shitlist:GetVersion()
    return tostring(GetAddOnMetadata(addonName, "Version")) or L["SHITLIST_NA"];
end

function Shitlist:GetTitle()
    return GetAddOnMetadata(addonName, "Title") or L["SHITLIST_NA"];
end

function Shitlist:GetAuthor()
    return GetAddOnMetadata(addonName, "Author") or L["SHITLIST_NA"];
end

function Shitlist:GetNotes()
    return GetAddOnMetadata(addonName, "Notes") or L["SHITLIST_NA"];
end

function Shitlist:GetLocalizations()
    return GetAddOnMetadata(addonName, "X-Localizations") or L["SHITLIST_NA"];
end

function Shitlist:GetCategory()
    return GetAddOnMetadata(addonName, "X-Category") or L["SHITLIST_NA"];
end

function Shitlist:GetWebsite()
    return GetAddOnMetadata(addonName, "X-Website") or L["SHITLIST_NA"];
end

function Shitlist:GetLicense()
    return GetAddOnMetadata(addonName, "X-License") or L["SHITLIST_NA"];
end

function Shitlist:Print(...)
    if (self.db and self.db.profile.debug) then
        return print(L["SHITLIST_DEBUG"], ...)
    end
    return print(L["SHITLIST_PRINT"], ...)
end

function Shitlist:PrintDebug(...)
    if (self.db and self.db.profile.debug) then
        return print(L["SHITLIST_DEBUG"], ...)
    end
end

function Shitlist:AceGUIDefaults()
    local aceGUI = LibStub("AceGUI-3.0"):Create("Frame")
    aceGUI:SetCallback("OnClose", function(widget) aceGUI:Release() end)
    aceGUI:SetLayout("Fill")
    aceGUI:SetStatusText(nil)
    aceGUI.statustext:Hide()
    aceGUI.statustext:GetParent():Hide()
    aceGUI:Hide()
    return aceGUI
end
