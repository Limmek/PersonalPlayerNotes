local shitlist = ...
local L = LibStub("AceLocale-3.0"):GetLocale(shitlist, true)

function Shitlist:GetVersion()
    return tostring(GetAddOnMetadata(shitlist, "Version")) or L["SHITLIST_NA"];
end

function Shitlist:GetTitle()
    return GetAddOnMetadata(shitlist, "Title") or L["SHITLIST_NA"];
end

function Shitlist:GetAuthor()
    return GetAddOnMetadata(shitlist, "Author") or L["SHITLIST_NA"];
end

function Shitlist:GetNotes()
    return GetAddOnMetadata(shitlist, "Notes") or L["SHITLIST_NA"];
end

function Shitlist:GetLocalizations()
    return GetAddOnMetadata(shitlist, "X-Localizations") or L["SHITLIST_NA"];
end

function Shitlist:GetCategory()
    return GetAddOnMetadata(shitlist, "X-Category") or L["SHITLIST_NA"];
end

function Shitlist:GetWebsite()
    return GetAddOnMetadata(shitlist, "X-Website") or L["SHITLIST_NA"];
end

function Shitlist:GetLicense()
    return GetAddOnMetadata(shitlist, "X-License") or L["SHITLIST_NA"];
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

function Shitlist:Print(...)
    if (self.db and self.db.profile.debug) then
        return print(L["SHITLIST_DEBUG"], ...)
    end
    return print(L["SHITLIST_PRINT"], ...)
end

--@debug@
function Shitlist:PrintDebug(...)
    if (self.db and self.db.profile.debug) then
        self:Print(...)
    end
end

--@end-debug@
