local oldSpectatingTeamInitialize = SpectatingTeam.Initialize
function SpectatingTeam:Initialize(teamName, teamNumber)
    oldSpectatingTeamInitialize(self, teamName, teamNumber)

    self.lastAlertPriority = {}
    self.lastAlertPriority[kTeam1Index] = 0
    self.lastAlertPriority[kTeam2Index] = 0

    self.lastPlayedTeamAlertName = {}
    self.lastPlayedTeamAlertName[kTeam1Index] = nil
    self.lastPlayedTeamAlertName[kTeam2Index] = nil

    self.timeOfLastPlayedTeamAlert = {}
    self.timeOfLastPlayedTeamAlert[kTeam1Index] = nil
    self.timeOfLastPlayedTeamAlert[kTeam2Index] = nil

    self.timeOfLastTechTreeUpdate = {}
    self.timeOfLastTechTreeUpdate[kTeam1Index] = 0
    self.timeOfLastTechTreeUpdate[kTeam2Index] = 0
end

local oldSpectatingTeamUninitialize = SpectatingTeam.Uninitialize
function SpectatingTeam:Uninitialize()


    self.lastAlertPriority[kTeam1Index] = nil
    self.lastAlertPriority[kTeam2Index] = nil
    self.lastAlertPriority = nil

    self.lastPlayedTeamAlertName[kTeam1Index] = nil
    self.lastPlayedTeamAlertName[kTeam2Index] = nil
    self.lastPlayedTeamAlertName = nil

    self.timeOfLastPlayedTeamAlert[kTeam1Index] = nil
    self.timeOfLastPlayedTeamAlert[kTeam2Index] = nil
    self.timeOfLastPlayedTeamAlert = nil

    self.timeOfLastTechTreeUpdate[kTeam1Index] = nil
    self.timeOfLastTechTreeUpdate[kTeam2Index] = nil
    self.timeOfLastTechTreeUpdate = nil

    oldSpectatingTeamUninitialize(self)
end

local function getTechTree(teamNumber)
    local team = GetGamerules():GetTeam(teamNumber)
    if team then
        return team:GetTechTree()
    end
end

function SpectatingTeam:OnResearchComplete(structure, researchId)
    Print("SpectatingTeam:OnResearchComplete")

    if structure then
        local team = structure:GetTeam()
        if team == nil then
            return
        end
        local teamNumber = team:GetTeamNumber()

        local shouldDoAlert = not LookupTechData(researchId, kTechDataResearchIgnoreCompleteAlert, false)
        if shouldDoAlert then
            local techTree = getTechTree(teamNumber)
            local techNode = techTree:GetTechNode(researchId)

            if techNode and (techNode:GetIsEnergyManufacture() or techNode:GetIsManufacture() or techNode:GetIsPlasmaManufacture()) then
                self:TriggerAlert(ConditionalValue(teamNumber == kMarineTeamType, kTechId.MarineAlertManufactureComplete, kTechId.AlienAlertManufactureComplete), structure, false, teamNumber)
            else
                self:TriggerAlert(ConditionalValue(teamNumber == kMarineTeamType, kTechId.MarineAlertResearchComplete, kTechId.AlienAlertResearchComplete), structure, false, teamNumber)
            end

        end

    end
end

-- Play audio alert for all players, but don't trigger them too often.
-- This also allows neat tactics where players can time strikes to prevent the other team from instant notification of an alert, ala RTS.
-- Returns true if the alert was played.
function SpectatingTeam:TriggerAlert(techId, entity, force, teamNumber)

    local triggeredAlert = false

    assert(techId ~= kTechId.None)
    assert(techId ~= nil)
    assert(entity ~= nil)

    if GetGamerules():GetGameStarted() then

        -- Lookup sound name
        local soundName = LookupTechData(techId, kTechDataAlertSound, "")
        if soundName ~= "" then

            --local location = entity:GetOrigin()
            local isRepeat = (self.lastPlayedTeamAlertName[teamNumber] ~= nil and self.lastPlayedTeamAlertName[teamNumber] == soundName)

            local timeElapsed = math.huge
            if self.timeOfLastPlayedTeamAlert[teamNumber] ~= nil then
                timeElapsed = Shared.GetTime() - self.timeOfLastPlayedTeamAlert[teamNumber]
            end

            -- Ignore source players for some alerts
            --local ignoreSourcePlayer = ConditionalValue(LookupTechData(techId, kTechDataAlertOthersOnly, false), nil, entity)
            local ignoreInterval = LookupTechData(techId, kTechDataAlertIgnoreInterval, false)

            local newAlertPriority = LookupTechData(techId, kTechDataAlertPriority, 0)
            if not self.lastAlertPriority[teamNumber] then
                self.lastAlertPriority[teamNumber] = 0
            end

            -- If time elapsed > kBaseAlertInterval and not a repeat, play it OR
            -- If time elapsed > kRepeatAlertInterval then play it no matter what
            if force or ignoreInterval or (timeElapsed >= PlayingTeam.kBaseAlertInterval and not isRepeat) or timeElapsed >= PlayingTeam.kRepeatAlertInterval or newAlertPriority  > self.lastAlertPriority[teamNumber] then

                -- Play for commanders only or for the whole team
                --local commandersOnly = not LookupTechData(techId, kTechDataAlertTeam, false)

                --local ignoreDistance = LookupTechData(techId, kTechDataAlertIgnoreDistance, false)

                --self:PlayPrivateTeamSound(soundName, location, commandersOnly, ignoreSourcePlayer, ignoreDistance, entity)

                if not ignoreInterval then

                    self.lastPlayedTeamAlertName[teamNumber] = soundName
                    self.lastAlertPriority[teamNumber] = newAlertPriority
                    self.timeOfLastPlayedTeamAlert[teamNumber] = Shared.GetTime()

                end

                triggeredAlert = true

                -- Check if we should also send out a team message for this alert.
                --local sendTeamMessageType = LookupTechData(techId, kTechDataAlertSendTeamMessage)
                --if sendTeamMessageType then
                --    SendTeamMessage(self, sendTeamMessageType, entity:GetLocationId())
                --end

                local TriggerAlert = Closure [=[
                    self techId entity
                    args player
                    player:TriggerAlert(techId, entity)
                ]=]{techId, entity}

                --self:ForEachPlayer(TriggerAlert)
                local playerIds = self.playerIds:GetList()

                for i = #playerIds, 1, -1 do
                    local playerId = playerIds[i]
                    local player = Shared.GetEntity(playerId)
                    if player and player:isa("Player") and player:GetTeamNumber() == teamNumber then
                        if TriggerAlert(player, self.teamNumber) == false then
                            break
                        end
                    end
                end
            end
        end
    end

    return triggeredAlert
end

function SpectatingTeam:Update()
    PROFILE("SpectatingTeam:Update")

    self:UpdateTechTree(kTeam1Index)
    self:UpdateTechTree(kTeam2Index)
end

-- This sends the full tech tree, this only happens after changing the spectated player
-- The TechTree:SendTechTreeUpdates is extended so players also send it to their specs as well
function SpectatingTeam:UpdateTechTree(teamNumber)

    PROFILE("SpectatingTeam:UpdateTechTree")

    local techTree
    local team = GetGamerules():GetTeam(teamNumber)
    if team then
        techTree = team:GetTechTree()
    end

    if techTree and (Shared.GetTime() > self.timeOfLastTechTreeUpdate[teamNumber] + PlayingTeam.kTechTreeUpdateTime) then
        -- Send tech tree base line to players that just started spectating or changed the team they are spectating
        local players = self:GetPlayers()

        local followTargets = {}
        for _, player in ipairs(players) do
            -- get the player being spectated (followed)
            if player:GetSendTechTreeBase() then
                local followId = player:GetFollowingPlayerId()

                -- cache the spectated players teamNumber
                if followTargets[followId] == nil then
                    local followTarget = Shared.GetEntity(followId)
                    if followTarget and followTarget.GetTeamNumber then
                        followTargets[followId] = followTarget:GetTeamNumber()
                    else
                        followTargets[followId] = false
                    end
                end
                if  followTargets[followId] == teamNumber then
                    techTree:SendTechTreeBase(player)
                    player:ClearSendTechTreeBase()
                end
            end
        end

        self.timeOfLastTechTreeUpdate[teamNumber] = Shared.GetTime()
    end
end