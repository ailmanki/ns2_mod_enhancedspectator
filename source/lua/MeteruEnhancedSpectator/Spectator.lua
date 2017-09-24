
--
-- Override this method to restrict or allow a target in follow mode.
--
function Spectator:GetIsValidTarget(entity)
    --[[
    -- @ailmanki
    -- A valid target can be dead, so accomodate for that]]
    local isValid = entity and not entity:isa("Commander") -- and (HasMixin(entity, "Live") and entity:GetIsAlive())
    isValid = isValid and (entity:GetTeamNumber() ~= kTeamReadyRoom and entity:GetTeamNumber() ~= kSpectatorIndex)

    return isValid

end

function Spectator:OnEntityChange(oldEntityId, newEntityId)
    Player.OnEntityChange(self, oldEntityId, newEntityId )

    if self.selectedId == oldEntityId then
        --[[
        -- @ailmanki
        -- This part is curious, I do not understand what it is good for
        --
        -- With original code, e.g. set to invalid:
        -- For one respawn cycle spectacting will work,
        -- but on second death one gets transfered immediately to another target -
        -- skipping the Player:RemoveSpectators
        --
        -- Setting it to the newEntitId .. it works, but would it be set to invalid anyway?
        -- ]]
        self.selectedId = newEntityId --Entity.invalidId
    end
end


local kDeltatimeBetweenAction = 0.3

--
-- Return the next mode according to the order of
-- kSpectatorMode enumeration and the current mode
-- selected
--
local function NextSpectatorMode(self, mode)

    if mode == nil then
        mode = self.specMode
    end

    local numModes = 0
    for name, _ in pairs(kSpectatorMode) do

        if type(name) ~= "number" then
            numModes = numModes + 1
        end

    end

    local nextMode = (mode % numModes) + 1
    -- Following is only used directly through SetSpectatorMode(), never in this function.
    if not self:IsValidMode(nextMode) or nextMode == kSpectatorMode.Following or nextMode == kSpectatorMode.KillCam then
        return NextSpectatorMode(self, nextMode)
    else
        return nextMode
    end

end

-- **** NOTE **** First Person keyboard control (mode switching) handled at:
-- GUIFirstPersonSpectate:SendKeyEvent(key, down)
--[[@ailmanki
- add extra function, problem with "local" and filehooks and "post". Would be easy with "replace", but I want to affect as less as possible
- The original function sets the selectedId to invalid, this changes that.
]]
local function UpdateSpectatorModeExtra(self, input)

    assert(Server)

    self.timeFromLastAction = self.timeFromLastAction + input.time
    if self.timeFromLastAction > kDeltatimeBetweenAction then

        if bit.band(input.commands, Move.Jump) ~= 0 then

            self:SetSpectatorMode(NextSpectatorMode(self))
            self.timeFromLastAction = 0

            if self:GetIsOverhead() then
                self:ResetOverheadModeHeight()
                --[[@ailmanki
                -- disabled so we dont loose track in overhead
                ]]
                --self.selectedId = Entity.invalidId
            end

        elseif bit.band(input.commands, Move.Weapon1) ~= 0 then

            self:SetSpectatorMode(kSpectatorMode.FreeLook)
            self.timeFromLastAction = 0

        elseif bit.band(input.commands, Move.Weapon2) ~= 0 then

            self:SetSpectatorMode(kSpectatorMode.Overhead)
            self.timeFromLastAction = 0
            self:ResetOverheadModeHeight()

        elseif bit.band(input.commands, Move.Weapon3) ~= 0 then

            self:SetSpectatorMode(kSpectatorMode.FirstPerson)
            self.timeFromLastAction = 0

        end

    end

    -- Switch away from following mode ASAP while on a playing team.
    -- Prefer first person mode in this case.
    if self:GetIsOnPlayingTeam() and self:GetIsFollowing() then

        local followTarget = Shared.GetEntity(self:GetFollowTargetId())
        -- Disallow following a Player in this case. Allow following Eggs and IPs
        -- for example.
        if not followTarget or followTarget:isa("Player") then
            self:SetSpectatorMode(kSpectatorMode.FirstPerson)
        end

    end

end

--[[@ailmanki
- this part is actually the same as before, just calling my "extra" function
]]
local kSpectatorMapMode = enum( { 'Invisible', 'Small', 'Big' } )
function Spectator:OnProcessMove(input)

    if Client then
        if self.clientSpecMode ~= self.specMode then
            self:SetSpectatorMode(self.specMode)
            self.clientSpecMode = self.specMode
            -- Log("%s: Switching to mode %s", self, self.specMode)
        end
    end

    if self.modeInstance and self.modeInstance.OnProcessMove then
        self.modeInstance:OnProcessMove(self, input)
    end

    self:UpdateMove(input)

    if Server then

        if not self:GetIsRespawning() then
            UpdateSpectatorModeExtra(self, input)
        end

    elseif Client then

        self:UpdateCrossHairTarget()

        -- Toggle the insight GUI.
        if self:GetTeamNumber() == kSpectatorIndex then

            if bit.band(input.commands, Move.Weapon4) ~= 0 then

                self.showInsight = not self.showInsight
                ClientUI.GetScript("GUISpectator"):SetIsVisible(self.showInsight)

                if self.showInsight then

                    self.mapMode = kSpectatorMapMode.Small
                    self:ShowMap(true, false, true)

                else

                    self.mapMode = kSpectatorMapMode.Invisible
                    self:ShowMap(false, false, true)

                end

            end

        end

        -- This flag must be cleared inside OnProcessMove. See explaination in Commander:OverrideInput().
        self.setScrollPosition = false

    end

    self:OnUpdatePlayer(input.time)

    Player.UpdateMisc(self, input)

end