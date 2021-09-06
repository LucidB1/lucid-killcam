
local startTick = 0;
local mainCam = -1;
local cam2 = -1;

local camTick = 0;
local extraStage = false
local storeInvincible = false
local soundId = nil;
local soundId2 = nil;
local targetPed = nil;
local stage = -1;
local stageNum = 2;
local killerCamTick = -1;
local pedCamTick = -1;
local rayTick = -1;
local switchTick = -1;
Citizen.CreateThread(function()
    SetTimeScale(1.0)
    startTick = GetGameTimer()
    soundId = GetSoundId()
    soundId2 = GetSoundId()
end)

function SetupCamera(cam, x, y, z, fov, entity)
    SetCamAffectsAiming(cam, false);
    SetCamCoord(cam, x, y, z);
    SetCamFov(cam, fov + (fov == Config.CameraFov and -15.0 or 15.0))
    SetCamNearClip(cam, 0.0);
    local num = PlayerPedId() == entity and 0.35 or 0.0;
    PointCamAtPedBone(cam, entity, 310860, 0.0, num, 0.0, true);
    SetCamActive(cam, true)

end






function Camera(active, ease, easedur, entity,x,y,z, addTick, doZoom )
    if(x == nil)then
        x = 0.0
    end
    if(y == nil) then
        y = 0.0;
    end
    if(z == nil) then
        z = 0.0
    end
    if(addTick == nil) then
        addTick = 2500;
    end
    if(doZoom == nil) then
        doZoom = false;
    end

    if(active) then
        local num = MovingTowards(entity, vector3(x, y, z)) and Config.CameraFov - 15.0 or Config.CameraFov;
        local flag = Config.LodTarget
        if(flag) then
            SetFocusEntity(entity)
        end
        local num2 = GetGameTimer();
        switchTick = num2 + 0.5

        camTick = addTick * 0.1;

        local flag2 = mainCam == -1;
        if(flag2) then
            extraStage = false;
            storeInvincible = GetPlayerInvincible(PlayerId());
            local flag4 = Config.SoundEnable;

            if(flag4) then
                PlaySoundFrontend(soundId, "MP_WAVE_COMPLETE", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
                PlaySoundFrontend(soundId2, "Crate_Land", "FBI_05_SOUNDS", false)

            end
            SetTimeScale(Config.TimeScale / 1000)
            local flag6 = Config.EffectEnable
            if(flag6) then
                AnimpostfxPlay("WeaponUpgrade", 750, false)
                ClearTimecycleModifier()
                SetTransitionTimecycleModifier(Config.Effect, 2.0 * Config.TimeScale)
            end
            local flag7 = not InVehicle(PlayerPedId()) and not IsPedInCover(PlayerPedId(), false);
            if(flag7) then
                SetPlayerForcedAim(PlayerId(), true)
                SetPlayerForcedZoom(PlayerId(), true)
            end
            mainCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", false)
            cam2 = CreateCam("DEFAULT_SCRIPTED_CAMERA", false)
            SetCamAffectsAiming(mainCam, false)
            SetCamAffectsAiming(cam2, false)
        end

        SetupCamera(mainCam, x, y, z, num, entity)
        SetupCamera(cam2, x, y, z, num + (num == Config.CameraFov and -15.0 or 15.0), entity)
        SetCamActive(mainCam, true);
        RenderScriptCams(true, ease, easedur, true, true);
        if(doZoom) then
            SetCamActiveWithInterp(cam2, mainCam, addTick, true, true)
        end
    else
        SetCamActive(mainCam, false);
        RenderScriptCams(false, ease, easedur, true, true);
        DestroyCam(mainCam)
        DestroyCam(cam2)
        SetTimeScale(1.0)
        SetPlayerForcedAim(PlayerId(), false)
        local flag8 = Config.LodTarget;
        if(flag8) then
            SetFocusEntity(PlayerPedId());
        end
        local flag9 = Config.SoundEnable;
        if(flag9) then
            PlaySoundFrontend(soundId, "Short_Transition_Out", "PLAYER_SWITCH_CUSTOM_SOUNDSET", false);
            
        end
        local flag10 = Config.EffectEnable;

        if(flag10) then
            SetTransitionTimecycleModifier("nextgen", 2.0);
        end
        camTick = 0;
        mainCam = -1;
        targetPed = nil;
    end
end




function EnemyNearby(ped, pos, range)
  local flag = Config.NoEnemiesNearby
  return flag and  Citizen.InvokeNative(0x336B3D200AB007CB,ped, pos.x, pos.y, pos.z, range )
end


function Chance(chance)
	return math.random() <= chance;
end

function RandNum()
	return math.random()
end


function GetEntInFrontOfPlayer(vector, vector2)
    local Ent = nil

    local RayHandle = CastRayPointToPoint(vector.x, vector.y, vector.z, vector2.x, vector2.y, vector2.z, 10, PlayerPedId(), 0)
    local A,B,C,D,Ent = GetRaycastResult(RayHandle)
    return Ent
end


function InVehicle(ped)
	return IsPedInAnyVehicle(ped, false)
end

function Damaged(ped)
	local flag3 =  (GetPedSourceOfDeath(ped) == PlayerPedId()) or HasEntityBeenDamagedByEntity(ped, PlayerPedId())
	return flag3
end

function VehicleKill(ped)
	return InVehicle(PlayerPedId()) and #(GetEntityCoords(ped) - GetEntityCoords(PlayerPedId())) < 3.0
end



local pedindex = {}

function PopulatePedIndex()
    local handle, ped = FindFirstPed()
    local finished = false -- FindNextPed will turn the first variable to false when it fails to find another ped in the index
    local plyCoords = GetEntityCoords(PlayerPedId());
    repeat
        local coords = GetEntityCoords(ped)
        local dist = #(plyCoords - coords)

        if(dist < 60) then
            if(pedindex[ped] == nil) then
                pedindex[ped] = ped;
            end
        else
            if(pedindex[ped] ~= nil) then
                pedindex[ped] = nil;
            end

        end
    

        finished, ped = FindNextPed(handle) -- first param returns true while entities are found
    until not finished
    EndFindPed(handle)
end

function GetNewCamPos(ped, zOffset, isKiller, ignoreDist, range, minDistance)

    if(zOffset == nil)then
        zOffset = 0
    end

    if(isKiller == nil) then
        isKiller = false
    end

    if(ignoreDist == nil) then
        ignoreDist = false
    end

    if(range == nil) then
        range = 2.5
    end

    if(minDistance == nil) then
        minDistance = 1.5
    end
    
    local flag = VehicleKill(ped)

    if(flag) then
        range = 5.0;
        minDistance = 3.0;
        zOffset = 1;
    end

    local num = 0;
    local vector = isKiller and GetPedBoneCoords(ped, GetPedBoneIndex(ped, 28252)) or GetPedBoneCoords(ped, GetPedBoneIndex(ped, 31086)) 
    local vector2 = vector;
    local vector4 = GetCamCoord(cam)
    local num2 = isKiller and 0.3 or 1.0;
    while (num < 3 and ( #(vector2 - vector ) < minDistance or (mainCam ~= -1 and not ignoreDist and #(vector2 - vector4) < 1.75 or GetEntInFrontOfPlayer(vector, vector2) and GetEntInFrontOfPlayer(GetEntityCoords(ped), vector2))  )) do
        Citizen.Wait(0);
        num = num + 1;
        vector2 = vector3(vector.x + -range + RandNum() * (range * 2.0), vector.y + -range + RandNum() * (range * 2.0), vector.z + -(range * num2) / 2.0 + zOffset + RandNum() * (range * num2 / 2.0) );
    end

    return vector2;
end


function Forward(heading, pitch, distance)
    if(distance == nil) then
        distance = 1.0
    end
    
    return vector3((math.cos(heading - 270.0)  * 0.017453292519943295) * distance, (math.cos(heading * 0.017453292519943295)  * 0.017453292519943295) * distance, (math.cos(pitch + 270.0) * 0.017453292519943295) * distance)
end


function MovingTowards(ent, pos)
    local position = GetEntityCoords(ent);
    local velocity = GetEntityVelocity(ent);
    return #((position+velocity) - pos) > #(position - pos);
end


Citizen.CreateThread(function()

    PopulatePedIndex()
    for _, ped in pairs(pedindex) do
        if(ped) then
            if(IsEntityDead(ped) and not IsPedAPlayer(ped)) then
                DeleteEntity(ped)
            end
        end
    end
end)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2000)
        PopulatePedIndex()
    end

end)
local change = nil;
local displayed_for_ped = {}
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local num = GetGameTimer();
        for _, ped in pairs(pedindex) do
            if(ped) then
                if(DoesEntityExist(ped)) then
                    local position = GetEntityCoords(ped)
                    local isDead =  IsPedFatallyInjured(ped)
                    local flag7  = camTick ~= 0 or stage ~= -1;
                    local flag9 = isDead and Damaged(ped)
                    if(flag9) then
                   
                        local position2 = GetEntityCoords(PlayerPedId());
                        local position3 =  GetEntityCoords(ped);
                        local flag10 = not InVehicle(ped) and ( (not EnemyNearby(PlayerPedId(), position2, Config.NearbyRange and not EnemyNearby(PlayerPedId(), position3, Config.NearbyRange ) ) or not Config.NoEnemiesNearby))
                        local flag11 = not flag10;
                        if(not flag11 and not displayed_for_ped[ped]) then

                            
                          
                            local flag12 =  pedCamTick <= num;
                            if(flag12) then
                                displayed_for_ped[ped] = true
                                local rnd = math.random(1, 100)
                                print('rnd : ', rnd)
                                local switchCam = rnd  >= Config.ChanceCamSwitch;
                                if(switchCam) then
                                    stage = 0;
                                    targetPed = ped;
                                    local num3 = 0.1;
                                    pedCamTick = num + Config.CamPedCooldown;
                                    local boneCoord = GetPedBoneCoords(targetPed, GetPedBoneIndex(targetPed, 31086))
                                    local flag13 = GetEntInFrontOfPlayer(boneCoord, boneCoord - vector3(0.0, 0.0, 0.5));
                                    if(flag13)then
                                        num3 = num3 + 1;
                                    end
                                    newCamPos = GetNewCamPos(targetPed, num3, false, false, 2.5, 1.5);
                                    Camera(true, false, 0, targetPed,newCamPos.x,newCamPos.y,newCamPos.z, 2500, false) 
                                end
                            end
                        end
                    end
                end
            end
        end
        if(stage >= 0) then
            local flag16 = camTick <= num
            print('flag 16 : ', flag16)
            if(flag16)then
                stage = stage + 1;
                local flag17 = stage >= 3
                if(flag17)then
                    local flag18 = mainCam ~= -1;
                    if(flag18)then
                        Camera(false, false, 0, nil, 0.0, 0.0, 0.0, 2500, false);
                    end
                    stage = -1;
                else
                    Citizen.Wait(275)
                    local flag19 = GetEntitySpeed(targetPed) > 0.4;
                    local flag20 = (not InVehicle(PlayerPedId()) and  killerCamTick <= num);
                    local flag21 = not InVehicle(PlayerPedId()) and flag19 or (flag20 and stage == stageNum - 1);
                    if(flag21)then
                        local addTick = Config.CamPedDuration;
                        local flag22 = flag20;

                        if(flag22)then

                            killerCamTick = num + 0.1
                            addTick = Config.CamKillerDuration 
                        end
                        local flag23 = (flag20 or  pedCamTick <= num and targetPed ~= nil)
                        if(flag23) then
                            newCamPos2 = GetNewCamPos(targetPed, 0.7, flag20, flag20, 2.5, 1.5);
                            Camera(true, false, 0, targetPed, newCamPos2.x, newCamPos2.y, newCamPos2.z, addTick, true);
                        end
                    else
                        stage = stage + 1
                    end
                end
            end

            local flag27 = mainCam ~= -1;

            if(flag27) then
                DisableAllControlActions(0)
                DisableAllControlActions(1)
                DisableAllControlActions(2)
                DisableAllControlActions(3)
                HideHudAndRadarThisFrame()
            end
        end
    end
end)