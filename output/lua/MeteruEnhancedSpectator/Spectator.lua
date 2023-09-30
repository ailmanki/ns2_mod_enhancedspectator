--
-- Override this method to restrict or allow a target in follow mode.
--
function Spectator:GetIsValidTarget(entity)
    --[[
    -- @ailmanki
    -- A valid target can be dead, so accommodate for that]]
    local isValid = entity and not entity:isa("Commander")  and not entity.isHallucination  -- and (HasMixin(entity, "Live") and entity:GetIsAlive())
    isValid = isValid and (entity:GetTeamNumber() ~= kTeamReadyRoom and entity:GetTeamNumber() ~= kSpectatorIndex)

    return isValid

end

local networkVars =
{
    relevancy = "boolean",
    relevancyOverhead = "integer (0 to 2)"
}

local oldOnInitialized = Spectator.OnInitialized
function Spectator:OnInitialized()
    oldOnInitialized(self)
    self.relevancy = false
    self.relevancyOverhead = 0
end

function Spectator:ToggleRelevancy(spectatingPlayer)
    if self.modeInstance and self.modeInstance.CycleSpectatingPlayer then
        local spectatorClient = Server.GetOwner(self)
        return self.modeInstance:ToggleRelevancy(spectatingPlayer, self, spectatorClient, forward)
    end
    return false
end


if Server then
    local oldUpdateSpectatorMode = debug.getupvaluex( Spectator.OnProcessMove, "UpdateSpectatorMode")
    local kDeltatimeBetweenAction = 0.3
    local function UpdateSpectatorMode(self, input)
        oldUpdateSpectatorMode(self, input)
        if not (self:GetIsOnPlayingTeam() and self:GetIsFollowing()) then
            if self.timeFromLastAction > kDeltatimeBetweenAction then
                if bit.band(input.commands, Move.Weapon5) ~= 0 then
                    local spectatorClient = Server.GetOwner(self)
                    local mask

                    self.relevancyOverhead = self.relevancyOverhead + 1
                    if self.relevancyOverhead > 2 then
                        self.relevancyOverhead = 0
                    end

                    if self.relevancyOverhead == 0 then
                        mask = bit.bor(kRelevantToTeam1Unit, kRelevantToTeam2Unit, kRelevantToReadyRoom)
                    elseif self.relevancyOverhead == 1 then
                        mask = kRelevantToTeam1Unit
                    else
                        mask = kRelevantToTeam2Unit
                    end

                    spectatorClient:SetRelevancyMask(mask)
                end
            end
        end
    end
    debug.setupvaluex(Spectator.OnProcessMove, "UpdateSpectatorMode", UpdateSpectatorMode)
end

Shared.LinkClassToMap("Spectator", Spectator.kMapName, networkVars)