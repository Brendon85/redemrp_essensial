local huk = false
RegisterCommand("huk", function(s, a)
    local ped = PlayerPedId()
    if huk == false then
        huk = true
        loadAnimDict("mech_busted@unapproved")
        TaskPlayAnim(PlayerPedId(), "mech_busted@unapproved", "idle_2_hands_up", 3.0, -1, -1, 0, 0, false, false, false)
        Wait(100)
        while IsEntityPlayingAnim(ped, "mech_busted@unapproved", "idle_2_hands_up", 3) do
            Wait(0)
        end
        StopAnimTask(ped, "mech_busted@unapproved", "idle_2_hands_up", 1.0)
        TaskPlayAnim(ped, "mech_busted@unapproved", "idle_b", 3.0, -1, -1, 1, 0, false, false, false)
    else
        huk = false
        loadAnimDict("mech_busted@unapproved")
        StopAnimTask(ped, "mech_busted@unapproved", "idle_b", 1.0)
        Wait(100)
        TaskPlayAnim(ped, "mech_busted@unapproved", "hands_up_2_idle", 3.0, 3.0, -1, 0, 0, false, false, false)
    end
end)

local hu = false
RegisterCommand("hu", function(s, a)
    local ped = PlayerPedId()
    if hu == false then
        hu = true
        loadAnimDict("mech_busted@arrest")
        TaskPlayAnim(ped, "mech_busted@arrest", "hands_up_transition", 3.0, -1, -1, 0, 0, false, false, false)
        Wait(100)
        while IsEntityPlayingAnim(ped, "mech_busted@arrest", "hands_up_transition", 3) do
            Wait(0)
        end
        StopAnimTask(ped, "mech_busted@arrest", "hands_up_transition", 1.0)
        TaskPlayAnim(ped, "mech_busted@arrest", "hands_up_loop", 3.0, -1, -1, 1, 0, false, false, false)
    else
        hu = false
        StopAnimTask(ped, "mech_busted@arrest", "hands_up_transition", 1.0)
        StopAnimTask(ped, "mech_busted@arrest", "hands_up_loop", 1.0)
        Wait(150)
        ClearPedTasks(PlayerPedId())
    end
end)

--[[CreateThread(function()
    while true do
        Wait(0)
        if IsControlJustPressed(0, 0x43CDA5B0) then --z
            loadAnimDict("mech_busted@unapproved")
            TaskPlayAnim(PlayerPedId(), "mech_busted@unapproved", "reach_weapon", 3.0, -1, -1, 0, 0, false, false, false)
        elseif IsControlJustReleased(0, 0x43CDA5B0) then --z
            StopAnimTask(PlayerPedId(), "mech_busted@unapproved", "reach_weapon", 1.0)
        end
    end
end)--]]

function loadAnimDict(dict)
	RequestAnimDict(dict)
	while not HasAnimDictLoaded(dict) do
		Citizen.Wait(1)
	end
end

SetMinimapType(3)

--[[RegisterCommand("dv", function()--Delete Vehicle
    local playerPed = PlayerPedId()
    local vehicle   = GetVehiclePedIsIn(playerPed, false)

    if IsPedInAnyVehicle(playerPed, true) then
        vehicle = GetVehiclePedIsIn(playerPed, false)
    end

    if DoesEntityExist(vehicle) then
        DeleteVehicle(vehicle)
    end
	TriggerServerEvent("ak_logs:DiscordChat", GetPlayerServerId(PlayerId()), GetPlayerName(PlayerId()), "**[DEL CAR]** ")
end)--]]

-- The distance to check in front of the player for a vehicle   
local distanceToCheck = 5.0

-- The number of times to retry deleting a vehicle if it fails the first time 
local numRetries = 5

RegisterCommand("dv", function(source, args, rawCommand)
	PoistaAjoneuvo()
end)

function PoistaAjoneuvo()
    local ped = PlayerPedId()

    if ( DoesEntityExist( ped ) and not IsEntityDead( ped ) ) then 
        local pos = GetEntityCoords( ped )

        if ( IsPedSittingInAnyVehicle( ped ) ) then 
            local vehicle = GetVehiclePedIsIn( ped, false )

            if ( GetPedInVehicleSeat( vehicle, -1 ) == ped ) then 
                DeleteGivenVehicle( vehicle, numRetries )
            else 
                print( "You must be in the driver's seat!" )
            end 
		
		elseif IsPedOnMount(ped) then
			local mount = GetMount(ped)
			NetworkRequestControlOfEntity(mount)
            while not NetworkHasControlOfEntity(mount) do Citizen.Wait(0);    end
            SetEntityAsMissionEntity(mount, true, true)
            while not IsEntityAMissionEntity(mount) do Citizen.Wait(0);    end
            DeletePed(mount)
        else
            local vehicle = GetVehicleInDirection()

            if ( DoesEntityExist( vehicle ) ) then 
                DeleteGivenVehicle( vehicle, numRetries )
            else 
                print( "You must be in or near a vehicle to delete it." )
            end 
        end 
    end 
end

function DeleteGivenVehicle( veh, timeoutMax )
    local timeout = 0 

    SetEntityAsMissionEntity( veh, true, true )
    DeleteVehicle( veh )

    if ( DoesEntityExist( veh ) ) then
        print( "Failed to delete vehicle, trying again..." )

        -- Fallback if the vehicle doesn't get deleted
        while ( DoesEntityExist( veh ) and timeout < timeoutMax ) do 
            DeleteVehicle( veh )

            -- The vehicle has been banished from the face of the Earth!
            if ( not DoesEntityExist( veh ) ) then 
                print( "Vehicle deleted." )
            end 

            -- Increase the timeout counter and make the system wait
            timeout = timeout + 1 
            Citizen.Wait( 500 )

            -- We've timed out and the vehicle still hasn't been deleted. 
            if ( DoesEntityExist( veh ) and ( timeout == timeoutMax - 1 ) ) then
                print( "Failed to delete vehicle after " .. timeoutMax .. " retries." )
            end 
        end 
    else 
        print( "Vehicle deleted." )
    end 
end 

function GetVehicleInDirection()
    local Cam = GetGameplayCamCoord()
    local handle = Citizen.InvokeNative(0x377906D8A31E5586, Cam, GetCoordsFromCam(10.0, Cam), -1, PlayerPedId(), 4)
    local _, Hit, Coords, _, Entity = GetShapeTestResult(handle)
    return Entity
end

GetCoordsFromCam = function(distance, coords)
    local rotation = GetGameplayCamRot()
    local adjustedRotation = vector3((math.pi / 180) * rotation.x, (math.pi / 180) * rotation.y, (math.pi / 180) * rotation.z)
    local direction = vector3(-math.sin(adjustedRotation[3]) * math.abs(math.cos(adjustedRotation[1])), math.cos(adjustedRotation[3]) * math.abs(math.cos(adjustedRotation[1])), math.sin(adjustedRotation[1]))
    return vector3(coords[1] + direction[1] * distance, coords[2] + direction[2] * distance, coords[3] + direction[3] * distance)
end

RegisterCommand("dh", function()--Delete horse
    local playerPed = PlayerPedId()
    local mount   = GetMount(PlayerPedId())

    if IsPedOnMount(playerPed) then
        DeleteEntity(mount)
    end

end)

Citizen.CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local vehicle   = GetVehiclePedIsIn(playerPed, false)

        if vehicle == 0 then
            Citizen.Wait(3000)
        else
            if IsPedInAnyVehicle(playerPed, true) then
                vehicle = GetVehiclePedIsIn(playerPed, false)
            end
            SetVehicleDoorsShut(vehicle, true)
            Citizen.Wait(50)
        end
    end
end)

Citizen.CreateThread(function()
    local active = false
    local timer = 0
    while true do 
        Wait(0)
        if IsControlJustPressed(0,0xCEFD9220) then -- E KEY
            timer = 0
            active = true
            while  timer < 200 do 
                Wait(0)
                timer = timer + 1
                SetRelationshipBetweenGroups(1, `PLAYER`, `PLAYER`)
            end
            
            active = false
        end

        if IsControlJustPressed(0,0xB2F377E8) then -- F KEY
			Citizen.Wait(500)
			SetRelationshipBetweenGroups(1, `PLAYER`, `PLAYER`)
			active = false
			timer = 0
        end
            
        if active == false and not IsPedOnMount(PlayerPedId()) and not IsPedInAnyVehicle(PlayerPedId()) then
            SetRelationshipBetweenGroups(5, `PLAYER`, `PLAYER`)
        end	
    end
end)

function DrawCoords()
    if 1 == 1 then
        local _source = source
        --local ent = GetPlayerPed(_source)
        local ent = PlayerPedId(_source)
        local pp = GetEntityCoords(ent)
        local hd = GetEntityHeading(ent)
        DrawTxt("x = " .. tonumber(string.format("%.2f", pp.x)) .. " y = " .. tonumber(string.format("%.2f", pp.y)) .. " z = " .. tonumber(string.format("%.2f", pp.z)) .. " | H: " .. tonumber(string.format("%.2f", hd)), 0.01, 0.0, 0.4, 0.4, true, 255, 255, 255, 150, false)
    end
end

function DrawTxt(str, x, y, w, h, enableShadow, col1, col2, col3, a, centre)
    local str = CreateVarString(10, "LITERAL_STRING", str)
    
    SetTextScale(w, h)
    SetTextColor(math.floor(col1), math.floor(col2), math.floor(col3), math.floor(a))
    SetTextCentre(centre)
    if enableShadow then SetTextDropshadow(1, 0, 0, 0, 255) end
    DisplayText(str, x, y)
end


local mostrar = false
RegisterCommand("coords",function()
    mostrar = not mostrar
    while mostrar do
          Citizen.Wait(0)
          DrawCoords()
    end
end)

--disable notif

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(10)
        local size = GetNumberOfEvents(0)   
        if size > 0 then
            for i = 0, size - 1 do
                local eventAtIndex = GetEventAtIndex(0, i)
                if eventAtIndex == GetHashKey("EVENT_CHALLENGE_GOAL_COMPLETE") or eventAtIndex == GetHashKey("EVENT_CHALLENGE_REWARD") or eventAtIndex == GetHashKey("EVENT_DAILY_CHALLENGE_STREAK_COMPLETED") then 
                    Citizen.InvokeNative(0x6035E8FBCA32AC5E)
                end
            end
        end
    end
end)

---new
Citizen.CreateThread(function()

    while true do
        local isTargetting, targetEntity = GetPlayerTargetEntity(PlayerId())
        if isTargetting and IsPedAPlayer(targetEntity) then
            if lastCow ~= targetEntity then

                local promptGroup = PromptGetGroupIdForTargetEntity(targetEntity)
				local horse = targetEntity -- GetMount(PlayerPedId())
				local group = Citizen.InvokeNative(0xB796970BD125FCE8, horse, Citizen.ResultAsLong()) -- PromptGetGroupIdForTargetEntity
				PromptSetGroup(prompt, group, 0)
				SetPedPromptName(horse, "Ped")

            end
        end

        Citizen.Wait(0)
    end
end)

--- dancas


--pron

local proned = false
--proneKey = 0x8AAA0AD4
--proneKey = 0x7ABC6A66
proneKey = 0x42385422

Citizen.CreateThread( function()
	while true do 
		Citizen.Wait( 1 )
		local ped = PlayerPedId()
		if ( DoesEntityExist( ped ) and not IsPedDeadOrDying( ped ) ) then 
			ProneMovement()
			DisableControlAction( 0, proneKey, true ) 
			if ( not IsPauseMenuActive() ) then 
				if ( IsDisabledControlJustPressed(0, proneKey) and not IsPedInAnyVehicle(ped, true) and not IsPedFalling(ped) and not IsPedDiving(ped) and not IsPedInCover(ped, false) and not IsEntityInWater(ped) ) then
					if proned then
						ClearPedTasks(ped)
						local me = GetEntityCoords(ped)
						SetEntityCoords(ped, me.x, me.y, me.z-0.5)
						proned = false
					elseif not proned then
						RequestAnimDict("mech_crawl@base")
						while not HasAnimDictLoaded("mech_crawl@base") do
							Citizen.Wait(100)
						end
						ClearPedTasksImmediately(ped)
						proned = true
						SetProned()
					end
				end
			end
		else
			proned = false
		end
	end
end)

function SetProned()
	ped = PlayerPedId()
	ClearPedTasksImmediately(ped)
	TaskPlayAnimAdvanced(PlayerPedId(), "mech_crawl@base", "onfront_fwd", GetEntityCoords(PlayerPedId()), 0.0, 0.0, GetEntityHeading(PlayerPedId()), 1.0, 1.0, 1.0, 2, 1.0, 0, 0)
end


function ProneMovement()
	if proned then
		ped = PlayerPedId()
		DisableControlAction(0, 0xB2F377E8)
		DisableControlAction(0, 0x8FFC75D6)
		DisableControlAction(0, 0xF3830D8E)
		if IsEntityInWater(ped) then
			ClearPedTasks(ped)
			proned = false
		end
		if IsControlPressed(0, 0x8FD015D8) or IsControlPressed(0, 0xD27782E3) then
			DisablePlayerFiring(ped, true)
		 elseif IsControlJustReleased(0, 0x8FD015D8) or IsControlJustReleased(0, 0xD27782E3) then
		 	DisablePlayerFiring(ped, false)
		 end
		if IsControlJustPressed(0, 0x8FD015D8) and not movefwd then
			movefwd = true
			TaskPlayAnimAdvanced(PlayerPedId(), "mech_crawl@base", "onfront_fwd", GetEntityCoords(PlayerPedId()), 0.0, 0.0, GetEntityHeading(PlayerPedId()), 1.0, 1.0, 1.0, 1, 1.0, 0, 0)
		elseif IsControlJustReleased(0, 0x8FD015D8) and movefwd then
			TaskPlayAnimAdvanced(PlayerPedId(), "mech_crawl@base", "onfront_fwd", GetEntityCoords(PlayerPedId()), 0.0, 0.0, GetEntityHeading(PlayerPedId()), 1.0, 1.0, 1.0, 2, 1.0, 0, 0)
			movefwd = false
		end		
		if IsControlJustPressed(0, 0xD27782E3) and not movebwd then
			movebwd = true
			TaskPlayAnimAdvanced(PlayerPedId(), "mech_crawl@base", "onfront_bwd", GetEntityCoords(PlayerPedId()), 0.0, 0.0, GetEntityHeading(PlayerPedId()), 1.0, 1.0, 1.0, 1, 1.0, 0, 0)
		elseif IsControlJustReleased(0, 0xD27782E3) and movebwd then 
			TaskPlayAnimAdvanced(PlayerPedId(), "mech_crawl@base", "onfront_bwd", GetEntityCoords(PlayerPedId()), 0.0, 0.0, GetEntityHeading(PlayerPedId()), 1.0, 1.0, 1.0, 2, 1.0, 0, 0)
		    movebwd = false
		end
		if IsControlPressed(0, 0x7065027D) then
			SetEntityHeading(ped, GetEntityHeading(ped)+2.0 )
		elseif IsControlPressed(0, 0xB4E465B4) then
			SetEntityHeading(ped, GetEntityHeading(ped)-2.0 )
		end
	end
end

--handsup
Citizen.CreateThread( function()
while true do
	Citizen.Wait(0)
		if IsControlJustPressed(0, 0x8CC9CD42) then -- x
			local playerPed = PlayerPedId()
			if not IsEntityDead(playerPed) and not Citizen.InvokeNative(0x9682F850056C9ADE, playerPed) then
				local animDict = "script_proc@robberies@homestead@lonnies_shack@deception"

				if not IsEntityPlayingAnim(playerPed, animDict, "hands_up_loop", 3) then
					if not HasAnimDictLoaded(animDict) then
						RequestAnimDict(animDict)

						while not HasAnimDictLoaded(animDict) do
							Citizen.Wait(0)
						end
					end

					TaskPlayAnim(playerPed, animDict, "hands_up_loop", 2.0, -2.0, -1, 67109393, 0.0, false, 1245184, false, "UpperbodyFixup_filter", false)
					RequestAnimDict(animDict)
				else
					ClearPedSecondaryTask(playerPed)
				end
			end
		end
	end
end)

--Point by clicking L
Citizen.CreateThread(function() --POINTING SCRIPT
    while true do
        Wait(0)
        if (IsControlJustPressed(0,0x80F28E95))  then --l
            local ped = PlayerPedId()
            if ( DoesEntityExist( ped ) and not IsEntityDead( ped ) ) then
 
                RequestAnimDict( "ai_react@point@base" )
 
                while ( not HasAnimDictLoaded( "ai_react@point@base" ) ) do
                    Wait( 100 )
                end
 
                if IsEntityPlayingAnim(ped, "ai_react@point@base", "point_fwd", 3) then
                    ClearPedSecondaryTask(ped)
                else
                    TaskPlayAnim(ped, "ai_react@point@base", "point_fwd", 8.0, -8.0, 120000, 31, 0, true, 0, false, 0, false)
                end
            end
        end
    end
end)

---disable v

Citizen.CreateThread(function()
    while true do
        Wait(0)
        DisableControlAction(0, 0x7F8D09B8, true)
        DisableControlAction(0, 0xE72B43F4, true)--INPUT_NEXT_CAMERA
    end
end)
