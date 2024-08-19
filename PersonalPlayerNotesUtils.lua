local personalPlayerNotes = ...
local L = LibStub("AceLocale-3.0"):GetLocale(personalPlayerNotes, true)

function PersonalPlayerNotes:GetVersion()
    return tostring(C_AddOns.GetAddOnMetadata(personalPlayerNotes, "Version")) or L["PPN_NA"];
end

function PersonalPlayerNotes:GetTitle()
    return C_AddOns.GetAddOnMetadata(personalPlayerNotes, "Title") or L["PPN_NA"];
end

function PersonalPlayerNotes:GetAuthor()
    return C_AddOns.GetAddOnMetadata(personalPlayerNotes, "Author") or L["PPN_NA"];
end

function PersonalPlayerNotes:GetNotes()
    return C_AddOns.GetAddOnMetadata(personalPlayerNotes, "Notes") or L["PPN_NA"];
end

function PersonalPlayerNotes:GetLocalizations()
    return C_AddOns.GetAddOnMetadata(personalPlayerNotes, "X-Localizations") or L["PPN_NA"];
end

function PersonalPlayerNotes:GetCategory()
    return C_AddOns.GetAddOnMetadata(personalPlayerNotes, "X-Category") or L["PPN_NA"];
end

function PersonalPlayerNotes:GetWebsite()
    return C_AddOns.GetAddOnMetadata(personalPlayerNotes, "X-Website") or L["PPN_NA"];
end

function PersonalPlayerNotes:GetLicense()
    return C_AddOns.GetAddOnMetadata(personalPlayerNotes, "X-License") or L["PPN_NA"];
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
        return print(L["PPN_DEBUG"], ...)
    end
    return print(L["PPN_PRINT"], ...)
end

function PersonalPlayerNotes:PrintDebug(...)
    if (self.db and self.db.profile.debug) then
        self:Print(...)
    end
end
