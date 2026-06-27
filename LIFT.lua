local ADDON_NAME = ...

local Lift = CreateFrame("Frame")
local DB

local FRAME_DEFS = {
    { key = "character", label = "Character Frame", names = { "CharacterFrame" } },
    { key = "spellbook", label = "Spellbook", names = { "SpellBookFrame" } },
    { key = "talent", label = "Talent Frame", names = { "PlayerTalentFrame", "TalentFrame" } },
    { key = "questlog", label = "Quest Log", names = { "QuestLogFrame" } },
    { key = "quest", label = "Quest Window", names = { "QuestFrame" } },
    { key = "gossip", label = "NPC Dialogue", names = { "GossipFrame" } },
    { key = "friends", label = "Social/Friends", names = { "FriendsFrame" } },
    { key = "guild", label = "Guild", names = { "GuildFrame", "CommunitiesFrame" } },
    { key = "pvp", label = "PvP/Honor", names = { "PVPFrame", "HonorFrame" } },
    { key = "lfg", label = "LFG", names = { "LFGParentFrame", "LFGFrame", "LookingForGroupFrame" } },
    { key = "help", label = "Help/GM Ticket", names = { "HelpFrame", "GMChatStatusFrame" } },
    { key = "tradeskill", label = "TradeSkill/Crafting", names = { "TradeSkillFrame", "CraftFrame" } },
    { key = "merchant", label = "Merchant", names = { "MerchantFrame" } },
    { key = "auction", label = "Auction House", names = { "AuctionFrame", "AuctionHouseFrame" } },
    { key = "trainer", label = "Trainer", names = { "ClassTrainerFrame" } },
    { key = "bank", label = "Bank", names = { "BankFrame" } },
    { key = "inspect", label = "Inspect", names = { "InspectFrame" } },
    { key = "mail", label = "Mail", names = { "MailFrame" }, dragTop = true, dragSources = { "OpenMailFrame", "SendMailFrame" } },
    { key = "itemtext", label = "Item Text", names = { "ItemTextFrame" } },
    { key = "petition", label = "Petition/Charter", names = { "PetitionFrame" } },
    { key = "tabard", label = "Tabard Designer", names = { "TabardFrame" } },
    { key = "taxi", label = "Taxi/Flight Master", names = { "TaxiFrame" } },
    { key = "stable", label = "Stable Master", names = { "PetStableFrame" } },
}

local hookedFrames = {}
local knownFrames = {}
local hookedDragSources = {}

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff5ad7ffLIFT|r: " .. tostring(message))
end

local function EnsureDb()
    if type(LIFTDB) ~= "table" then
        LIFTDB = {}
    end

    if type(LIFTDB.positions) ~= "table" then
        LIFTDB.positions = {}
    end

    DB = LIFTDB
end

local function IsFrameUsable(frame)
    if type(frame) ~= "table" then
        return false
    end

    if frame.IsForbidden and frame:IsForbidden() then
        return false
    end

    if frame.IsProtected and frame:IsProtected() and InCombatLockdown and InCombatLockdown() then
        return false
    end

    return frame.EnableMouse and frame.SetMovable and frame.RegisterForDrag and frame.HookScript
end

local function SavePosition(frame, key)
    if not DB or not DB.positions or not frame or not frame.GetPoint then
        return
    end

    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint(1)
    if not point then
        return
    end

    local relativeName
    if relativeTo and relativeTo.GetName then
        relativeName = relativeTo:GetName()
    end

    if not relativeName or relativeName == "" then
        relativeName = "UIParent"
    end

    DB.positions[key] = {
        point = point,
        relativeTo = relativeName,
        relativePoint = relativePoint or point,
        x = xOfs or 0,
        y = yOfs or 0,
    }
end

local function ApplyPosition(frame, key)
    if not DB or not DB.positions or not frame or not frame.ClearAllPoints or not frame.SetPoint then
        return
    end

    local pos = DB.positions[key]
    if type(pos) ~= "table" or not pos.point then
        return
    end

    if frame.IsProtected and frame:IsProtected() and InCombatLockdown and InCombatLockdown() then
        return
    end

    local relativeTo = _G[pos.relativeTo or "UIParent"] or UIParent
    pcall(function()
        frame:ClearAllPoints()
        frame:SetPoint(pos.point, relativeTo, pos.relativePoint or pos.point, pos.x or 0, pos.y or 0)
    end)
end

local function StopMoving(frame, key)
    if frame.StopMovingOrSizing then
        pcall(frame.StopMovingOrSizing, frame)
    end
    SavePosition(frame, key)
end

local function StartMoving(frame)
    if InCombatLockdown and InCombatLockdown() and frame.IsProtected and frame:IsProtected() then
        return
    end

    if frame.StartMoving then
        pcall(frame.StartMoving, frame)
    end
end

local function HookTitleRegion(frame, key)
    local regions = { frame:GetRegions() }
    for _, region in ipairs(regions) do
        if region and region.GetObjectType and region:GetObjectType() == "FontString" then
            local parent = region:GetParent()
            if parent and parent == frame and region.EnableMouse and region.RegisterForDrag and region.SetScript then
                region:EnableMouse(true)
                region:RegisterForDrag("LeftButton")
                region:SetScript("OnDragStart", function()
                    StartMoving(frame)
                end)
                region:SetScript("OnDragStop", function()
                    StopMoving(frame, key)
                end)
            end
        end
    end
end

local function CreateTopDragHandle(frame, key)
    if not CreateFrame then
        return
    end

    if frame.LIFTTopDragHandle then
        return
    end

    local handle = CreateFrame("Button", nil, frame)
    handle:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -8)
    handle:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -34, -32)
    handle:EnableMouse(true)
    handle:RegisterForDrag("LeftButton")
    handle:SetFrameLevel((frame:GetFrameLevel() or 0) + 8)
    handle:SetScript("OnDragStart", function()
        StartMoving(frame)
    end)
    handle:SetScript("OnDragStop", function()
        StopMoving(frame, key)
    end)
    handle:SetScript("OnMouseUp", function()
        StopMoving(frame, key)
    end)

    frame.LIFTTopDragHandle = handle
end

local function HookDragSource(source, target, key)
    if not source or not target or hookedDragSources[source] then
        return
    end

    if source.EnableMouse and source.RegisterForDrag and source.HookScript then
        source:EnableMouse(true)
        source:RegisterForDrag("LeftButton")
        source:HookScript("OnDragStart", function()
            StartMoving(target)
        end)
        source:HookScript("OnDragStop", function()
            StopMoving(target, key)
        end)
        source:HookScript("OnMouseUp", function()
            StopMoving(target, key)
        end)
        hookedDragSources[source] = true
    end
end

local function HookDragSources(frame, def, key)
    if not def.dragSources then
        return
    end

    for _, name in ipairs(def.dragSources) do
        HookDragSource(_G[name], frame, key)
    end
end

local function MakeDraggable(frame, def)
    if hookedFrames[frame] then
        HookDragSources(frame, def, def.key)
        return false
    end

    if not IsFrameUsable(frame) then
        return false
    end

    local key = def.key
    knownFrames[key] = frame

    pcall(function()
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetClampedToScreen(true)
    end)

    frame:HookScript("OnDragStart", function(self)
        StartMoving(self)
    end)

    frame:HookScript("OnDragStop", function(self)
        StopMoving(self, key)
    end)

    frame:HookScript("OnMouseUp", function(self)
        if self.StopMovingOrSizing then
            StopMoving(self, key)
        end
    end)

    frame:HookScript("OnShow", function(self)
        pcall(function()
            self:SetMovable(true)
            self:EnableMouse(true)
            self:RegisterForDrag("LeftButton")
        end)
        ApplyPosition(self, key)
    end)

    if frame.HookScript and frame.GetRegions then
        pcall(HookTitleRegion, frame, key)
    end

    if def.dragTop then
        pcall(CreateTopDragHandle, frame, key)
    end

    HookDragSources(frame, def, key)

    hookedFrames[frame] = true
    ApplyPosition(frame, key)
    return true
end

local function FindFrame(def)
    for _, name in ipairs(def.names) do
        local frame = _G[name]
        if frame then
            return frame
        end
    end
end

local function RegisterAvailableFrames()
    for _, def in ipairs(FRAME_DEFS) do
        for _, name in ipairs(def.names) do
            local frame = _G[name]
            if frame and MakeDraggable(frame, def) then
                break
            end
        end
    end
end

local function ResetPositions()
    EnsureDb()
    DB.positions = {}
    Print("saved positions reset. Close and reopen windows, or reload UI, to use Blizzard defaults.")
end

local function PrintHelp()
    Print("commands: /lift help, /lift status, /lift reset")
    Print("alias: /dragui")
end

local function PrintStatus()
    RegisterAvailableFrames()

    local active = 0
    local saved = 0

    for _, def in ipairs(FRAME_DEFS) do
        if knownFrames[def.key] or FindFrame(def) then
            active = active + 1
        end
        if DB and DB.positions and DB.positions[def.key] then
            saved = saved + 1
        end
    end

    Print(active .. " supported frames currently available, " .. saved .. " saved positions.")
end

local function SlashHandler(message)
    message = (message or ""):lower():match("^%s*(.-)%s*$")

    if message == "help" or message == "" then
        PrintHelp()
    elseif message == "status" then
        PrintStatus()
    elseif message == "reset" then
        ResetPositions()
    else
        Print("unknown command: " .. message)
        PrintHelp()
    end
end

Lift:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" and addonName == ADDON_NAME then
        EnsureDb()

        SLASH_LIFT1 = "/lift"
        SLASH_LIFT2 = "/dragui"
        SlashCmdList.LIFT = SlashHandler
    elseif event == "PLAYER_LOGIN" then
        RegisterAvailableFrames()
    elseif event == "ADDON_LOADED" then
        RegisterAvailableFrames()
    elseif event == "PLAYER_REGEN_ENABLED" then
        RegisterAvailableFrames()
    end
end)

Lift:RegisterEvent("ADDON_LOADED")
Lift:RegisterEvent("PLAYER_LOGIN")
Lift:RegisterEvent("PLAYER_REGEN_ENABLED")
