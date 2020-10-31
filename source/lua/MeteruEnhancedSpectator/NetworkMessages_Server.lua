local function OnFirstPersonSpectateToggleRelevancy(client, _)
    if client:GetSpectatingPlayer() and client:GetControllingPlayer() then
        if client:GetControllingPlayer().ToggleRelevancy then
            client:GetControllingPlayer():ToggleRelevancy(client:GetSpectatingPlayer())
        end
    end
end
Server.HookNetworkMessage("FirstPersonSpectateToggleRelevancy", OnFirstPersonSpectateToggleRelevancy)