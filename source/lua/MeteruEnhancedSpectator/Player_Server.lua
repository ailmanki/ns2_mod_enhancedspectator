--[[
 * Check if there were any spectators watching them. Make these
 * spectators follow the new player unless the new player is also
 * a spectator (in which case, make the spectating players follow a new target).
]]
function Player:RemoveSpectators(newPlayer)
    local spectatorEntity, spectatorClient, spectatingPlayer
    local spectators = Shared.GetEntitiesWithClassname("Spectator")
--    local message = "[RemoveSpectators]"
    local spectatorSize = spectators:GetSize()
    for e = 0, spectatorSize - 1 do

        spectatorEntity = spectators:GetEntityAtIndex(e)
        if spectatorEntity and spectatorEntity ~= newPlayer then
            spectatorClient = Server.GetOwner(spectatorEntity)
            if spectatorClient then
                spectatingPlayer = spectatorClient:GetSpectatingPlayer()
                if spectatingPlayer and spectatingPlayer == self then
                    --[[
                    -- @ailmanki
                    -- A dead player becomes a Spectator of another player, as long as he is a playing team - all is fine
                    -- ]]
                    local allowedToFollowNewPlayer = newPlayer and not newPlayer:isa("Spectator") and not newPlayer:isa("Commander") and newPlayer:GetIsOnPlayingTeam()
                    --local allowedToFollowNewPlayer = newPlayer and not newPlayer:isa("Commander") and newPlayer:GetIsOnPlayingTeam()
                    if not allowedToFollowNewPlayer then
--                        message = message .. "{-)"
                        local success = spectatorEntity:CycleSpectatingPlayer(self, true)
                        if not success and not self:GetIsOnPlayingTeam() then
                            spectatorEntity:SetSpectatorMode(kSpectatorMode.FreeLook)
                        end

                    else
--                        message = message .. "{+)"
                        spectatorClient:SetSpectatingPlayer(newPlayer)
                    end
                end
            end


        end

    end
--    if spectatorSize > 0 then
--        if spectatorEntity then
--            message = message .. " spectatorEntity:" .. spectatorEntity:GetName()
--        end
--
--        if spectatingPlayer then
--            message = message .. " spectatingPlayer:" .. spectatingPlayer:GetName()
--        end
--        Shared.Message(message .. " spectatorSize:" .. spectatorSize)
--    end
end
