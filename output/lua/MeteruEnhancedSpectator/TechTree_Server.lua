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


                --if ent then
                --   team = ent:GetTeam()
                --end

                --assert(team.OnResearchComplete ~= nil)

                team:OnResearchComplete(ent, researchId)

            end
        end

        -- Clear out table
        -- self.queuedOnResearchComplete:Clear()
    end

    oldTechTreeTriggerQueuedResearchComplete(self)
end


function TechTree:SendTechTreeUpdates(playerList)

    local spectators = Shared.GetEntitiesWithClassname("Spectator")
    local countSpectators = spectators:GetSize() - 1
    for _, techNode in ipairs(self.techNodesChanged:GetList()) do

        local techNodeUpdateTable = BuildTechNodeUpdateMessage(techNode)
        local removedInstances = {}

        for _, player in ipairs(playerList) do

            Server.SendNetworkMessage(player, "TechNodeUpdate", techNodeUpdateTable, true)
            removedInstances = self:SendTechNodeInstances(player, techNode)

            for e = 0, countSpectators do
                local spectatorEntity = spectators:GetEntityAtIndex(e)
                if spectatorEntity and spectatorEntity ~= player and not spectatorEntity:GetIsOnPlayingTeam() then
                    local spectatorClient = Server.GetOwner(spectatorEntity)
                    if spectatorClient and spectatorClient:GetSpectatingPlayer() == player then
                        --Print("TechTree:SendTechTreeUpdates: ".. spectatorEntity:GetName())
                        Server.SendNetworkMessage(spectatorEntity, "TechNodeUpdate", techNodeUpdateTable, true)
                        self:SendTechNodeInstances(spectatorEntity, techNode)
                    end
                end

            end
        end

        -- Remove any done-for research instances after we are done sending them to players.
        if techNode.instances then
            for i = 1, #removedInstances do
                techNode.instances[removedInstances[i]] = nil
            end
        end

    end

    self.techNodesChanged:Clear()

end