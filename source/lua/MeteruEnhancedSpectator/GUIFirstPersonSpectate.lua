local oldSendKeyEvent = GUIFirstPersonSpectate.SendKeyEvent
function GUIFirstPersonSpectate:SendKeyEvent(key, down)
    if down and GetIsBinding(key, "Weapon5") then
        Client.SendNetworkMessage("FirstPersonSpectateToggleRelevancy", {}, true)
    end
    oldSendKeyEvent(self, key, down)
end
