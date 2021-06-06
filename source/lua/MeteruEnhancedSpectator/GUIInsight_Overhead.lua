-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\GUIInsight_Overhead.lua
--
-- Created by: Jon 'Huze' Hughes (jon@jhuze.com)
--
-- Spectator Overhead: Displays mouse over text and loads healthbars
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

--[[
@ailmanki
Was simpler to replace the whole file,
its only a small change, so we keep spectating a "dead" player
]]
class 'GUIInsight_Overhead' (GUIScript)

local showHints, playerFollowAttempts, playerFollowNextAttempt, lastPlayerId

local kPlayerFollowMaxAttempts = 20
local kPlayerFollowCheckInterval = 0.05

function GUIInsight_Overhead:Initialize()
    local kFontScale = GUIScale(Vector(1, 0.8, 0))

    self.mouseoverBackground = GUIManager:CreateGraphicItem()
    self.mouseoverBackground:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.mouseoverBackground:SetLayer(kGUILayerPlayerHUD)
    self.mouseoverBackground:SetColor(Color(1, 1, 1, 0))
    self.mouseoverBackground:SetIsVisible(false)

    self.mouseoverText = GUIManager:CreateTextItem()
    self.mouseoverText:SetFontName(Fonts.kAgencyFB_Medium)
    self.mouseoverText:SetScale(kFontScale)
    self.mouseoverText:SetColor(Color(1, 1, 1, 1))
    self.mouseoverText:SetFontIsBold(true)
    GUIMakeFontScale(self.mouseoverText)

    self.mouseoverTextBack = GUIManager:CreateTextItem()
    self.mouseoverTextBack:SetFontName(kFontName)
    self.mouseoverTextBack:SetScale(kFontScale)
    self.mouseoverTextBack:SetColor(Color(0, 0, 0, 0.8))
    self.mouseoverTextBack:SetFontIsBold(true)
    self.mouseoverTextBack:SetPosition(GUIScale(Vector(3,3,0)))
    GUIMakeFontScale(self.mouseoverTextBack)

    self.mouseoverBackground:AddChild(self.mouseoverTextBack)
    self.mouseoverBackground:AddChild(self.mouseoverText)

    showHints = Client.GetOptionBoolean("showHints", true) == true

    playerFollowAttempts = 0
    playerFollowNextAttempt = 0
    lastPlayerId = Entity.invalidId

    if showHints then
        GetGUIManager():CreateGUIScriptSingle("GUIInsight_Logout")
    end

    self.keyHints = GUIManager:CreateTextItem()
    self.keyHints:SetFontName(Fonts.kAgencyFB_Tiny)
    self.keyHints:SetScale(GetScaledVector())
    self.keyHints:SetAnchor(GUIItem.Left, GUIItem.Bottom)

    local numLines = 1
    local keyHintsText = table.concat(
            {
                string.format("[%s] Free camera mode", BindingsUI_GetInputValue("Weapon1")),
                string.format("[%s] Overview mode", BindingsUI_GetInputValue("Weapon2")),
                string.format("[%s] First person mode", BindingsUI_GetInputValue("Weapon3")),
                string.format("[%s] Switch mode", BindingsUI_GetInputValue("Jump")),
                string.format("[%s] Stats", BindingsUI_GetInputValue("RequestHealth")),
                string.format("[%s] Toggle health", BindingsUI_GetInputValue("Use")),
                string.format("[%s] Toggle outlines", BindingsUI_GetInputValue("ToggleFlashlight")),
                string.format("[%s/%s] Zoom", BindingsUI_GetInputValue("OverHeadZoomIncrease"),
                        BindingsUI_GetInputValue("OverHeadZoomDecrease")),
                string.format("[%s] Reset zoom", BindingsUI_GetInputValue("OverHeadZoomReset")),
                string.format("[%s] Draw on screen", BindingsUI_GetInputValue("SecondaryAttack")),
                string.format("[%s] Clear screen", BindingsUI_GetInputValue("Reload")),
                string.format("[%s] Toggle this help", BindingsUI_GetInputValue("RequestAmmo")),
                string.format("[%s] Toggle HUD", BindingsUI_GetInputValue("Weapon4")),
                string.format("[%s] Toggle relevancy ", BindingsUI_GetInputValue("Weapon5"))
            }, " ")

    keyHintsText, _, numLines = WordWrap(self.keyHints, keyHintsText, 0, Client.GetScreenWidth() - GUIScale(260))

    self.keyHints:SetPosition(Vector(GUIScale(10), -GUIScale(20 * numLines), 0))
    self.keyHints:SetColor(kWhite)
    GUIMakeFontScale(self.keyHints)

    self.keyHints:SetText(keyHintsText)

    self.reuseGhostGuides = { }
    self.ghostGuides = {}

end

function GUIInsight_Overhead:Uninitialize()

    GUI.DestroyItem(self.mouseoverBackground)

    if self.playerHealthbars then
        GetGUIManager():DestroyGUIScriptSingle("GUIInsight_PlayerHealthbars")
        self.playerHealthbars = nil
    end
    if self.otherHealthbars then
        GetGUIManager():DestroyGUIScriptSingle("GUIInsight_OtherHealthbars")
        self.otherHealthbars = nil
    end
    if showHints then
        GetGUIManager():DestroyGUIScriptSingle("GUIInsight_Logout")
    end

    if self.keyHints then
        GUI.DestroyItem(self.keyHints)
        self.keyHints = nil
    end

    self:DestroyGhostGuides(false)
end

local function GetEntityUnderCursor(player)

    local xScalar, yScalar = Client.GetCursorPos()
    local x = xScalar * Client.GetScreenWidth()
    local y = yScalar * Client.GetScreenHeight()
    local pickVec = CreatePickRay(player, x, y)

    local origin = player:GetOrigin()
    local trace = Shared.TraceRay(origin, origin + pickVec*1000, CollisionRep.Select, PhysicsMask.CommanderSelect, EntityFilterOne(player))
    local recastCount = 0
    while trace.entity == nil and trace.fraction < 1 and trace.normal:DotProduct(Vector(0, 1, 0)) < 0 and recastCount < 3 do
        -- We've hit static geometry with the normal pointing down (ceiling). Re-cast from the point of impact.
        local recastFrom = 1000 * trace.fraction + 0.1
        trace = Shared.TraceRay(origin + pickVec*recastFrom, origin + pickVec*1000, CollisionRep.Select, PhysicsMask.CommanderSelect, EntityFilterOne(player))
        recastCount = recastCount + 1
    end

    return trace.entity, trace.endPoint

end

function GUIInsight_Overhead:AddGhostGuide(target)

    local origin = target:GetOrigin()
    local radii = {}

    local visualRadius = target.GetVisualRadius and target:GetVisualRadius()

    if visualRadius then
        if type(visualRadius) == "table" then
            for i = 1, #visualRadius do
                local r = visualRadius[i]
                radii[#radii+1] = r
            end
        else
            radii[1] = visualRadius
        end
    end

    for i = 1, #radii do
        local radius = radii[i]
        local guide
        if #self.reuseGhostGuides > 0 then
            guide = table.remove(self.reuseGhostGuides)
        end

        -- Insert point, circle
        if not guide then
            guide = Client.CreateRenderDecal()
            guide.material = Client.CreateRenderMaterial()
        end

        local materialName = ConditionalValue(target:GetTeamType() == kAlienTeamType, Commander.kAlienCircleDecalName, Commander.kMarineCircleDecalName)
        guide.material:SetMaterial(materialName)
        guide:SetMaterial(guide.material)
        local coords = Coords.GetTranslation(origin)
        guide:SetCoords( coords )
        guide:SetExtents(Vector(1,1,1)*radius)

        self.ghostGuides[#self.ghostGuides+1] = guide
    end

end

function GUIInsight_Overhead:DestroyGhostGuides(reuse)

    for i = 1, #self.ghostGuides do
        local guide = self.ghostGuides[i]
        if not reuse then
            Client.DestroyRenderDecal(guide)
        else
            guide:SetExtents(Vector(0,0,0))
            table.insert(self.reuseGhostGuides, guide)
        end
    end

    if not reuse then

        for i = 1, #self.reuseGhostGuides do
            local guide = self.reuseGhostGuides[i]
            Client.DestroyRenderMaterial(guide.material)
            Client.DestroyRenderDecal(guide)
            guide = nil
        end

        self.reuseGhostGuides = {}

end

    self.ghostGuides = {}

end

function GUIInsight_Overhead:Update()

    PROFILE("GUIInsight_Overhead:Update")

    local player = Client.GetLocalPlayer()
    if player == nil then
        return
    end

    local entityId = player.followId
    -- Only initialize healthbars after the camera has finished animating
    -- Should help smooth transition to overhead
    if not PlayerUI_IsCameraAnimated() then

        if self.playerHealthbars == nil then
            self.playerHealthbars = GetGUIManager():CreateGUIScriptSingle("GUIInsight_PlayerHealthbars")
        end
        if self.otherHealthbars == nil then
            self.otherHealthbars = GetGUIManager():CreateGUIScriptSingle("GUIInsight_OtherHealthbars")
        end

        -- If we have high ping it will take a while for entities to be relevant to us again, so we retry a few times before we give up and deselect
        if entityId and entityId ~= Entity.invalidId and (playerFollowNextAttempt < Shared.GetTime() or playerFollowNextAttempt == 0) then
            local entity = Shared.GetEntity(entityId)

            -- If we're not in relevancy range, get the position from the mapblips
            if not entity then
                for _, blip in ientitylist(Shared.GetEntitiesWithClassname("MapBlip")) do

                    if blip.ownerEntityId == entityId then

                        local blipOrig = blip:GetOrigin()
                        player:SetWorldScrollPosition(blipOrig.x, blipOrig.z)

                    end
                end
                -- Try to get the player again
                entity = Shared.GetEntity(entityId)
            end

            if entity and entity:isa("Player") and HasMixin(entity, "Team") then
                local origin = entity:GetOrigin()
                player:SetWorldScrollPosition(origin.x, origin.z)
                playerFollowAttempts = 0
                playerFollowNextAttempt = 0
            elseif not entity then
                if playerFollowAttempts < kPlayerFollowMaxAttempts then
                    playerFollowAttempts = playerFollowAttempts + 1
                    playerFollowNextAttempt = Shared.GetTime() + kPlayerFollowCheckInterval
                end
                -- If the player is dead, or the entity is not a player, deselect
            else
                entityId = Entity.invalidId
            end

            if lastPlayerId ~= entityId then
                Client.SendNetworkMessage("SpectatePlayer", {entityId = entityId}, true)
                player.followId = entityId
                lastPlayerId = entityId
                playerFollowAttempts = 0
                playerFollowNextAttempt = 0
            end
        end

    end

    -- Store entity under cursor
    local entity, targetCoord = GetEntityUnderCursor(player)
    local oldId = player.entityIdUnderCursor
    local newId = entity and entity:GetId() or Entity.invalidId
    player.entityIdUnderCursor = newId
    player.groundCoordUnderCursor = targetCoord

    if entity then

        if newId ~= oldId then
            self:AddGhostGuide(entity)
        end

        if HasMixin(entity, "Live") and entity:GetIsAlive() then

        local text = ToString(math.ceil(entity:GetHealthScalar() * 100)) .. "%"

        if HasMixin(entity, "Construct") then
            if not entity:GetIsBuilt() then

                local builtStr
                if entity:GetTeamNumber() == kTeam1Index then
                    builtStr = Locale.ResolveString("TECHPOINT_BUILT")
                else
                    builtStr = Locale.ResolveString("GROWN")
                end
                local constructionStr = string.format(" (%d%% %s)", math.ceil(entity:GetBuiltFraction()*100), builtStr)
                text = text .. constructionStr

            end
        end



        local xScalar, yScalar = Client.GetCursorPos()
        local x = xScalar * Client.GetScreenWidth()
        local y = yScalar * Client.GetScreenHeight()
            self.mouseoverBackground:SetPosition(Vector(x + GUIScale(18), y + GUIScale(18), 0))
            self.mouseoverBackground:SetIsVisible(true)

            self.mouseoverText:SetText(text)
            self.mouseoverTextBack:SetText(text)

        else
            self.mouseoverBackground:SetIsVisible(false)
                    end


            else

        self:DestroyGhostGuides(true)
        self.mouseoverBackground:SetIsVisible(false)

    end

                end

function GUIInsight_Overhead:SendKeyEvent(key, down)
    if not down then return end

    if GetIsBinding(key, "RequestAmmo") then
        self.keyHints:SetIsVisible(not self.keyHints:GetIsVisible())
        return true
    end

    local player = Client.GetLocalPlayer()
    if not player then
        return
            end

    if key == InputKey.MouseButton0 then
        local target = player:GetCrossHairTarget()
        if not target and player.groundCoordUnderCursor then
            local kRange = 2
            local targets = GetEntitiesWithinXYRange("Player", player.groundCoordUnderCursor, kRange)
            target = targets[1]
        end

        if target and target:isa("Player") then

            local followId = target:GetId()

            -- When clicking the same player, deselect so it stops following
            if player.followId == followId then
                followId = Entity.invalidId
            end

            player.followId = followId
            Client.SendNetworkMessage("SpectatePlayer", {entityId = followId}, true)

            return true -- consume the key event

    else
            -- Clicking outside of the frames while not having the graphs up should deselect too
            local guiGraphs = GetGUIManager():GetGUIScriptSingle("GUIInsight_Graphs")
            if not guiGraphs or not guiGraphs:GetIsVisible() then
                player.followId = Entity.invalidId
                Client.SendNetworkMessage("SpectatePlayer", {entityId = player.followId}, true)
    end

end
    end
end

function GUIInsight_Overhead:OnResolutionChanged()
    self:Uninitialize()
    self:Initialize()
end