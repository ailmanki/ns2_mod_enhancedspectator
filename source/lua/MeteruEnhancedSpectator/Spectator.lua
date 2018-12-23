--
-- Override this method to restrict or allow a target in follow mode.
--
function Spectator:GetIsValidTarget(entity)
    --[[
    -- @ailmanki
    -- A valid target can be dead, so accommodate for that]]
    local isValid = entity and not entity:isa("Commander") -- and (HasMixin(entity, "Live") and entity:GetIsAlive())
    isValid = isValid and (entity:GetTeamNumber() ~= kTeamReadyRoom and entity:GetTeamNumber() ~= kSpectatorIndex)

    return isValid

end
