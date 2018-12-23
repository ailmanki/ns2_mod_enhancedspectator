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
                end

            end

        end

    end

end