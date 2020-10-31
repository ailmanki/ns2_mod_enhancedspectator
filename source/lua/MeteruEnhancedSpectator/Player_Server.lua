function Player:UpdateClientRelevancyMask()
    local mask = 0xFFFFFFFF

    if GetConcedeSequenceActive() then

        mask = bit.bor(kRelevantToTeam1Unit, kRelevantToTeam2Unit)

    elseif self:GetTeamNumber() == 1 then

        if self:GetIsCommander() then
            mask = kRelevantToTeam1Commander
        else
            mask = kRelevantToTeam1Unit
        end

    elseif self:GetTeamNumber() == 2 then

        if self:GetIsCommander() then
            mask = kRelevantToTeam2Commander
        else
            mask = kRelevantToTeam2Unit
        end

        -- Spectators should see all map blips.
    elseif self:GetTeamNumber() == kSpectatorIndex then

        if self:GetIsOverhead() then

            mask = bit.bor(kRelevantToTeam1Commander, kRelevantToTeam2Commander)

        elseif self:GetIsFirstPerson() then

            --[[ @ailmanki
            Adjust relevancy depending on the spectated client]]
            if self.relevancy and self.selectedId ~= Entity.invalidId then
                local followTarget = Shared.GetEntity(self.selectedId)
                if followTarget and followTarget:isa("Player") then

                    if followTarget:GetTeamNumber() == 1 then
                        mask = kRelevantToTeam1Unit
                    elseif followTarget:GetTeamNumber() == 2 then
                        mask = kRelevantToTeam2Unit
                    else
                        mask = bit.bor(kRelevantToTeam1Unit, kRelevantToTeam2Unit, kRelevantToReadyRoom)
                    end

                else
                    mask = bit.bor(kRelevantToTeam1Unit, kRelevantToTeam2Unit, kRelevantToReadyRoom)
                end
            else
                mask = bit.bor(kRelevantToTeam1Unit, kRelevantToTeam2Unit, kRelevantToReadyRoom)
            end

        end

        -- ReadyRoomPlayers should not see any blips.
    elseif self:GetTeamNumber() == kTeamReadyRoom then
        mask = kRelevantToReadyRoom
    end

    local client = self.client

    -- client may be nil if the server is shutting down.
    if client then
        client:SetRelevancyMask(mask)
    end

end

--[[
 * Check if there were any spectators watching them. Make these
 * spectators follow the new player unless the new player is also
 * a spectator (in which case, make the spectating players follow a new target).
]]
function Player:RemoveSpectators(newPlayer)

    local spectators = Shared.GetEntitiesWithClassname("Spectator")
    for e = 0, spectators:GetSize() - 1 do

        local spectatorEntity = spectators:GetEntityAtIndex(e)
        if spectatorEntity and spectatorEntity ~= newPlayer then
            local spectatorClient = Server.GetOwner(spectatorEntity)
            if spectatorClient and spectatorClient:GetSpectatingPlayer() == self then

                --[[
                    -- @ailmanki
                    -- A dead player becomes a Spectator of another player, as long as he is a playing team - all is fine
                    -- ]]
                --local allowedToFollowNewPlayer = newPlayer and not newPlayer:isa("Spectator") and not newPlayer:isa("Commander") and newPlayer:GetIsOnPlayingTeam()
                local allowedToFollowNewPlayer = newPlayer and not newPlayer:isa("Commander") and newPlayer:GetIsOnPlayingTeam()
                if not allowedToFollowNewPlayer then

                    local success = spectatorEntity:CycleSpectatingPlayer(self, true)
                    if not success and not self:GetIsOnPlayingTeam() then
                        spectatorEntity:SetSpectatorMode(kSpectatorMode.FreeLook)
                    end

                else
                    spectatorClient:SetSpectatingPlayer(newPlayer)
                    --[[@ailmanki
                    Select the id]]
                    spectatorEntity.selectedId = newPlayer:GetId()
                end

            end

        end

    end

end