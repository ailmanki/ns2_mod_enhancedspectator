-- ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\GUIProduction.lua
--
-- Created by: Jon 'Huze' Hughes (jon@jhuze.com)
--
-- Production and Research bar for commanders and spectators
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIList.lua")

class 'GUIProduction' (GUIScript)

local kBackgroundPos
local kIconSize
local kIconSpacing
local kIconOffset
local kResearchBarWidth
local kResearchBarHeight

local kTextureName = "ui/productionbar.dds"
local hammerCoords = {64,0,128,64}
local checkCoords = {0,0,64,64}

local kResearchColor = Color(1, 133 / 255, 0, 1)
local kResearchBackColor = Color(0.2,0.1,0.0,1)
local kDeactivatedColor = Color(1,0.2,0.2,1)
local kStates = enum( {'Unresearched', 'Researching', 'Researched', 'Deactivated'} )

local function UpdateItemsGUIScale(self)
    kBackgroundPos = GUIScale(Vector(20,-100,0))
    kIconSize = GUIScale(Vector(42, 42, 0))
    kIconSpacing = GUIScale(4)
    kIconOffset = Vector(kIconSize.x + kIconSpacing,0,0)
    kResearchBarWidth = kIconSize.x - 2
    kResearchBarHeight = GUIScale(4)
end

local function createTech(self, list, techId)

    local tech = list:Create(techId)
    tech.ResearchTime = LookupTechData(techId, kTechDataResearchTimeKey, 1)

    local techTree = GetTechTree()
    local techNode
    if techTree then techNode = techTree:GetTechNode(techId) end
    if techNode then tech.researchProgress = techNode:GetResearchProgress() end
    if tech.researchProgress then
        tech.StartTime = Shared.GetTime() - tech.researchProgress * tech.ResearchTime
    else
        tech.StartTime = Shared.GetTime()
    end

    local isMarine = self.TeamIndex == kTeam1Index

    local background = tech.Background
    if isMarine then
        background:SetTexture("ui/marine_buildmenu_buttonbg.dds")
    else
        background:SetTexture("ui/alien_buildmenu_buttonbg.dds")
    end
    background:SetSize(kIconSize)

    local iconItem = GUIManager:CreateGraphicItem()
    iconItem:SetTexture("ui/buildmenu.dds")
    iconItem:SetSize(kIconSize)
    iconItem:SetTexturePixelCoordinates(GUIUnpackCoords(GetTextureCoordinatesForIcon(techId, isMarine)))
    iconItem:SetColor(kIconColors[self.TeamIndex])
    background:AddChild(iconItem)
    tech.Icon = iconItem

    local researchBarBack = GUIManager:CreateGraphicItem()
    researchBarBack:SetIsVisible(false)
    researchBarBack:SetColor(kResearchBackColor)
    researchBarBack:SetSize(Vector(kResearchBarWidth, kResearchBarHeight, 0))
    researchBarBack:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    researchBarBack:SetPosition(Vector(1,1,0))
    background:AddChild(researchBarBack)
    tech.ResearchBarBack = researchBarBack

    local researchBar = GUIManager:CreateGraphicItem()
    researchBar:SetColor(kResearchColor)
    researchBar:SetAnchor(GUIItem.Left, GUIItem.Top)
    researchBarBack:AddChild(researchBar)
    tech.ResearchBar = researchBar

    return tech

end

local function alert(self, techId)
    if PlayerUI_GetIsSpecating() then
        local color = kIconColors[self.TeamIndex]
        local text = GetDisplayNameForTechId(techId, "Tech")
        local textColor
        local state = self.States[techId]
        if state == kStates.Researching then
            text = string.format(Locale.ResolveString("PRODUCTION_STARTED"), text)
            textColor = Color(0,1,0,1)
        elseif state == kStates.Researched then
            text = string.format(Locale.ResolveString("PRODUCTION_COMPLETED"), text)
            textColor = Color(1,1,1,1)
        elseif state == kStates.Deactivated then
            text = string.format(Locale.ResolveString("PRODUCTION_LOST"), text)
            textColor = Color(1,0,0,1)
        else
            return
        end

        local icon = {Texture = "ui/buildmenu.dds", TextureCoordinates = GetTextureCoordinatesForIcon(techId, true), Color = color, Size = kIconSize}
        local info = {Text = text, Scale = Vector(1,1,1), Color = Color(1,1,1,1), ShadowColor = Color(0,0,0,0.5)}
        local position = self.Background:GetScreenPosition(Client.GetScreenWidth(), Client.GetScreenHeight())

        local alert = GUIInsight_AlertQueue:CreateAlert(position, icon, info, self.TeamIndex)
        GUIInsight_AlertQueue:AddAlert(alert, color, textColor)
    end
end

--[[
A - Active
O - Owned
-----
A O |
-----
0 0 | None
1 0 | Researching
0 1 | Lost
1 1 | Researched
-----]]
local function updateState(self, techId, isActive, isOwned)

    local previous = self.States[techId]
    local current
    local list

    if isOwned then
        list = self.Complete
        if isActive then
            current = kStates.Researched
        else
            current = kStates.Deactivated
        end
    else
        if isActive then
            list = self.InProgress
            current = kStates.Researching
        else
            current = kStates.Unresearched
        end
    end

    if previous ~= current then
        --DebugPrint(EnumToString(kTechStates, current))
        self.States[techId] = current
        if previous == kStates.Researching then
            self.InProgress:Remove(techId)
        elseif previous == kStates.Researched or previous == kStates.Deactivated then
            self.Complete:Remove(techId)
        end

        if list then
            local tech = list:Get(techId)
            if not tech then
                tech = createTech(self, list, techId, self.TeamIndex)
                list:Add(tech)
            end
            if current == kStates.Researched then
                tech.Background:SetColor(kIconColors[self.TeamIndex])
                tech.Icon:SetColor(kIconColors[self.TeamIndex])
            elseif current == kStates.Deactivated then
                tech.Background:SetColor(kDeactivatedColor)
                tech.Icon:SetColor(kDeactivatedColor)
            elseif current == kStates.Researching then
                tech.ResearchBarBack:SetIsVisible(true)
            end
        end
        return true
    end
    return false
end

function GUIProduction:Initialize()

    UpdateItemsGUIScale(self)

    local background = GUIManager:CreateGraphicItem()
    background:SetLayer(kGUILayerInsight)
    background:SetColor(Color(0,0,0,0))
    background:SetPosition(kBackgroundPos)
    background:SetAnchor(GUIItem.Right, GUIItem.Bottom)

    local inProgress = GetGUIManager():CreateGUIScript("GUIList")
    inProgress:SetPadding(Vector(0,kResearchBarHeight+2,0))
    background:AddChild(inProgress:GetBackground())

    local complete = GetGUIManager():CreateGUIScript("GUIList")
    complete:GetBackground():SetPosition(Vector(0,kIconSize.y * 1.2,0))
    background:AddChild(complete:GetBackground())

    self.Background = background
    self.InProgress = inProgress
    self.Complete = complete
end

function GUIProduction:Uninitialize()
    GetGUIManager():DestroyGUIScript(self.InProgress)
    GetGUIManager():DestroyGUIScript(self.Complete)
    GUI.DestroyItem(self.Background)

    self.Background = nil
    self.InProgress = nil
    self.Complete = nil
    self.States = nil
    self.PrevTechActive = 0
    self.PrevTechOwned = 0
    self.TeamIndex = 0
end

function GUIProduction:SetSpectatorRight()
    self.Background:SetAnchor(GUIItem.Right, GUIItem.Bottom)
    self.Background:SetPosition(Vector(-GUIScale(280),-GUIScale(120),0))
    self.InProgress:SetAlignment(GUIList.kAlignment.Right)
    self.Complete:SetAlignment(GUIList.kAlignment.Right)
end

function GUIProduction:SetSpectatorLeft()
    self.Background:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.Background:SetPosition(Vector(GUIMinimap.kBackgroundWidth,-GUIScale(120),0))
    self.InProgress:SetAlignment(GUIList.kAlignment.Left)
    self.Complete:SetAlignment(GUIList.kAlignment.Left)
end

function GUIProduction:OnResolutionChanged(oldX, oldY, newX, newY)
    UpdateItemsGUIScale(self)

    self.Background:SetPosition(kBackgroundPos)
    self.InProgress:SetPadding(Vector(0,kResearchBarHeight+2,0))
    self.Complete:GetBackground():SetPosition(Vector(0,kIconSize.y * 1.2,0))

    local function Resize(item, i)
        item.Icon:SetSize(kIconSize)
        item.ResearchBarBack:SetSize(Vector(kResearchBarWidth, kResearchBarHeight, 0))
    end

    self.InProgress:ForEach(Resize)
    self.Complete:ForEach(Resize)
end

function GUIProduction:SetTeam(teamIndex)

    self.TeamIndex = teamIndex
    self.PrevTechActive = 0
    self.PrevTechOwned = 0
    self.States = {}

    self:UpdateTech()

end

function GUIProduction:GetBackground()
    return self.Background
end

function GUIProduction:SetIsVisible(bool)
    self.Background:SetIsVisible(bool)
end

function GUIProduction:UpdateTech(onChange)

    local teamInfo = GetEntitiesForTeam("TeamInfo", self.TeamIndex)[1]
    local techActive, techOwned = teamInfo:GetTeamTechTreeInfo()

    -- Do a comparison on the bitmasks before looping through
    if techActive ~= self.PrevTechActive or techOwned ~= self.PrevTechOwned then
        local relevantIdMask, relevantTechIds = teamInfo:GetRelevantTech()

        for i, techId in ipairs(relevantTechIds) do

            local techIdString = EnumToString(kTechId, techId)
            local isActive = bit.band(techActive, relevantIdMask[techIdString]) > 0
            local isOwned = bit.band(techOwned, relevantIdMask[techIdString]) > 0
            local stateChanged = updateState(self, techId, isActive, isOwned)
            if stateChanged and onChange then
                onChange(self, techId)
            end

        end
        self.PrevTechActive = techActive
        self.PrevTechOwned = techOwned
    end
end

local function updateProgress(tech)

    if tech.StartTime then
        local progress = (Shared.GetTime() - tech.StartTime) / tech.ResearchTime
        if progress < 1 then
            tech.ResearchBarBack:SetIsVisible(true)
            tech.ResearchBar:SetSize(Vector(kResearchBarWidth * progress, kResearchBarHeight, 0))
        else
            tech.ResearchBarBack:SetIsVisible(false)
        end
    end
end

function GUIProduction:Update(deltaTime)
    PROFILE("GUIProduction:Update")
    if self.TeamIndex then

        self:UpdateTech(alert)
        -- update progress bars for researching tech
        self.InProgress:ForEach(updateProgress)

    end
end