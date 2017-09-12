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

