
-- Utility functions
function GetHasTech(callingEntity, techId, silenceError)

    if callingEntity ~= nil and HasMixin(callingEntity, "Team") then

        local team = GetGamerules():GetTeam(callingEntity:GetTeamNumber())

        if team ~= nil and team.GetTechTree then -- team:isa("PlayingTeam") then

            local techTree = team:GetTechTree()

            if techTree ~= nil then
                return techTree:GetHasTech(techId, silenceError)
            end

        end

    end

    return false

end

local oldTechTreeTriggerQueuedResearchComplete = TechTree.TriggerQueuedResearchComplete
function TechTree:TriggerQueuedResearchComplete()
    if self.queuedOnResearchComplete then

        local team = GetGamerules():GetTeam(kSpectatorIndex)
        assert(team ~= nil)

        for _, pair in ipairs(self.queuedOnResearchComplete:GetList()) do

            local entId = pair[1]
            local researchId = pair[2]

            local ent
            if entId ~= Entity.invalidId then

                -- It's possible that entity has been destroyed before here
                ent = Shared.GetEntity(entId)

            end

            --if ent then
            --   team = ent:GetTeam()
            --end

            assert(team.OnResearchComplete ~= nil)

            team:OnResearchComplete(ent, researchId)

        end

        -- Clear out table
        -- self.queuedOnResearchComplete:Clear()
    end

    oldTechTreeTriggerQueuedResearchComplete(self)
end