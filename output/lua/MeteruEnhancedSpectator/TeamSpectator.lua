function TeamSpectator:GetIsValidTarget(entity)
    --[[
        -- @ailmanki
        -- add (HasMixin(entity, "Live") and entity:GetIsAlive()) which I had removed from Spectator:GetIsValidTarget
        -- so dead players can only spec living players, reverting my change
        -- ]]
    return Spectator.GetIsValidTarget(self, entity) and (HasMixin(entity, "Live") and entity:GetIsAlive()) and HasMixin(entity, "Team") and (self.specMode == kSpectatorMode.KillCam or entity:GetTeamNumber() == self:GetTeamNumber())
end