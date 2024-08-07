local personalPlayerNotes = ...
local L = LibStub("AceLocale-3.0"):GetLocale(personalPlayerNotes, true)

function PersonalPlayerNotes:GetVersion()
    return tostring(GetAddOnMetadata(personalPlayerNotes, "Version")) or L["SHITLIST_NA"];
end

function PersonalPlayerNotes:GetTitle()
    return GetAddOnMetadata(personalPlayerNotes, "Title") or L["SHITLIST_NA"];
end

function PersonalPlayerNotes:GetAuthor()
    return GetAddOnMetadata(personalPlayerNotes, "Author") or L["SHITLIST_NA"];
end

function PersonalPlayerNotes:GetNotes()
    return GetAddOnMetadata(personalPlayerNotes, "Notes") or L["SHITLIST_NA"];
end

function PersonalPlayerNotes:GetLocalizations()
    return GetAddOnMetadata(personalPlayerNotes, "X-Localizations") or L["SHITLIST_NA"];
end

function PersonalPlayerNotes:GetCategory()
    return GetAddOnMetadata(personalPlayerNotes, "X-Category") or L["SHITLIST_NA"];
end

function PersonalPlayerNotes:GetWebsite()
    return GetAddOnMetadata(personalPlayerNotes, "X-Website") or L["SHITLIST_NA"];
end

function PersonalPlayerNotes:GetLicense()
    return GetAddOnMetadata(personalPlayerNotes, "X-License") or L["SHITLIST_NA"];
end

function PersonalPlayerNotes:AceGUIDefaults()
    local aceGUI = LibStub("AceGUI-3.0"):Create("Frame")
    aceGUI:SetCallback("OnClose", function(widget) aceGUI:Release() end)
    aceGUI:SetLayout("Fill")
    aceGUI:SetStatusText(nil)
    aceGUI.statustext:Hide()
    aceGUI.statustext:GetParent():Hide()
    aceGUI:Hide()
    return aceGUI
end

function PersonalPlayerNotes:Print(...)
    if (self.db and self.db.profile.debug) then
        return print(L["SHITLIST_DEBUG"], ...)
    end
    return print(L["SHITLIST_PRINT"], ...)
end

--@debug@
function PersonalPlayerNotes:PrintDebug(...)
    if (self.db and self.db.profile.debug) then
        self:Print(...)
    end
end
--@end-debug@
