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
    relevancy = "boolean"
}

local oldOnInitialized = Spectator.OnInitialized
function Spectator:OnInitialized()
    oldOnInitialized(self)
    self.relevancy = false
end

function Spectator:ToggleRelevancy(spectatingPlayer)
    if self.modeInstance and self.modeInstance.CycleSpectatingPlayer then
        local spectatorClient = Server.GetOwner(self)
        return self.modeInstance:ToggleRelevancy(spectatingPlayer, self, spectatorClient, forward)
    end
    return false
end

Shared.LinkClassToMap("Spectator", Spectator.kMapName, networkVars)