-- We need to replace the used method Plugin:IsSpectatorAllTalk
-- so if the player is spectator we can check which team the Speaker is in
-- see https://github.com/Person8880/Shine/blob/develop/lua/shine/extensions/basecommands/server.lua
if Shine then
    local Enabled, BaseCommands = Shine:IsExtensionEnabled( "basecommands" )
    if Enabled then

        function CanSpectatorHear( Listener , Speaker)
            if Listener:GetTeamNumber() == ( kSpectatorIndex or 3 ) then
                if Listener.relevancyOverhead == 0 then
                    -- can hear all
                    return true
                elseif Listener.relevancyOverhead == 1 then
                    -- can hear marines (and ready room)
                    return Speaker:GetTeamNumber() ~= ( kTeam2Index or 2 )
                elseif Listener.relevancyOverhead == 2 then
                    -- can hear aliens (and ready room)
                    return Speaker:GetTeamNumber() ~= ( kTeam1Index or 1 )
                end
            end
            return false
        end

        function CanPlayerHearLocalVoice(self, Gamerules, Listener, Speaker, SpeakerClient )
            local ListenerClient = GetClientForPlayer( Listener )
            -- Default behaviour for those that have chosen to disable it.
            if self:IsLocalAllTalkDisabled( ListenerClient )
                    or self:IsLocalAllTalkDisabled( SpeakerClient ) then
                return
            end

            -- Assume non-global means local chat, so "all-talk" means true if distance check passes.
            if self.Config.AllTalkLocal or self.Config.AllTalk or self:IsPregameAllTalk( Gamerules )
                    or ( self.Config.AllTalkSpectator and CanSpectatorHear( Listener, Speaker ) ) then
                return self:ArePlayersInLocalVoiceRange( Speaker, Listener )
            end
        end

        function CanPlayerHearGlobalVoice( self, Gamerules, Listener, Speaker, SpeakerClient )
            if self.Config.AllTalk or self:IsPregameAllTalk( Gamerules )
                    or ( self.Config.AllTalkSpectator and CanSpectatorHear( Listener, Speaker ) ) then
                return true
            end
        end

        Shine.Plugins["basecommands"].CanPlayerHearLocalVoice = CanPlayerHearLocalVoice
        Shine.Plugins["basecommands"].CanPlayerHearGlobalVoice = CanPlayerHearGlobalVoice
    end
end