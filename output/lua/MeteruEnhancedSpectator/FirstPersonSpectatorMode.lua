function FirstPersonSpectatorMode:FindTarget(spectator)
    local validTarget
    if spectator.selectedId ~= Entity.invalidId then

        validTarget = Shared.GetEntity(spectator.selectedId)
        -- Do not allow spectating Commanders currently in first person.
        -- More work is needed before that is ready.
        if validTarget and validTarget:isa("Commander") then
            validTarget = nil
        end

    end

    local targets = spectator:GetTargetsToFollow()
    if not validTarget then

        -- Find a valid target to follow.
        for t = 1, #targets do

            if targets[t]:isa("Player") and HasMixin(targets[t], "Team") then

                validTarget = targets[t]
                break

            end

        end

    end

    if validTarget then
        --[[@ailmanki
        Adjust relevancy depending on the spectated client]]
        local client = Server.GetOwner(spectator)
        client:SetSpectatingPlayer(validTarget)
        --[[@ailmanki
        Select the id]]
        spectator.selectedId = validTarget:GetId()

        SetRelevancyMaskFirstPersonSpectator(validTarget, client, spectator)
    elseif spectator:GetIsOnPlayingTeam() then
        spectator:SetSpectatorMode(kSpectatorMode.Following)
    else

        -- If there is at least an invalid target, use it as the origin for the spectator
        -- so the spectator free cam isn't placed in the RR for example.
        if #targets > 0 then
            spectator:SetOrigin(targets[1]:GetOrigin() + Vector(0, 1, 0))
        end
        spectator:SetSpectatorMode(kSpectatorMode.FreeLook)

    end

end


--[[@ailmanki
Adjust relevancy depending on the spectated client]]
function SetRelevancyMaskFirstPersonSpectator(target, client, spectator)
    local mask
    if spectator:GetIsOnPlayingTeam() or spectator.relevancy then
        local teamNumber = target:GetTeamNumber()
        if teamNumber == 1 then
            mask = kRelevantToTeam1Unit
            spectator.relevancyOverhead = 1
        elseif teamNumber == 2 then
            mask = kRelevantToTeam2Unit
            spectator.relevancyOverhead = 2
        else
            -- should never happen
            mask = bit.bor(kRelevantToTeam1Unit, kRelevantToTeam2Unit, kRelevantToReadyRoom)
            spectator.relevancyOverhead = 0
        end
    else
        mask = bit.bor(kRelevantToTeam1Unit, kRelevantToTeam2Unit, kRelevantToReadyRoom)
        spectator.relevancyOverhead = 0
    end
    client:SetRelevancyMask(mask)
end

function FirstPersonSpectatorMode:ToggleRelevancy(spectatingEntity, spectatorEntity, client, forward)
    spectatorEntity.relevancy = not spectatorEntity.relevancy
    if spectatorEntity.selectedId ~= Entity.invalidId then
        local validTarget = Shared.GetEntity(spectatorEntity.selectedId)
        if validTarget  then
            local client = Server.GetOwner(spectatorEntity)
            SetRelevancyMaskFirstPersonSpectator(validTarget, client, spectatorEntity)
        end
    end
end

function FirstPersonSpectatorMode:CycleSpectatingPlayer(spectatingEntity, spectatorEntity, client, forward)

    -- Find a valid target to follow.
    local targets = spectatorEntity:GetTargetsToFollow()
    -- Remove any non-players from the list.
    for t = #targets, 1, -1 do

        local target = targets[t]
        if not ( target:isa("Player") and HasMixin(target, "Team") ) then
            table.remove(targets, t)
        end

    end

    local numTargets = #targets
    local validTargetIndex = numTargets > 0 and math.random(1, numTargets) or nil
    -- Look for the current spectatingEntity index.
    for t = 1, #targets do

        if targets[t] == spectatingEntity then

            validTargetIndex = t
            break

        end

    end

    -- Fall back on Following mode if there is no other target.
    if numTargets == 0 then

        spectatorEntity:SetSpectatorMode(kSpectatorMode.Following)
        return true

    elseif validTargetIndex then
        -- Find the next index and cycle around if needed.
        if forward then
            validTargetIndex = validTargetIndex < #targets and validTargetIndex + 1 or 1
        else
            validTargetIndex = validTargetIndex > 1 and validTargetIndex - 1 or #targets
        end

        local finalTargetEnt = targets[validTargetIndex]
        if spectatingEntity ~= finalTargetEnt then

            --[[@ailmanki
            Select the id]]
            spectatorEntity.selectedId = finalTargetEnt:GetId()
            client:SetSpectatingPlayer(finalTargetEnt)

            --[[@ailmanki
            Adjust relevancy depending on the spectated client]]
            SetRelevancyMaskFirstPersonSpectator(finalTargetEnt, client, spectatorEntity)
            return true

        end

    end

    return false

end