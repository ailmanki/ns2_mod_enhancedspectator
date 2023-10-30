-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\SpectatingTeam.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
--                  Max McGuire (max@unknownworlds.com)
--
-- This class is used for teams that are only spectating.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Team.lua")
Script.Load("lua/Entity.lua")
Script.Load("lua/TeamDeathMessageMixin.lua")

class 'SpectatingTeam' (Team)

SpectatingTeam.kTooltipHelpInterval = 1

SpectatingTeam.kTechTreeUpdateTime = 1

function SpectatingTeam:Initialize(teamName, teamNumber)
    Team.Initialize(self, teamName, teamNumber)
    self:OnCreate()

    -- child classes can specify a custom team info class
    local teamInfoMapName = TeamInfo.kMapName
    if self.GetTeamInfoMapName then
        teamInfoMapName = self:GetTeamInfoMapName()
    end

    local teamInfoEntity = Server.CreateEntity(teamInfoMapName)

    self.teamInfoEntityId = teamInfoEntity:GetId()
    teamInfoEntity:SetWatchTeam(self)
    self.entityTechIds = {}
    self.entityTechIds[kTeam1Index] = unique_set()
    self.entityTechIds[kTeam2Index] = unique_set()
    self.techIdCount = {}
    self.techIdCount[kTeam1Index] = {}
    self.techIdCount[kTeam2Index] = {}


    self.eventListeners = {}

    self:OnInitialized()
end

function PlayingTeam:AddListener( event, func )

    local listeners = self.eventListeners[event]

    if not listeners then
        listeners = {}
        self.eventListeners[event] = listeners
    end

    table.insert( listeners, func )

    --DebugPrint( 'event %s has %d listeners', event, #self.eventListeners[event] )

end

function SpectatingTeam:GetInfoEntity()
    return Shared.GetEntity(self.teamInfoEntityId)
end


function SpectatingTeam:OnInitialized()

    Team.OnInitialized(self)

    self.techTree = {}
    self:InitTechTreeMarines()
    self:InitTechTreeAliens()

    InitMixin(self, TeamDeathMessageMixin)
end

function SpectatingTeam:Uninitialize()

    if self.teamInfoEntityId and Shared.GetEntity(self.teamInfoEntityId) then

        DestroyEntity(Shared.GetEntity(self.teamInfoEntityId))
        self.teamInfoEntityId = nil

    end

    self.entityTechIds[kTeam1Index] = nil
    self.entityTechIds[kTeam2Index] = nil
    self.entityTechIds = nil

    self.techIdCount[kTeam1Index] = nil
    self.techIdCount[kTeam2Index] = nil
    self.techIdCount = nil

    Team.Uninitialize(self)
end

--
-- Transform player to appropriate team respawn class and respawn them at an appropriate spot for the team.
--
function SpectatingTeam:ReplaceRespawnPlayer(player, origin, angles)

    local spectatorPlayer = player:Replace(Spectator.kMapName, self:GetTeamNumber(), false, origin)
    
    spectatorPlayer:ClearGameEffects()
   
    return true, spectatorPlayer

end


function SpectatingTeam:InitTechTree(teamNumber)
    Print("SpectatingTeam:InitTechTree")
    
    techTree = TechTree()
    
    techTree:Initialize()

    techTree:SetTeamNumber(teamNumber)

    -- Menus
    techTree:AddMenu(kTechId.RootMenu)
    techTree:AddMenu(kTechId.BuildMenu)
    techTree:AddMenu(kTechId.AdvancedMenu)
    techTree:AddMenu(kTechId.AssistMenu)

    -- Orders
    techTree:AddOrder(kTechId.Default)
    techTree:AddOrder(kTechId.Move)
    techTree:AddOrder(kTechId.Patrol)
    techTree:AddOrder(kTechId.Attack)
    techTree:AddOrder(kTechId.Build)
    techTree:AddOrder(kTechId.Construct)
    techTree:AddOrder(kTechId.AutoConstruct)
    techTree:AddAction(kTechId.HoldPosition)

    techTree:AddAction(kTechId.Cancel)

    techTree:AddOrder(kTechId.Weld)

    techTree:AddAction(kTechId.Stop)

    techTree:AddOrder(kTechId.SetRally)
    techTree:AddOrder(kTechId.SetTarget)

    techTree:AddUpgradeNode(kTechId.TransformResources)
    
    return techTree
end

function SpectatingTeam:InitTechTreeMarines()
    Print("SpectatingTeam:InitTechTreeMarines")

    self.techTree[kTeam1Index] = SpectatingTeam.InitTechTree(self, kTeam1Index)

    -- Marine tier 1
    self.techTree[kTeam1Index]:AddBuildNode(kTechId.CommandStation,            kTechId.None,                kTechId.None)
    self.techTree[kTeam1Index]:AddBuildNode(kTechId.Extractor,                 kTechId.None,                kTechId.None)

    self.techTree[kTeam1Index]:AddUpgradeNode(kTechId.ExtractorArmor)

    -- Count recycle like an upgrade so we can have multiples
    self.techTree[kTeam1Index]:AddUpgradeNode(kTechId.Recycle, kTechId.None, kTechId.None)

    self.techTree[kTeam1Index]:AddPassive(kTechId.Welding)
    self.techTree[kTeam1Index]:AddPassive(kTechId.SpawnMarine)
    self.techTree[kTeam1Index]:AddPassive(kTechId.CollectResources, kTechId.Extractor)
    self.techTree[kTeam1Index]:AddPassive(kTechId.Detector)

    self.techTree[kTeam1Index]:AddSpecial(kTechId.TwoCommandStations)
    self.techTree[kTeam1Index]:AddSpecial(kTechId.ThreeCommandStations)

    -- When adding marine upgrades that morph structures, make sure to add to GetRecycleCost() also
    self.techTree[kTeam1Index]:AddBuildNode(kTechId.InfantryPortal,            kTechId.CommandStation,                kTechId.None)
    self.techTree[kTeam1Index]:AddBuildNode(kTechId.Sentry,                    kTechId.RoboticsFactory,     kTechId.None, true)
    self.techTree[kTeam1Index]:AddBuildNode(kTechId.Armory,                    kTechId.CommandStation,      kTechId.None)
    self.techTree[kTeam1Index]:AddBuildNode(kTechId.ArmsLab,                   kTechId.CommandStation,                kTechId.None)
    self.techTree[kTeam1Index]:AddManufactureNode(kTechId.MAC,                 kTechId.RoboticsFactory,                kTechId.None,  true)

    self.techTree[kTeam1Index]:AddBuyNode(kTechId.Axe,                         kTechId.None,              kTechId.None)
    self.techTree[kTeam1Index]:AddBuyNode(kTechId.Pistol,                      kTechId.None,                kTechId.None)
    self.techTree[kTeam1Index]:AddBuyNode(kTechId.Rifle,                       kTechId.None,                kTechId.None)

    self.techTree[kTeam1Index]:AddBuildNode(kTechId.SentryBattery,             kTechId.RoboticsFactory,      kTechId.None)

    self.techTree[kTeam1Index]:AddOrder(kTechId.Defend)
    self.techTree[kTeam1Index]:AddOrder(kTechId.FollowAndWeld)

    -- Commander abilities
    self.techTree[kTeam1Index]:AddResearchNode(kTechId.AdvancedMarineSupport)

    self.techTree[kTeam1Index]:AddTargetedActivation(kTechId.NanoShield,       kTechId.AdvancedMarineSupport)
    self.techTree[kTeam1Index]:AddTargetedActivation(kTechId.Scan,             kTechId.Observatory)
    self.techTree[kTeam1Index]:AddTargetedActivation(kTechId.PowerSurge,       kTechId.AdvancedMarineSupport)
    self.techTree[kTeam1Index]:AddTargetedActivation(kTechId.MedPack,          kTechId.None)
    self.techTree[kTeam1Index]:AddTargetedActivation(kTechId.AmmoPack,         kTechId.None)
    self.techTree[kTeam1Index]:AddTargetedActivation(kTechId.CatPack,          kTechId.AdvancedMarineSupport)

    self.techTree[kTeam1Index]:AddAction(kTechId.SelectObservatory)

    -- Armory upgrades
    self.techTree[kTeam1Index]:AddUpgradeNode(kTechId.AdvancedArmoryUpgrade,  kTechId.Armory)

    -- arms lab upgrades

    self.techTree[kTeam1Index]:AddResearchNode(kTechId.Armor1,                 kTechId.ArmsLab)
    self.techTree[kTeam1Index]:AddResearchNode(kTechId.Armor2,                 kTechId.Armor1, kTechId.None)
    self.techTree[kTeam1Index]:AddResearchNode(kTechId.Armor3,                 kTechId.Armor2, kTechId.None)
    self.techTree[kTeam1Index]:AddResearchNode(kTechId.NanoArmor,              kTechId.None)

    self.techTree[kTeam1Index]:AddResearchNode(kTechId.Weapons1,               kTechId.ArmsLab)
    self.techTree[kTeam1Index]:AddResearchNode(kTechId.Weapons2,               kTechId.Weapons1, kTechId.None)
    self.techTree[kTeam1Index]:AddResearchNode(kTechId.Weapons3,               kTechId.Weapons2, kTechId.None)

    -- Marine tier 2
    self.techTree[kTeam1Index]:AddBuildNode(kTechId.AdvancedArmory,               kTechId.Armory,        kTechId.None)
    self.techTree[kTeam1Index]:AddResearchNode(kTechId.PhaseTech,                    kTechId.Observatory,        kTechId.None)
    self.techTree[kTeam1Index]:AddBuildNode(kTechId.PhaseGate,                    kTechId.PhaseTech,        kTechId.None, true)


    self.techTree[kTeam1Index]:AddBuildNode(kTechId.Observatory,               kTechId.InfantryPortal,       kTechId.Armory)
    self.techTree[kTeam1Index]:AddActivation(kTechId.DistressBeacon,           kTechId.Observatory)
    self.techTree[kTeam1Index]:AddActivation(kTechId.ReversePhaseGate,         kTechId.None)

    -- Door actions
    self.techTree[kTeam1Index]:AddBuildNode(kTechId.Door, kTechId.None, kTechId.None)
    self.techTree[kTeam1Index]:AddActivation(kTechId.DoorOpen)
    self.techTree[kTeam1Index]:AddActivation(kTechId.DoorClose)
    self.techTree[kTeam1Index]:AddActivation(kTechId.DoorLock)
    self.techTree[kTeam1Index]:AddActivation(kTechId.DoorUnlock)

    -- Weapon-specific
    self.techTree[kTeam1Index]:AddResearchNode(kTechId.ShotgunTech,           kTechId.Armory,              kTechId.None)
    self.techTree[kTeam1Index]:AddTargetedBuyNode(kTechId.Shotgun,            kTechId.ShotgunTech,         kTechId.None)
    self.techTree[kTeam1Index]:AddTargetedActivation(kTechId.DropShotgun,     kTechId.ShotgunTech,         kTechId.None)

    --self.techTree[kTeam1Index]:AddResearchNode(kTechId.HeavyMachineGunTech,           kTechId.AdvancedWeaponry,              kTechId.None)
    self.techTree[kTeam1Index]:AddTargetedBuyNode(kTechId.HeavyMachineGun,            kTechId.AdvancedWeaponry)
    self.techTree[kTeam1Index]:AddTargetedActivation(kTechId.DropHeavyMachineGun,     kTechId.AdvancedWeaponry)

    self.techTree[kTeam1Index]:AddResearchNode(kTechId.AdvancedWeaponry,      kTechId.AdvancedArmory,      kTechId.None)

    self.techTree[kTeam1Index]:AddTargetedBuyNode(kTechId.GrenadeLauncher,  kTechId.AdvancedWeaponry)
    self.techTree[kTeam1Index]:AddTargetedActivation(kTechId.DropGrenadeLauncher,  kTechId.AdvancedWeaponry)

    self.techTree[kTeam1Index]:AddResearchNode(kTechId.GrenadeTech,           kTechId.Armory,                   kTechId.None)
    self.techTree[kTeam1Index]:AddTargetedBuyNode(kTechId.ClusterGrenade,     kTechId.GrenadeTech)
    self.techTree[kTeam1Index]:AddTargetedBuyNode(kTechId.GasGrenade,         kTechId.GrenadeTech)
    self.techTree[kTeam1Index]:AddTargetedBuyNode(kTechId.PulseGrenade,       kTechId.GrenadeTech)

    self.techTree[kTeam1Index]:AddTargetedBuyNode(kTechId.Flamethrower,     kTechId.AdvancedWeaponry)
    self.techTree[kTeam1Index]:AddTargetedActivation(kTechId.DropFlamethrower,    kTechId.AdvancedWeaponry)

    self.techTree[kTeam1Index]:AddResearchNode(kTechId.MinesTech,            kTechId.Armory,           kTechId.None)
    self.techTree[kTeam1Index]:AddTargetedBuyNode(kTechId.LayMines,          kTechId.MinesTech,        kTechId.None)
    self.techTree[kTeam1Index]:AddTargetedActivation(kTechId.DropMines,      kTechId.MinesTech,        kTechId.None)

    self.techTree[kTeam1Index]:AddTargetedBuyNode(kTechId.Welder,          kTechId.Armory,        kTechId.None)
    self.techTree[kTeam1Index]:AddTargetedActivation(kTechId.DropWelder,   kTechId.Armory,        kTechId.None)

    -- ARCs
    self.techTree[kTeam1Index]:AddBuildNode(kTechId.RoboticsFactory,                    kTechId.InfantryPortal,    kTechId.None)
    self.techTree[kTeam1Index]:AddUpgradeNode(kTechId.UpgradeRoboticsFactory,           kTechId.None,              kTechId.RoboticsFactory)
    self.techTree[kTeam1Index]:AddBuildNode(kTechId.ARCRoboticsFactory,                 kTechId.None,              kTechId.RoboticsFactory)

    self.techTree[kTeam1Index]:AddTechInheritance(kTechId.RoboticsFactory, kTechId.ARCRoboticsFactory)

    self.techTree[kTeam1Index]:AddManufactureNode(kTechId.ARC,    kTechId.ARCRoboticsFactory,     kTechId.None, true)
    self.techTree[kTeam1Index]:AddActivation(kTechId.ARCDeploy)
    self.techTree[kTeam1Index]:AddActivation(kTechId.ARCUndeploy)

    -- Robotics factory menus
    self.techTree[kTeam1Index]:AddMenu(kTechId.RoboticsFactoryARCUpgradesMenu)
    self.techTree[kTeam1Index]:AddMenu(kTechId.RoboticsFactoryMACUpgradesMenu)

    self.techTree[kTeam1Index]:AddMenu(kTechId.WeaponsMenu)

    -- Marine tier 3
    self.techTree[kTeam1Index]:AddBuildNode(kTechId.PrototypeLab,          kTechId.AdvancedArmory,              kTechId.None)

    -- Jetpack
    self.techTree[kTeam1Index]:AddResearchNode(kTechId.JetpackTech,           kTechId.PrototypeLab, kTechId.None)
    self.techTree[kTeam1Index]:AddBuyNode(kTechId.Jetpack,                    kTechId.JetpackTech, kTechId.None)
    self.techTree[kTeam1Index]:AddTargetedActivation(kTechId.DropJetpack,    kTechId.JetpackTech, kTechId.None)

    -- Exosuit
    self.techTree[kTeam1Index]:AddResearchNode(kTechId.ExosuitTech,           kTechId.PrototypeLab, kTechId.None)
    self.techTree[kTeam1Index]:AddBuyNode(kTechId.DualMinigunExosuit, kTechId.ExosuitTech, kTechId.None)
    self.techTree[kTeam1Index]:AddBuyNode(kTechId.DualRailgunExosuit, kTechId.ExosuitTech, kTechId.None)

    --  self.techTree[kTeam1Index]:AddTargetedActivation(kTechId.DropExosuit,     kTechId.ExosuitTech, kTechId.None)

    --self.techTree[kTeam1Index]:AddResearchNode(kTechId.DualMinigunTech,       kTechId.ExosuitTech, kTechId.TwoCommandStations)
    --self.techTree[kTeam1Index]:AddResearchNode(kTechId.DualMinigunExosuit,    kTechId.DualMinigunTech, kTechId.TwoCommandStations)
    --self.techTree[kTeam1Index]:AddResearchNode(kTechId.ClawRailgunExosuit,    kTechId.ExosuitTech, kTechId.None)
    --self.techTree[kTeam1Index]:AddResearchNode(kTechId.DualRailgunTech,       kTechId.ExosuitTech, kTechId.TwoCommandStations)
    --self.techTree[kTeam1Index]:AddResearchNode(kTechId.DualRailgunExosuit,    kTechId.DualMinigunTech, kTechId.TwoCommandStations)


    self.techTree[kTeam1Index]:AddActivation(kTechId.SocketPowerNode,    kTechId.None,   kTechId.None)

    self.techTree[kTeam1Index]:SetComplete()

    self.requiredTechIds[kTeam1Index] = self.techTree[kTeam1Index]:GetRequiredTechIds()
    self.timeOfLastTechTreeUpdate[kTeam1Index] = nil
end

function SpectatingTeam:InitTechTreeAliens()

    Print("SpectatingTeam:InitTechTreeAliens")

    self.techTree[kTeam2Index] = SpectatingTeam.InitTechTree(self, kTeam2Index)
    
    -- Add special alien menus
    self.techTree[kTeam2Index]:AddMenu(kTechId.MarkersMenu)
    self.techTree[kTeam2Index]:AddMenu(kTechId.UpgradesMenu)
    self.techTree[kTeam2Index]:AddMenu(kTechId.ShadePhantomMenu)
    self.techTree[kTeam2Index]:AddMenu(kTechId.ShadePhantomStructuresMenu)
    self.techTree[kTeam2Index]:AddMenu(kTechId.ShiftEcho, kTechId.ShiftHive)
    self.techTree[kTeam2Index]:AddMenu(kTechId.LifeFormMenu)
    self.techTree[kTeam2Index]:AddMenu(kTechId.SkulkMenu)
    self.techTree[kTeam2Index]:AddMenu(kTechId.GorgeMenu)
    self.techTree[kTeam2Index]:AddMenu(kTechId.LerkMenu)
    self.techTree[kTeam2Index]:AddMenu(kTechId.FadeMenu)
    self.techTree[kTeam2Index]:AddMenu(kTechId.OnosMenu)
    self.techTree[kTeam2Index]:AddMenu(kTechId.Return)

    self.techTree[kTeam2Index]:AddOrder(kTechId.Grow)
    self.techTree[kTeam2Index]:AddAction(kTechId.FollowAlien)

    self.techTree[kTeam2Index]:AddPassive(kTechId.Infestation)
    self.techTree[kTeam2Index]:AddPassive(kTechId.SpawnAlien)
    self.techTree[kTeam2Index]:AddPassive(kTechId.CollectResources, kTechId.Harvester)

    -- Add markers (orders)
    self.techTree[kTeam2Index]:AddSpecial(kTechId.ThreatMarker, kTechId.None, kTechId.None, true)
    self.techTree[kTeam2Index]:AddSpecial(kTechId.LargeThreatMarker, kTechId.None, kTechId.None, true)
    self.techTree[kTeam2Index]:AddSpecial(kTechId.NeedHealingMarker, kTechId.None, kTechId.None, true)
    self.techTree[kTeam2Index]:AddSpecial(kTechId.WeakMarker, kTechId.None, kTechId.None, true)
    self.techTree[kTeam2Index]:AddSpecial(kTechId.ExpandingMarker, kTechId.None, kTechId.None, true)

    -- bio mass levels (required to unlock new abilities)
    self.techTree[kTeam2Index]:AddSpecial(kTechId.BioMassOne)
    self.techTree[kTeam2Index]:AddSpecial(kTechId.BioMassTwo)
    self.techTree[kTeam2Index]:AddSpecial(kTechId.BioMassThree)
    self.techTree[kTeam2Index]:AddSpecial(kTechId.BioMassFour)
    self.techTree[kTeam2Index]:AddSpecial(kTechId.BioMassFive)
    self.techTree[kTeam2Index]:AddSpecial(kTechId.BioMassSix)
    self.techTree[kTeam2Index]:AddSpecial(kTechId.BioMassSeven)
    self.techTree[kTeam2Index]:AddSpecial(kTechId.BioMassEight)
    self.techTree[kTeam2Index]:AddSpecial(kTechId.BioMassNine)
    self.techTree[kTeam2Index]:AddSpecial(kTechId.BioMassTen)
    self.techTree[kTeam2Index]:AddSpecial(kTechId.BioMassEleven)
    self.techTree[kTeam2Index]:AddSpecial(kTechId.BioMassTwelve)

    -- Commander abilities
    self.techTree[kTeam2Index]:AddBuildNode(kTechId.Cyst)
    self.techTree[kTeam2Index]:AddBuildNode(kTechId.NutrientMist)
    self.techTree[kTeam2Index]:AddBuildNode(kTechId.Rupture, kTechId.BioMassTwo)
    self.techTree[kTeam2Index]:AddBuildNode(kTechId.BoneWall, kTechId.BioMassThree)
    self.techTree[kTeam2Index]:AddBuildNode(kTechId.Contamination, kTechId.BioMassTwelve)
    self.techTree[kTeam2Index]:AddAction(kTechId.SelectDrifter)
    self.techTree[kTeam2Index]:AddAction(kTechId.SelectHallucinations, kTechId.ShadeHive)
    self.techTree[kTeam2Index]:AddAction(kTechId.SelectShift, kTechId.ShiftHive)

    -- Count consume like an upgrade so we can have multiples
    self.techTree[kTeam2Index]:AddUpgradeNode(kTechId.Consume, kTechId.None, kTechId.None)

    -- Drifter triggered abilities
    self.techTree[kTeam2Index]:AddTargetedActivation(kTechId.EnzymeCloud,      kTechId.ShiftHive,      kTechId.None)
    self.techTree[kTeam2Index]:AddTargetedActivation(kTechId.Hallucinate,      kTechId.ShadeHive,      kTechId.None)
    self.techTree[kTeam2Index]:AddTargetedActivation(kTechId.MucousMembrane,   kTechId.CragHive,      kTechId.None)
    --self.techTree[kTeam2Index]:AddTargetedActivation(kTechId.Storm,            kTechId.ShiftHive,       kTechId.None)
    self.techTree[kTeam2Index]:AddActivation(kTechId.DestroyHallucination)

    -- Cyst passives
    self.techTree[kTeam2Index]:AddPassive(kTechId.CystCamouflage, kTechId.ShadeHive,      kTechId.None)
    self.techTree[kTeam2Index]:AddPassive(kTechId.CystCelerity, kTechId.ShiftHive,      kTechId.None)
    self.techTree[kTeam2Index]:AddPassive(kTechId.CystCarapace, kTechId.CragHive,      kTechId.None)

    -- Drifter passive abilities
    self.techTree[kTeam2Index]:AddPassive(kTechId.DrifterCamouflage, kTechId.ShadeHive,      kTechId.None)
    self.techTree[kTeam2Index]:AddPassive(kTechId.DrifterCelerity, kTechId.ShiftHive,      kTechId.None)
    self.techTree[kTeam2Index]:AddPassive(kTechId.DrifterRegeneration, kTechId.CragHive,      kTechId.None)

    -- Hive types
    self.techTree[kTeam2Index]:AddBuildNode(kTechId.Hive,                    kTechId.None,           kTechId.None)
    self.techTree[kTeam2Index]:AddPassive(kTechId.HiveHeal)
    self.techTree[kTeam2Index]:AddBuildNode(kTechId.CragHive,                kTechId.Hive,                kTechId.None)
    self.techTree[kTeam2Index]:AddBuildNode(kTechId.ShadeHive,               kTechId.Hive,                kTechId.None)
    self.techTree[kTeam2Index]:AddBuildNode(kTechId.ShiftHive,               kTechId.Hive,                kTechId.None)

    self.techTree[kTeam2Index]:AddTechInheritance(kTechId.Hive, kTechId.CragHive)
    self.techTree[kTeam2Index]:AddTechInheritance(kTechId.Hive, kTechId.ShiftHive)
    self.techTree[kTeam2Index]:AddTechInheritance(kTechId.Hive, kTechId.ShadeHive)

    self.techTree[kTeam2Index]:AddUpgradeNode(kTechId.ResearchBioMassOne)
    self.techTree[kTeam2Index]:AddUpgradeNode(kTechId.ResearchBioMassTwo)
    self.techTree[kTeam2Index]:AddUpgradeNode(kTechId.ResearchBioMassThree)
    self.techTree[kTeam2Index]:AddUpgradeNode(kTechId.ResearchBioMassFour)

    self.techTree[kTeam2Index]:AddUpgradeNode(kTechId.UpgradeToCragHive,     kTechId.Hive,                kTechId.None)
    self.techTree[kTeam2Index]:AddUpgradeNode(kTechId.UpgradeToShadeHive,    kTechId.Hive,                kTechId.None)
    self.techTree[kTeam2Index]:AddUpgradeNode(kTechId.UpgradeToShiftHive,    kTechId.Hive,                kTechId.None)

    self.techTree[kTeam2Index]:AddBuildNode(kTechId.Harvester)
    self.techTree[kTeam2Index]:AddBuildNode(kTechId.DrifterEgg)
    self.techTree[kTeam2Index]:AddBuildNode(kTechId.Drifter, kTechId.None, kTechId.None, true)

    -- Whips
    self.techTree[kTeam2Index]:AddBuildNode(kTechId.Whip,                      kTechId.None,                kTechId.None)
    self.techTree[kTeam2Index]:AddUpgradeNode(kTechId.EvolveBombard,             kTechId.None,                kTechId.None)

    self.techTree[kTeam2Index]:AddPassive(kTechId.WhipBombard)
    self.techTree[kTeam2Index]:AddPassive(kTechId.Slap)
    self.techTree[kTeam2Index]:AddActivation(kTechId.WhipUnroot)
    self.techTree[kTeam2Index]:AddActivation(kTechId.WhipRoot)

    -- Tier 1 lifeforms
    self.techTree[kTeam2Index]:AddAction(kTechId.Skulk,                     kTechId.None,                kTechId.None)
    self.techTree[kTeam2Index]:AddAction(kTechId.Gorge,                     kTechId.None,                kTechId.None)
    self.techTree[kTeam2Index]:AddAction(kTechId.Lerk,                      kTechId.None,                kTechId.None)
    self.techTree[kTeam2Index]:AddAction(kTechId.Fade,                      kTechId.None,                kTechId.None)
    self.techTree[kTeam2Index]:AddAction(kTechId.Onos,                      kTechId.None,                kTechId.None)
    self.techTree[kTeam2Index]:AddBuyNode(kTechId.Egg,                      kTechId.None,                kTechId.None)

    self.techTree[kTeam2Index]:AddUpgradeNode(kTechId.GorgeEgg, kTechId.BioMassTwo)
    self.techTree[kTeam2Index]:AddUpgradeNode(kTechId.LerkEgg, kTechId.BioMassFour)
    self.techTree[kTeam2Index]:AddUpgradeNode(kTechId.FadeEgg, kTechId.BioMassEight)
    self.techTree[kTeam2Index]:AddUpgradeNode(kTechId.OnosEgg, kTechId.BioMassNine)

    -- Special alien structures. These tech nodes are modified at run-time, depending when they are built, so don't modify prereqs.
    self.techTree[kTeam2Index]:AddBuildNode(kTechId.Crag,                      kTechId.Hive,          kTechId.None)
    self.techTree[kTeam2Index]:AddBuildNode(kTechId.Shift,                     kTechId.Hive,          kTechId.None)
    self.techTree[kTeam2Index]:AddBuildNode(kTechId.Shade,                     kTechId.Hive,          kTechId.None)

    -- Alien upgrade structure
    self.techTree[kTeam2Index]:AddBuildNode(kTechId.Shell, kTechId.CragHive)
    self.techTree[kTeam2Index]:AddSpecial(kTechId.TwoShells, kTechId.Shell)
    self.techTree[kTeam2Index]:AddSpecial(kTechId.ThreeShells, kTechId.TwoShells)

    self.techTree[kTeam2Index]:AddBuildNode(kTechId.Veil, kTechId.ShadeHive)
    self.techTree[kTeam2Index]:AddSpecial(kTechId.TwoVeils, kTechId.Veil)
    self.techTree[kTeam2Index]:AddSpecial(kTechId.ThreeVeils, kTechId.TwoVeils)

    self.techTree[kTeam2Index]:AddBuildNode(kTechId.Spur, kTechId.ShiftHive)
    self.techTree[kTeam2Index]:AddSpecial(kTechId.TwoSpurs, kTechId.Spur)
    self.techTree[kTeam2Index]:AddSpecial(kTechId.ThreeSpurs, kTechId.TwoSpurs)


    -- personal upgrades (all alien types)
    self.techTree[kTeam2Index]:AddBuyNode(kTechId.Vampirism, kTechId.Shell, kTechId.None, kTechId.AllAliens)
    self.techTree[kTeam2Index]:AddBuyNode(kTechId.Carapace, kTechId.Shell, kTechId.None, kTechId.AllAliens)
    self.techTree[kTeam2Index]:AddBuyNode(kTechId.Regeneration, kTechId.Shell, kTechId.None, kTechId.AllAliens)

    self.techTree[kTeam2Index]:AddBuyNode(kTechId.Focus, kTechId.Veil, kTechId.None, kTechId.AllAliens)
    self.techTree[kTeam2Index]:AddBuyNode(kTechId.Aura, kTechId.Veil, kTechId.None, kTechId.AllAliens)
    self.techTree[kTeam2Index]:AddBuyNode(kTechId.Camouflage, kTechId.Veil, kTechId.None, kTechId.AllAliens)

    self.techTree[kTeam2Index]:AddBuyNode(kTechId.Crush, kTechId.Spur, kTechId.None, kTechId.AllAliens)
    self.techTree[kTeam2Index]:AddBuyNode(kTechId.Celerity, kTechId.Spur, kTechId.None, kTechId.AllAliens)
    self.techTree[kTeam2Index]:AddBuyNode(kTechId.Adrenaline, kTechId.Spur, kTechId.None, kTechId.AllAliens)


    -- Crag
    self.techTree[kTeam2Index]:AddPassive(kTechId.CragHeal)
    self.techTree[kTeam2Index]:AddActivation(kTechId.HealWave,                kTechId.CragHive,          kTechId.None)

    -- Shift
    self.techTree[kTeam2Index]:AddActivation(kTechId.ShiftHatch,               kTechId.None,         kTechId.None)
    self.techTree[kTeam2Index]:AddPassive(kTechId.ShiftEnergize,               kTechId.None,         kTechId.None)

    self.techTree[kTeam2Index]:AddTargetedActivation(kTechId.TeleportHydra,       kTechId.ShiftHive,         kTechId.None)
    self.techTree[kTeam2Index]:AddTargetedActivation(kTechId.TeleportWhip,        kTechId.ShiftHive,         kTechId.None)
    self.techTree[kTeam2Index]:AddTargetedActivation(kTechId.TeleportTunnel,      kTechId.ShiftHive,         kTechId.None)
    self.techTree[kTeam2Index]:AddTargetedActivation(kTechId.TeleportCrag,        kTechId.ShiftHive,         kTechId.None)
    self.techTree[kTeam2Index]:AddTargetedActivation(kTechId.TeleportShade,       kTechId.ShiftHive,         kTechId.None)
    self.techTree[kTeam2Index]:AddTargetedActivation(kTechId.TeleportShift,       kTechId.ShiftHive,         kTechId.None)
    self.techTree[kTeam2Index]:AddTargetedActivation(kTechId.TeleportVeil,        kTechId.ShiftHive,         kTechId.None)
    self.techTree[kTeam2Index]:AddTargetedActivation(kTechId.TeleportSpur,        kTechId.ShiftHive,         kTechId.None)
    self.techTree[kTeam2Index]:AddTargetedActivation(kTechId.TeleportShell,       kTechId.ShiftHive,         kTechId.None)
    self.techTree[kTeam2Index]:AddTargetedActivation(kTechId.TeleportHive,        kTechId.ShiftHive,         kTechId.None)
    self.techTree[kTeam2Index]:AddTargetedActivation(kTechId.TeleportEgg,         kTechId.ShiftHive,         kTechId.None)
    self.techTree[kTeam2Index]:AddTargetedActivation(kTechId.TeleportHarvester,   kTechId.ShiftHive,         kTechId.None)

    -- Shade
    self.techTree[kTeam2Index]:AddPassive(kTechId.ShadeDisorient)
    self.techTree[kTeam2Index]:AddPassive(kTechId.ShadeCloak)
    self.techTree[kTeam2Index]:AddActivation(kTechId.ShadeInk,                 kTechId.ShadeHive,         kTechId.None)

    self.techTree[kTeam2Index]:AddSpecial(kTechId.TwoHives)
    self.techTree[kTeam2Index]:AddSpecial(kTechId.ThreeHives)

    self.techTree[kTeam2Index]:AddSpecial(kTechId.TwoWhips)
    self.techTree[kTeam2Index]:AddSpecial(kTechId.TwoShifts)
    self.techTree[kTeam2Index]:AddSpecial(kTechId.TwoShades)
    self.techTree[kTeam2Index]:AddSpecial(kTechId.TwoCrags)

    -- Tunnel
    self.techTree[kTeam2Index]:AddBuildNode(kTechId.TunnelExit)
    self.techTree[kTeam2Index]:AddBuildNode(kTechId.TunnelRelocate)
    self.techTree[kTeam2Index]:AddActivation(kTechId.TunnelCollapse)

    --self.techTree[kTeam2Index]:AddBuildNode(kTechId.InfestedTunnel)
    --self.techTree[kTeam2Index]:AddUpgradeNode(kTechId.UpgradeToInfestedTunnel)

    self.techTree[kTeam2Index]:AddAction(kTechId.BuildTunnelMenu)

    self.techTree[kTeam2Index]:AddBuildNode(kTechId.BuildTunnelEntryOne)
    self.techTree[kTeam2Index]:AddBuildNode(kTechId.BuildTunnelEntryTwo)
    self.techTree[kTeam2Index]:AddBuildNode(kTechId.BuildTunnelEntryThree)
    self.techTree[kTeam2Index]:AddBuildNode(kTechId.BuildTunnelEntryFour)
    self.techTree[kTeam2Index]:AddBuildNode(kTechId.BuildTunnelExitOne)
    self.techTree[kTeam2Index]:AddBuildNode(kTechId.BuildTunnelExitTwo)
    self.techTree[kTeam2Index]:AddBuildNode(kTechId.BuildTunnelExitThree)
    self.techTree[kTeam2Index]:AddBuildNode(kTechId.BuildTunnelExitFour)
    self.techTree[kTeam2Index]:AddAction(kTechId.SelectTunnelEntryOne)
    self.techTree[kTeam2Index]:AddAction(kTechId.SelectTunnelEntryTwo)
    self.techTree[kTeam2Index]:AddAction(kTechId.SelectTunnelEntryThree)
    self.techTree[kTeam2Index]:AddAction(kTechId.SelectTunnelEntryFour)
    self.techTree[kTeam2Index]:AddAction(kTechId.SelectTunnelExitOne)
    self.techTree[kTeam2Index]:AddAction(kTechId.SelectTunnelExitTwo)
    self.techTree[kTeam2Index]:AddAction(kTechId.SelectTunnelExitThree)
    self.techTree[kTeam2Index]:AddAction(kTechId.SelectTunnelExitFour)

    -- abilities unlocked by bio mass:

    -- skulk researches
    self.techTree[kTeam2Index]:AddResearchNode(kTechId.Leap,              kTechId.BioMassFour, kTechId.None, kTechId.AllAliens)
    self.techTree[kTeam2Index]:AddResearchNode(kTechId.Xenocide,          kTechId.BioMassNine, kTechId.None, kTechId.AllAliens)

    -- gorge researches
    self.techTree[kTeam2Index]:AddBuyNode(kTechId.BabblerAbility,        kTechId.None)
    self.techTree[kTeam2Index]:AddPassive(kTechId.WebTech,            kTechId.None) --, kTechId.None, kTechId.AllAliens
    --FIXME Above still shows in Alien-Comm buttons/menu
    self.techTree[kTeam2Index]:AddBuyNode(kTechId.Web,                   kTechId.None)
    self.techTree[kTeam2Index]:AddBuyNode(kTechId.BabblerEgg,            kTechId.None)
    self.techTree[kTeam2Index]:AddResearchNode(kTechId.BileBomb,         kTechId.BioMassTwo, kTechId.None, kTechId.AllAliens)

    -- lerk researches
    self.techTree[kTeam2Index]:AddResearchNode(kTechId.Umbra,               kTechId.BioMassSix, kTechId.None, kTechId.AllAliens)
    self.techTree[kTeam2Index]:AddResearchNode(kTechId.Spores,              kTechId.BioMassSix, kTechId.None, kTechId.AllAliens)

    -- fade researches
    self.techTree[kTeam2Index]:AddResearchNode(kTechId.MetabolizeEnergy,        kTechId.BioMassThree, kTechId.None, kTechId.AllAliens)
    self.techTree[kTeam2Index]:AddResearchNode(kTechId.MetabolizeHealth,        kTechId.BioMassFive, kTechId.MetabolizeEnergy, kTechId.AllAliens)
    self.techTree[kTeam2Index]:AddResearchNode(kTechId.Stab,              kTechId.BioMassSeven, kTechId.None, kTechId.AllAliens)

    -- onos researches
    self.techTree[kTeam2Index]:AddPassive(kTechId.Charge)
    self.techTree[kTeam2Index]:AddResearchNode(kTechId.BoneShield,        kTechId.BioMassSix, kTechId.None, kTechId.AllAliens)
    self.techTree[kTeam2Index]:AddResearchNode(kTechId.Stomp,             kTechId.BioMassEight, kTechId.None, kTechId.AllAliens)

    -- gorge structures
    self.techTree[kTeam2Index]:AddBuildNode(kTechId.Hydra)
    self.techTree[kTeam2Index]:AddBuildNode(kTechId.Clog)

    self.techTree[kTeam2Index]:SetComplete()

    self.requiredTechIds[kTeam2Index] = self.techTree[kTeam2Index]:GetRequiredTechIds()
    self.timeOfLastTechTreeUpdate[kTeam2Index] = nil
end

function SpectatingTeam:GetSupportsOrders()
    return false
end
function SpectatingTeam:GetTeamType()
    return self:GetTeamNumber()
end

function SpectatingTeam:TriggerAlert(techId, entity)
    return false
end

local relevantResearchIds
local function GetIsResearchRelevant(techId)

    if not relevantResearchIds then

        relevantResearchIds = {}
        relevantResearchIds[kTechId.GrenadeLauncherTech] = 2
        relevantResearchIds[kTechId.AdvancedWeaponry] = 2
        relevantResearchIds[kTechId.FlamethrowerTech] = 2
        relevantResearchIds[kTechId.WelderTech] = 2
        relevantResearchIds[kTechId.GrenadeTech] = 2
        relevantResearchIds[kTechId.MinesTech] = 2
        relevantResearchIds[kTechId.ShotgunTech] = 2
        relevantResearchIds[kTechId.HeavyMachineGunTech] = 2
        relevantResearchIds[kTechId.ExosuitTech] = 3
        relevantResearchIds[kTechId.JetpackTech] = 3
        relevantResearchIds[kTechId.DualMinigunTech] = 3
        relevantResearchIds[kTechId.ClawRailgunTech] = 3
        relevantResearchIds[kTechId.DualRailgunTech] = 3

        relevantResearchIds[kTechId.DetonationTimeTech] = 2

        relevantResearchIds[kTechId.Armor1] = 1
        relevantResearchIds[kTechId.Armor2] = 1
        relevantResearchIds[kTechId.Armor3] = 1

        relevantResearchIds[kTechId.Weapons1] = 1
        relevantResearchIds[kTechId.Weapons2] = 1
        relevantResearchIds[kTechId.Weapons3] = 1

        relevantResearchIds[kTechId.UpgradeSkulk] = 1
        relevantResearchIds[kTechId.UpgradeGorge] = 1
        relevantResearchIds[kTechId.UpgradeLerk] = 1
        relevantResearchIds[kTechId.UpgradeFade] = 1
        relevantResearchIds[kTechId.UpgradeOnos] = 1

        --relevantResearchIds[kTechId.GorgeTunnelTech] = 1

        relevantResearchIds[kTechId.Leap] = 1
        relevantResearchIds[kTechId.BileBomb] = 1
        relevantResearchIds[kTechId.Spores] = 1
        relevantResearchIds[kTechId.Stab] = 1
        relevantResearchIds[kTechId.Stomp] = 1

        relevantResearchIds[kTechId.Xenocide] = 1
        relevantResearchIds[kTechId.Umbra] = 1
        relevantResearchIds[kTechId.BoneShield] = 1
        relevantResearchIds[kTechId.WebTech] = 1

    end

    return relevantResearchIds[techId]

end

function SpectatingTeam:OnResearchComplete(structure, researchId)
    Print("SpectatingTeam:OnResearchComplete")
    Print("Teamnumber: " .. self:GetTeamNumber())

    local team = structure:GetTeam()
    if team == nil then
        return
    end
    local teamNumber = team:GetTeamNumber()
    --assert(type(researchId) == "table")
    -- Loop through all entities on our team and tell them research was completed
    local teamEnts = GetEntitiesWithMixinForTeam("Research", self:GetTeamNumber())
    for _, ent in ipairs(teamEnts) do
        ent:TechResearched(structure, researchId)
    end

    local shouldDoAlert = not LookupTechData(researchId, kTechDataResearchIgnoreCompleteAlert, false)
    if structure and shouldDoAlert then

        local techNode = self:GetTechTree():GetTechNode(researchId)

        if techNode and (techNode:GetIsEnergyManufacture() or techNode:GetIsManufacture() or techNode:GetIsPlasmaManufacture()) then
            self:TriggerAlert(ConditionalValue(self:GetTeamType() == kMarineTeamType, kTechId.MarineAlertManufactureComplete, kTechId.AlienAlertManufactureComplete), structure)
        else
            self:TriggerAlert(ConditionalValue(self:GetTeamType() == kMarineTeamType, kTechId.MarineAlertResearchComplete, kTechId.AlienAlertResearchComplete), structure)
        end

    end

    -- pass relevant techIds to team info object
    local techPriority = GetIsResearchRelevant(researchId)
    if techPriority ~= nil then

        local teamInfoEntity = Shared.GetEntity(self.teamInfoEntityId)
        teamInfoEntity:SetLatestResearchedTech(researchId, Shared.GetTime() + PlayingTeam.kResearchDisplayTime, techPriority)

    end

    -- inform listeners

    --local listeners = self.eventListeners['OnResearchComplete']
    --
    --if listeners then
    --
    --    for _, listener in ipairs(listeners) do
    --        listener(structure, researchId)
    --    end
    --
    --end

end

function SpectatingTeam:GetTeamResources()
    return 0 -- self.teamResources
end

--Up to implementing child classes to override and calculate reutrn value
function SpectatingTeam:GetTotalInRespawnQueue()
    return 0
end


function SpectatingTeam:GetSupplyUsed()
    return 0 --Clamp(self.supplyUsed, 0, kMaxSupply)
end

function SpectatingTeam:GetTotalTeamResources()
    return 0 --self.totalTeamResourcesCollected
end

function SpectatingTeam:GetCommanderPingTime()
    return 0 -- self.lastCommPingTime
end

function SpectatingTeam:GetCommanderPingPosition()
    return Vector(0,0,0) -- self.lastCommPingPosition
end

function SpectatingTeam:GetNumCapturedTechPoints()

    local commandStructures = GetEntitiesForTeam("CommandStructure", self:GetTeamNumber())
    local count = 0

    for _, cs in ipairs(commandStructures) do

        if cs:GetIsBuilt() and cs:GetIsAlive() and cs:GetAttached() then
            count = count + 1
        end

    end

    return count

end

function SpectatingTeam:GetTotalTeamResources()
    return 0 --self.totalTeamResourcesCollected
end
function SpectatingTeam:TechAdded(entity)
    Print("SpectatingTeam:TechAdded")
    PROFILE("SpectatingTeam:TechAdded")

    -- Tell tech tree to recompute availability next think
    local techId = entity:GetTechId()

    if not self.requiredTechIds then
        self.requiredTechIds = { }
    end

    -- don't do anything if this tech is not prereq of another tech
    if not self.requiredTechIds[techId] then
        return
    end

    self.entityTechIds:Insert(techId)

    if self.techIdCount[techId] then
        self.techIdCount[techId] = self.techIdCount[techId] + 1
    else
        self.techIdCount[techId] = 1
    end

    --Print("TechAdded %s  id: %s", EnumToString(kTechId, entity:GetTechId()), ToString(entity:GetTechId()))
    if self.techTree then
        self.techTree:SetTechChanged()
    end
end

function SpectatingTeam:TechRemoved(entity)

    Print("SpectatingTeam:TechRemoved")
    PROFILE("SpectatingTeam:TechRemoved")

    -- Tell tech tree to recompute availability next think

    local techId = entity:GetTechId()

    -- don't do anything if this tech is not prereq of another tech
    if not self.requiredTechIds[techId] then
        return
    end

    if self.techIdCount[techId] then
        self.techIdCount[techId] = self.techIdCount[techId] - 1
    end

    if self.techIdCount[techId] == nil or self.techIdCount[techId] <= 0 then
        self.entityTechIds:Remove(techId)
        self.techIdCount[techId] = nil
    end

    --Print(ToString(debug.traceback()))
    --Print("TechRemoved %s  id: %s", EnumToString(kTechId, entity:GetTechId()), ToString(entity:GetTechId()))
    if(self.techTree ~= nil) then
        self.techTree:SetTechChanged()
    end

end


function SpectatingTeam:Update()

    PROFILE("SpectatingTeam:Update")

    self:UpdateTechTree(kTeam1Index)
    self:UpdateTechTree(kTeam2Index)

end

function SpectatingTeam:GetTechTree(teamNumber)
    return self.techTree[teamNumber]
end

local function filterTable(players, teamNumber)
    local new = {}

    for _, player in ipairs(players) do
        if player:GetTeamNumber() == teamNumber then
            table.insert(new, player)
        end
    end
    return new
end

function SpectatingTeam:UpdateTechTree(teamNumber)
    PROFILE("SpectatingTeam:UpdateTechTree")

    -- Compute tech tree availability only so often because it's very slooow
    if self.techTree[teamNumber] and (self.timeOfLastTechTreeUpdate[teamNumber] == nil or Shared.GetTime() > self.timeOfLastTechTreeUpdate[teamNumber] + SpectatingTeam.kTechTreeUpdateTime) then
        self.techTree[teamNumber]:Update(self.entityTechIds[teamNumber]:GetList(), self.techIdCount[teamNumber])

        -- Send tech tree base line to players that just switched teams or joined the game
        local players = self:GetPlayers()
        players = filterTable(players, teamNumber)

        Print("SpectatingTeam:UpdateTechTree " .. teamNumber  .. " count: ".. #players)

        for _, player in ipairs(players) do

            if player:GetSendTechTreeBase() then

                self.techTree[teamNumber]:SendTechTreeBase(player)

                player:ClearSendTechTreeBase()

            end

        end

        -- Send research, availability, etc. tech node updates to team players
        self.techTree[teamNumber]:SendTechTreeUpdates(players)

        self.timeOfLastTechTreeUpdate[teamNumber] = Shared.GetTime()

        self:OnTechTreeUpdated()

    end

end

function SpectatingTeam:OnTechTreeUpdated()
end