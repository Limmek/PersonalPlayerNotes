local personalPlayerNotes = ...
local L = LibStub("AceLocale-3.0"):GetLocale(personalPlayerNotes, true)
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

-- Current SavedVariables schema version. Bump this and extend
-- MigrateSavedVariablesSchema() whenever the profile table shape changes
-- in a way that requires converting existing user data.
PersonalPlayerNotes.SCHEMA_VERSION = 2

--#region Client feature detection

--[[
    Client capabilities are feature-detected instead of branched on
    WOW_PROJECT_ID/flavor, since Classic clients have progressively picked up
    modern Retail APIs and this avoids hardcoding assumptions per client.
]]
function PersonalPlayerNotes:HasModernMenuAPI()
    return type(Menu) == "table" and type(Menu.ModifyMenu) == "function"
end

function PersonalPlayerNotes:HasModernTooltipAPI()
    return type(TooltipDataProcessor) == "table"
        and type(TooltipDataProcessor.AddTooltipPostCall) == "function"
        and type(Enum) == "table"
        and Enum.TooltipDataType ~= nil
end

function PersonalPlayerNotes:HasModernSettingsAPI()
    return type(Settings) == "table" and type(Settings.OpenToCategory) == "function"
end

--[[
    Some Classic clients don't expose the C_AddOns/C_UI namespaces yet, still
    relying on the older global LoadAddOn/DisableAddOn/ReloadUI functions.
    Confirmed via live testing on Wrath Classic.
]]
function PersonalPlayerNotes:HasModernAddOnAPI()
    return type(C_AddOns) == "table"
        and type(C_AddOns.LoadAddOn) == "function"
        and type(C_AddOns.DisableAddOn) == "function"
end

function PersonalPlayerNotes:HasModernUIReloadAPI()
    return type(C_UI) == "table" and type(C_UI.Reload) == "function"
end

--[[
    Patch 12.0.0 (Midnight) introduced "secret values": some unit tokens
    (e.g. those tied to world cursor tooltips over terrain/world objects) can
    no longer be inspected by insecure addon code. Passing one to an API like
    UnitIsPlayer() throws a hard Lua error ("Secret values are only allowed
    during untainted execution for this argument") instead of just returning
    a value, so it must be checked for and skipped rather than caught after
    the fact. issecretvalue() is the client API added to detect this; it may
    not exist on older clients, hence the feature check.
    https://warcraft.wiki.gg/wiki/Secret_Values
]]
function PersonalPlayerNotes:IsSecretUnit(unit)
    return type(issecretvalue) == "function" and issecretvalue(unit) == true
end

--[[
    Opens the Blizzard options window to this addon's category, falling back
    to opening the Ace3 config dialog directly on clients without the modern
    Settings API.

    Settings.OpenToCategory() expects the numeric/category-object ID returned
    by AceConfigDialog:AddToBlizOptions() (stored in
    self.blizOptionsCategoryID during OnInitialize), NOT the addon name
    string - passing the string throws "bad argument #1 to
    'OpenSettingsPanel' (outside of expected range)" on modern clients.
]]
function PersonalPlayerNotes:OpenBlizzardOptions()
    if self:HasModernSettingsAPI() and self.blizOptionsCategoryID then
        Settings.OpenToCategory(self.blizOptionsCategoryID)
    else
        AceConfigDialog:Open("PersonalPlayerNotesSettings Info")
    end
end

--#endregion

--#region SavedVariables migration

--[[
    Parses a legacy Shitlist "Name-Realm" key into separate name/realm values.
    Kept as a pure string function (no SavedVariables/WoW API access) so it
    can be unit tested outside of WoW, see Tests/test_utils.lua.
]]
function PersonalPlayerNotes:ParseLegacyPlayerKey(key)
    if type(key) ~= "string" then
        return nil, nil
    end
    return key:match("([^-]+)-([^-]+)")
end

--[[
    Runs once per login after the AceDB profile is loaded. AceDB-3.0 already
    fills in missing fields from PersonalPlayerNotes.defaults, so this only
    needs to handle actual structural changes between schema versions.
]]
function PersonalPlayerNotes:MigrateSavedVariablesSchema()
    local profile = self.db.profile
    local fromVersion = profile.schemaVersion or 0

    if fromVersion < 1 then
        -- Initial schema version, nothing to convert yet.
    end

    if fromVersion < 2 then
        -- alert.sound used to be a 1-4 index into a per-profile alert.sounds
        -- array; sounds are now selected by filename instead, sourced from
        -- the global PersonalPlayerNotes.SoundManifest (see
        -- Sounds/Manifest.lua) rather than stored per-profile. Reset
        -- everyone to the new default sound rather than trying to map old
        -- indices to filenames, and drop the now-unused sounds array.
        -- (Not read from PersonalPlayerNotes.defaults here: this file's own
        -- unit tests load it in isolation, without PersonalPlayerNotesConfig.lua.)
        profile.alert.sound = "default.mp3"
        profile.alert.sounds = nil
        -- Superseded by alert.customSounds (a list the user can add/remove
        -- entries from) before this ever shipped, so there's no old value to
        -- carry over - just make sure both new fields exist.
        profile.alert.customSoundFile = nil
        profile.alert.customSounds = profile.alert.customSounds or {}
        profile.alert.newCustomSound = profile.alert.newCustomSound or ""
    end

    profile.schemaVersion = PersonalPlayerNotes.SCHEMA_VERSION
end

--#endregion

--#region Addon metadata

--[[
    All of the following read a single field from the .toc's metadata via
    C_AddOns.GetAddOnMetadata(), falling back to L["PPN_NA"] if the field is
    missing (e.g. an optional .toc field like X-Website wasn't set).
]]

--[[
    Returns the addon's Version .toc field, wrapped in tostring() since
    GetAddOnMetadata() can hand back a bare number for numeric-looking
    version strings.
]]
function PersonalPlayerNotes:GetVersion()
    return tostring(C_AddOns.GetAddOnMetadata(personalPlayerNotes, "Version")) or L["PPN_NA"]
end

--[[
    Returns the addon's Title .toc field.
]]
function PersonalPlayerNotes:GetTitle()
    return C_AddOns.GetAddOnMetadata(personalPlayerNotes, "Title") or L["PPN_NA"]
end

--[[
    Returns the addon's Author .toc field.
]]
function PersonalPlayerNotes:GetAuthor()
    return C_AddOns.GetAddOnMetadata(personalPlayerNotes, "Author") or L["PPN_NA"]
end

--[[
    Returns the addon's Notes .toc field.
]]
function PersonalPlayerNotes:GetNotes()
    return C_AddOns.GetAddOnMetadata(personalPlayerNotes, "Notes") or L["PPN_NA"]
end

--[[
    Returns the addon's X-Localizations .toc field.
]]
function PersonalPlayerNotes:GetLocalizations()
    return C_AddOns.GetAddOnMetadata(personalPlayerNotes, "X-Localizations") or L["PPN_NA"]
end

--[[
    Returns the addon's X-Category .toc field.
]]
function PersonalPlayerNotes:GetCategory()
    return C_AddOns.GetAddOnMetadata(personalPlayerNotes, "X-Category") or L["PPN_NA"]
end

--[[
    Returns the addon's X-Website .toc field.
]]
function PersonalPlayerNotes:GetWebsite()
    return C_AddOns.GetAddOnMetadata(personalPlayerNotes, "X-Website") or L["PPN_NA"]
end

--[[
    Returns the addon's X-License .toc field.
]]
function PersonalPlayerNotes:GetLicense()
    return C_AddOns.GetAddOnMetadata(personalPlayerNotes, "X-License") or L["PPN_NA"]
end

--#endregion

-- AceConfigDialog-3.0's width_multiplier is 170px per `width = 1` unit (see
-- AceConfigDialog-3.0.lua). A row of sibling widgets forced onto a single
-- hard line (via an unnamed/borderless inline SimpleGroup - see the comment
-- above Settings.args.contextMenu.args.row1/Reasons.args.iconColorAlert/
-- ListedPlayers.args.iconColorAlert in PersonalPlayerNotesConfig.lua) whose
-- own widths sum to N units therefore needs N*170px of content width. That
-- content area sits behind several nested layers that each eat into it:
-- this Frame's own 34px border padding (AceGUIContainer-Frame.lua), a
-- ScrollFrame's 20px scrollbar gutter once its content overflows vertically
-- (AceGUIContainer-ScrollFrame.lua - AceConfigDialog wraps every root
-- group's content in one of these), and a further 20px for any *named*
-- inline group's own border (AceGUIContainer-InlineGroup.lua - e.g.
-- Settings.args.contextMenu, which has a title, unlike the
-- unnamed/borderless SimpleGroup rows nested inside it). That's 74px of
-- unavailable overhead. WIDTH_SAFETY_MARGIN then adjusts that baseline -
-- tested in-game to be 75px too generous for Reasons/Listed Players'
-- 2.5-unit row (see DIALOG_WIDTH_ADJUSTMENT below for why Settings' 3-unit
-- row needs those 75px added back instead).
local WIDTH_MULTIPLIER = 170
local WIDTH_OVERHEAD = 74
local WIDTH_SAFETY_MARGIN = -9

--[[
    Converts a forced-row width (in width_multiplier units, see above) into
    the Frame width needed to show it without wrapping.
]]
function PersonalPlayerNotes:DialogWidthForUnits(units)
    return math.ceil(units * WIDTH_MULTIPLIER + WIDTH_OVERHEAD + WIDTH_SAFETY_MARGIN)
end

-- The width (in width_multiplier units) of the widest row each option
-- window deliberately forces onto a single line - see
-- DialogWidthForUnits() above. Keyed by the same appName used to
-- AceConfig:RegisterOptionsTable()/OpenDialog() it (PersonalPlayerNotes.lua).
-- Giving each window just enough width for ITS OWN forced row (instead of a
-- single blanket width sized for the widest one of all of them) avoids
-- narrower windows like Reasons/Listed Players (2.5 units - icon+color+
-- alert) looking oddly empty next to Settings' context menu row (3 units -
-- party+friends+chat).
PersonalPlayerNotes.DIALOG_WIDTH_UNITS = {
    ["PersonalPlayerNotesSettings Options"] = 3,
    ["PersonalPlayerNotesSettings Reasons"] = 2.5,
    ["PersonalPlayerNotesSettings Listed_Players"] = 2.5,
}
-- Fallback for any appName not listed above (matches the widest known row,
-- so an unlisted/future window is never too narrow).
PersonalPlayerNotes.DEFAULT_DIALOG_WIDTH_UNITS = 3
-- Per-appName pixel adjustment on top of DialogWidthForUnits() above, for
-- windows that need to differ from what their own width-unit row alone
-- would compute. Settings' context menu row (3 units) is the widest of the
-- three, but its two sibling half-width columns (Settings.args.alert/icons,
-- see PersonalPlayerNotesConfig.lua) each hold their own nested rows that
-- add up to a bit more visual width than the bare 3-unit formula accounts
-- for once tested in-game - hence the positive bump here instead of
-- shrinking Reasons/Listed Players below their own already-correct
-- 2.5-unit formula width.
PersonalPlayerNotes.DIALOG_WIDTH_ADJUSTMENT = {
    ["PersonalPlayerNotesSettings Options"] = 75,
}
-- Shared minimum width (in pixels) for AceGUIDefaults() itself, used only as
-- a generic first-paint default before EnforceDialogWidth() (which knows
-- the appName, and so its actual per-window width) can run - see
-- OpenDialog()/RefreshDialog().
PersonalPlayerNotes.MIN_DIALOG_WIDTH =
    PersonalPlayerNotes:DialogWidthForUnits(PersonalPlayerNotes.DEFAULT_DIALOG_WIDTH_UNITS)
-- Shared minimum/maximum height (in pixels) for every AceGUIDefaults()-backed
-- option window - see ResizeDialogToContent() below. Below
-- MAX_DIALOG_HEIGHT, a window's height auto-wraps to fit whatever's shown;
-- at/above it, the window stops growing and its ScrollFrame shows a
-- scrollbar instead (that part is stock AceGUI-3.0 behavior, automatic once
-- content no longer fits the frame).
PersonalPlayerNotes.MIN_DIALOG_HEIGHT = 200
PersonalPlayerNotes.MAX_DIALOG_HEIGHT = 800
-- Extra headroom (in pixels) added on top of the exact-fit height computed
-- in ResizeDialogToContent() below. The exact-fit math (content height +
-- the Frame widget's own chrome overhead) should in theory need no margin
-- at all, but in practice still left the frame a few pixels too short -
-- clipping the last row of content - likely down to some further rounding
-- this addon's option tables' nested widgets introduce that isn't worth
-- chasing pixel-for-pixel. A small safety margin (mirroring
-- WIDTH_SAFETY_MARGIN above) is a cheap, reliable fix.
local HEIGHT_SAFETY_MARGIN = 12

--[[
    Creates a bare AceGUI-3.0 Frame widget preconfigured the way this addon's
    dropdown/minimap-icon "Add"/"Edit" popups expect it: releases itself on
    close, fills its container, and hides the (unused) status bar text/frame.
    Callers are expected to still call :SetTitle() before showing it.
]]
function PersonalPlayerNotes:AceGUIDefaults()
    local aceGUI = LibStub("AceGUI-3.0"):Create("Frame")
    -- AceGUIContainer-Frame's OnAcquire calls self:Show(), so the frame
    -- starts out visible. Hide it here, BEFORE registering the OnClose
    -- callback below: :Hide() fires OnHide -> Fire("OnClose") synchronously,
    -- and if the release-on-close callback were already registered at that
    -- point it would immediately release this brand-new widget back into
    -- AceGUI's pool (silently, since Release() is otherwise a no-op-looking
    -- call here) before the caller ever gets to configure/show it. A later
    -- :Release() call on the same stale reference (e.g. a guard-clause that
    -- closes a previous popup before opening a new one) would then hit
    -- AceGUI's "Attempt to Release Widget that is already released" error.
    aceGUI:Hide()
    aceGUI:SetCallback("OnClose", function(widget)
        aceGUI:Release()
    end)
    aceGUI:SetLayout("Fill")
    -- MIN_DIALOG_WIDTH is only a generic first-paint default here, sized for
    -- the widest known forced row (see DialogWidthForUnits() and
    -- DIALOG_WIDTH_UNITS above) - EnforceDialogWidth() (called from
    -- OpenDialog()/RefreshDialog(), which know the appName) narrows this
    -- down to the specific window's own actual requirement right after,
    -- and updates the resize floor to match too.
    local minWidth = PersonalPlayerNotes.MIN_DIALOG_WIDTH
    local minHeight = PersonalPlayerNotes.MIN_DIALOG_HEIGHT
    aceGUI:SetWidth(minWidth)
    if aceGUI.frame.SetResizeBounds then -- WoW 10.0+
        aceGUI.frame:SetResizeBounds(minWidth, minHeight)
    else
        aceGUI.frame:SetMinResize(minWidth, minHeight)
    end
    aceGUI:SetStatusText(nil)
    aceGUI.statustext:Hide()
    aceGUI.statustext:GetParent():Hide()
    return aceGUI
end

--[[
    Opens an AceConfig options table (appName) inside a frame built by
    AceGUIDefaults() instead of letting AceConfigDialog:Open() create its own
    bare "Frame" widget - AceConfigDialog's own auto-created frame shows a
    plain, unstyled (black) status bar strip along the bottom that none of
    this addon's other windows have; AceGUIDefaults() hides that.

    AceConfigDialog:Open(appName, container) only reuses/de-dupes via its own
    internal self.OpenFrames[appName] cache when NO container argument is
    passed - passing one every time (as this addon used to) bypassed that
    entirely, so every call created a brand new, untracked frame that never
    got cleaned up (windows stacking endlessly, and :CloseAll() couldn't see
    them to close them either, since it only walks OpenFrames).

    self.customDialogFrames mirrors that same cache, keyed by appName, so
    repeat opens reuse the same frame (refeeding it via AceConfigDialog:Open)
    instead of creating a new one, and the entry is cleared (mirroring
    AceConfigDialog's own internal FrameOnClose behavior) whenever the frame
    closes, so a closed/released frame is never handed back to
    AceConfigDialog:Open() again.
]]

--[[
    AceConfigDialog:Open(appName, container) always calls
    container:SetStatusTable(status) with ITS OWN internal per-appName status
    table (AceConfigDialog:GetStatusTable(appName), defaulting width to 700
    the first time it's ever read) - that runs the frame's ApplyStatus(),
    which unconditionally does self:SetWidth(status.width or 700), silently
    overwriting whatever width AceGUIDefaults() set beforehand. So the
    width AceGUIDefaults() set there only actually takes effect the moment
    the user manually resizes the window (SetResizeBounds/SetMinResize
    clamps that interactive drag, which is why it visually "snaps" to the
    right size then) - on every other open it silently falls back to
    whatever AceConfigDialog's own status table remembers.

    Call this AFTER every AceConfigDialog:Open(appName, frame), so the SAME
    status table AceConfigDialog just applied gets overwritten (to THIS
    appName's own width - see DIALOG_WIDTH_UNITS/DIALOG_WIDTH_ADJUSTMENT
    above) and reapplied immediately, instead of only being fixed
    retroactively on next resize. This is UNCONDITIONAL (not just a
    minimum/floor): status.width can be stale from an earlier session/test
    pass (e.g. it used to hold a wider value back when every window shared
    one flat width) - only clamping upward when too small left any
    previously-too-wide value stuck forever, which looked identical to the
    original bug (only a manual resize would ever "snap" it to the correct
    width). Also refreshes the resize floor to match, so the user still
    can't drag any window narrower than its own correct width.
]]
function PersonalPlayerNotes:EnforceDialogWidth(appName, frame)
    local status = AceConfigDialog:GetStatusTable(appName)
    if not status then
        return
    end
    local units = PersonalPlayerNotes.DIALOG_WIDTH_UNITS[appName] or PersonalPlayerNotes.DEFAULT_DIALOG_WIDTH_UNITS
    local adjustment = PersonalPlayerNotes.DIALOG_WIDTH_ADJUSTMENT[appName] or 0
    local width = PersonalPlayerNotes:DialogWidthForUnits(units) + adjustment
    if frame.frame then
        if frame.frame.SetResizeBounds then -- WoW 10.0+
            frame.frame:SetResizeBounds(width, PersonalPlayerNotes.MIN_DIALOG_HEIGHT)
        else
            frame.frame:SetMinResize(width, PersonalPlayerNotes.MIN_DIALOG_HEIGHT)
        end
    end
    if status.width ~= width then
        status.width = width
        frame:ApplyStatus()
    end
end

--[[
    AceConfigDialog:Open() lays out a dialog's content synchronously - AceGUI's
    "Fill" layout (used by AceGUIDefaults()'s frame) applies immediately,
    it never waits for a later OnUpdate tick (see the disabled
    LayoutOnUpdate code in AceGUI-3.0.lua) - so by the time
    AceConfigDialog:Open() returns, the ScrollFrame it fed the options into
    (see EnforceDialogWidth()'s comment above for why there always is
    one) already knows exactly how tall its content ended up:
    self.content:GetHeight(), set from the height LayoutFinished() was
    called with (AceGUIContainer-ScrollFrame.lua).

    Call this AFTER every AceConfigDialog:Open(appName, frame) (and after
    EnforceDialogWidth(), whose frame:ApplyStatus() call also resets the
    frame's height back to AceConfigDialog's own stale per-appName
    status.height - this needs to run last to win that tug-of-war), so each
    option window's height automatically wraps to fit whatever's actually
    shown: short option groups (Alert, Icons) don't leave a big empty gap,
    and long ones (many Listed Players/Reasons) cap out at
    MAX_DIALOG_HEIGHT and scroll instead of growing off-screen.

    The one wrinkle: the layout pass that JUST finished (inside
    AceConfigDialog:Open(), above) measured content height against whatever
    the frame's height happened to be BEFORE this call (e.g. its previous
    open's height, or the stale AceConfigDialog status.height ApplyStatus()
    just reapplied) - if that was too short for the content,
    AceGUIContainer-ScrollFrame.lua's FixScroll() already decided a
    scrollbar was needed and showed one, which is never revisited just
    because the frame's height changes afterwards (only a fresh layout
    pass re-evaluates it). Left alone, every window would open with a
    scrollbar showing even when its content fits fine at its own correct
    height. So: grow to MAX_DIALOG_HEIGHT and re-check the scrollbar BEFORE
    measuring (giving content every chance to lay out scrollbar-free, at
    full width, so the height read below is its true un-cramped size), then
    shrink to the actual desired height and re-check the scrollbar AGAIN
    (this time it correctly shows one only if content genuinely exceeds
    MAX_DIALOG_HEIGHT).

    A second wrinkle, this time AFTER the fact: AceConfigDialog-3.0's
    ActivateControl (AceConfigDialog-3.0.lua) reruns AceConfigDialog:Open()
    on this SAME frame on virtually every widget interaction inside the
    dialog - selecting a dropdown value, clicking an execute button (e.g.
    Reasons' "Test" sound button), etc. - as a "full refresh" so
    hidden/disabled conditions elsewhere in the options table stay in sync.
    That refeed calls container:SetStatusTable(status) -> ApplyStatus()
    again too, same as the very first open - so unless status.height itself
    is updated to match, ApplyStatus() would silently reapply whatever
    status.height held BEFORE this function ever ran (500, or a stale
    value), undoing this computed height the moment the user so much as
    clicks anything in the window. So the computed height must be written
    back into the SAME AceConfigDialog status table EnforceDialogWidth()
    uses for width, not just applied to the widget directly.
]]
function PersonalPlayerNotes:ResizeDialogToContent(appName, frame)
    local scrollChild = frame.children and frame.children[1]
    local content = scrollChild and scrollChild.content
    if not content then
        return
    end
    frame:SetHeight(PersonalPlayerNotes.MAX_DIALOG_HEIGHT)
    scrollChild:FixScroll()

    -- 57px is the Frame widget's own title bar/chrome overhead subtracted
    -- from its height to get its content area (see OnHeightSet in
    -- AceGUIContainer-Frame.lua). The "Fill" layout stretches the
    -- ScrollFrame to exactly that content area with 0 extra padding (see
    -- the "Fill" layout registration in AceGUI-3.0.lua), so
    -- content height + 57 (+ HEIGHT_SAFETY_MARGIN, see above) is the Frame
    -- height needed to show it all without scrolling.
    local desiredHeight = (content:GetHeight() or 0) + 57 + HEIGHT_SAFETY_MARGIN
    if desiredHeight < PersonalPlayerNotes.MIN_DIALOG_HEIGHT then
        desiredHeight = PersonalPlayerNotes.MIN_DIALOG_HEIGHT
    elseif desiredHeight > PersonalPlayerNotes.MAX_DIALOG_HEIGHT then
        desiredHeight = PersonalPlayerNotes.MAX_DIALOG_HEIGHT
    end
    frame:SetHeight(desiredHeight)
    scrollChild:FixScroll()

    local status = AceConfigDialog:GetStatusTable(appName)
    if status then
        status.height = desiredHeight
    end
end

function PersonalPlayerNotes:OpenDialog(appName)
    self.customDialogFrames = self.customDialogFrames or {}
    local frame = self.customDialogFrames[appName]
    if not frame then
        frame = self:AceGUIDefaults()
        frame:SetCallback("OnClose", function(widget)
            if PersonalPlayerNotes.customDialogFrames[appName] == widget then
                PersonalPlayerNotes.customDialogFrames[appName] = nil
            end
            widget:Release()
        end)
        self.customDialogFrames[appName] = frame
    end
    AceConfigDialog:Open(appName, frame)
    self:EnforceDialogWidth(appName, frame)
    self:ResizeDialogToContent(appName, frame)
    frame:Show()
end

--[[
    Closes every dialog opened via OpenDialog() above. AceConfigDialog:CloseAll()
    only knows about frames it created itself (self.OpenFrames), so it can't
    see or close these custom AceGUIDefaults()-backed containers - callers
    that used to rely on :CloseAll() to reset to a clean slate before opening
    a different window need to call this too.
]]
function PersonalPlayerNotes:CloseAllDialogs()
    if not self.customDialogFrames then
        return
    end
    for _, frame in pairs(self.customDialogFrames) do
        frame:Hide()
    end
end

--[[
    Re-feeds a dialog previously opened via OpenDialog(), if it's currently
    open, so option widgets whose displayed value changed elsewhere (e.g.
    the Reasons/Listed Players "Icon" label after picking a new icon in
    OpenIconPicker()) refresh immediately instead of only on the next open.

    AceConfigDialog normally handles this itself via
    AceConfigRegistry:NotifyChange(appName) - it listens for that and
    refeeds any currently open dialog - but only for frames it tracks in
    its own self.OpenFrames cache (see OpenDialog()'s comment above); frames
    passed in as a custom container (ours) are invisible to that mechanism,
    so callers that call AceConfigRegistry:NotifyChange(appName) need to
    call this too.
]]
function PersonalPlayerNotes:RefreshDialog(appName)
    local frame = self.customDialogFrames and self.customDialogFrames[appName]
    if frame then
        AceConfigDialog:Open(appName, frame)
        self:EnforceDialogWidth(appName, frame)
        self:ResizeDialogToContent(appName, frame)
    end
end

--[[
    Prints to the default chat frame, prefixed with L["PPN_DEBUG"] instead of
    L["PPN_PRINT"] when debug mode is on (self.db.profile.debug). Safe to
    call before self.db exists (e.g. very early during load).
]]
function PersonalPlayerNotes:Print(...)
    if self.db and self.db.profile.debug then
        return print(L["PPN_DEBUG"], ...)
    end
    return print(L["PPN_PRINT"], ...)
end

--[[
    Forwards to Print() only while debug mode is enabled; a no-op otherwise.
    Used for verbose logging that shouldn't show up for regular users.
]]
function PersonalPlayerNotes:PrintDebug(...)
    if self.db and self.db.profile.debug then
        self:Print(...)
    end
end
