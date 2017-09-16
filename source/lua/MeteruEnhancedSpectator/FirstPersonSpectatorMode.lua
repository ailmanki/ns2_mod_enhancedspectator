function FirstPersonSpectatorMode:CycleSpectatingPlayer(spectatingEntity, spectatorEntity, client, forward)

    -- Find a valid target to follow.
    local targets = spectatorEntity:GetTargetsToFollow()
    -- Remove any non-players from the list.
    for t = #targets, 1, -1 do

        local target = targets[t]
        if not target:isa("Player") then
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

            client:SetSpectatingPlayer(finalTargetEnt)
            spectatorEntity.selectedId = finalTargetEnt:GetId()
            return true

        end

    end

    return false

end