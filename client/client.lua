ESX = nil
shopid = nil
robstarted = false
robx = nil
roby = nil
robz = nil

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(100)
    end

    while ESX.GetPlayerData().job == nil do
        Citizen.Wait(100)
    end

    PlayerData = ESX.GetPlayerData()

    spawnSafes()
end)

function spawnSafes()
	for i=1, #safes, 1 do
		local coords = {
			x = safes[i].x,
			y = safes[i].y,
			z = safes[i].z - 1,
		}
		local safe = CreateObject(1089807209, coords.x, coords.y, coords.z, 0, 0, 0)
		SetEntityHeading(safe, safes[i].heading)
		FreezeEntityPosition(safe, true)
	end
end

Citizen.CreateThread(function()
	while true do
		local wait = 750
		for i=1, #safes, 1 do
			local ped = PlayerPedId()
			local pedCoords = GetEntityCoords(ped)
			pedDistance = GetDistanceBetweenCoords(pedCoords, safes[i].x, safes[i].y, safes[i].z - 1, false)
			if pedDistance <= 3.0 then
				DrawText3D(safes[i].x, safes[i].y, safes[i].z, '[E] Kasayı Aç')
				if IsControlJustReleased(0, 38) then
					openSafe(safes[i].number, safes[i].x, safes[i].y, safes[i].z - 1)
				end
				wait = 5
			end
		end
		Citizen.Wait(wait)
    end
end)

Citizen.CreateThread(function()
	while true do
		local sleepThread = 3000
		if robstarted then
			sleepThread = 10
			local ped = PlayerPedId()
			local pedCoords = GetEntityCoords(ped)
			distance = GetDistanceBetweenCoords(pedCoords, robx, roby, robz, false)
			if distance >= 15 then
				EndMinigame(false)
			end
		else
			sleepThread = 3000
		end
		Citizen.Wait(sleepThread)
	end
end)

DrawText3D = function(x, y, z, text)
    local onScreen,x,y = World3dToScreen2d(x, y, z)
    local factor = #text / 370

    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(x,y)
        DrawRect(x,y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 120)
    end
end

function openSafe(id, x, y, z)
	local ped = PlayerPedId()
	ESX.TriggerServerCallback('yatzzz_shoprobbery:getCops', function(cops)
		if cops >= Config.NeededCops then
			if IsPedArmed(ped, 4) then
				ESX.TriggerServerCallback('yatzzz_shoprobbery:time', function(time)
					if time then
						TriggerEvent("mythic_progbar:client:progress", {

							name = "startrob",
							duration = Config.StartSearchTime,
							label = 'Kasa kilidi kurcalanıyor...',
							useWhileDead = false,
							canCancel = false,
							controlDisables = {
								disableMovement = true,
								disableCarMovement = true,
								disableMouse = false,
								disableCombat = true,
							},
						},function(cancelled)
							if not cancelled then
								robstarted = true
								robx = x
								roby = y
								robz = z
								TriggerEvent("yatzzz_outlawalert:shopRobbery")
								SafeRewards = math.random(Config.SafeRewardMin, Config.SafeRewardMax)
								StartMinigame(SafeRewards)
								shopid = id
							end
						end)
					end
				end, id)
			else
				TriggerEvent('mythic_notify:client:SendAlert', { type = 'error', text = 'Kasayı soyabilmek için elinde silah tutmalısın!'})
			end
		else
			TriggerEvent('mythic_notify:client:SendAlert', { type = 'error', text = 'Şehirde yeterli polis yok!'})
		end
	end)
end

function lockFinished(rewards)
	TriggerServerEvent('yatzzz_shoprobbery:giveMoney', rewards)
	TriggerServerEvent("yatzzz_shoprobbery:setRobbableFALSE")
end


function StartMinigame(rewards)

	local txd = CreateRuntimeTxd("JSCTextureDict")
	for i = 1, 2 do 
		CreateRuntimeTextureFromImage(txd, tostring(i), "LockPart" .. i .. ".PNG") 
	end

	MinigameOpen = true
	SoundID 	  = GetSoundId() 
	Timer 		  = GetGameTimer()

	if not RequestAmbientAudioBank("SAFE_CRACK", false) then 
		RequestAmbientAudioBank("SAFE_CRACK", false)
	end
	if not HasStreamedTextureDictLoaded("JSCTextureDict", false) then 
		RequestStreamedTextureDict("JSCTextureDict", false)
	end

	Citizen.CreateThread(function() 
		Update(rewards) 
	end)	
end

function Update(rewards)
	Citizen.CreateThread(function() 
		HandleMinigame(rewards) 
	end)
	while MinigameOpen do
		InputCheck()  
		if IsEntityDead(PlayerPedId(PlayerId())) then 
			EndMinigame(false, false) 
		end
		Citizen.Wait(0)
	end
end

function InputCheck()

	local leftKeyPressed 	= IsControlPressed(0, 174) or 0 
	local rightKeyPressed 	= IsControlPressed(0, 175) or 0 
	if IsControlPressed(0, 113) then
		EndMinigame(false) 
	end
	if IsControlPressed(0, 48) then 
		rotSpeed = 0.1 
		modifier = 33
	elseif IsControlPressed(0, 21) then 
		rotSpeed = 1.0
		modifier = 50 
	else
		rotSpeed = 0.4 
		modifier = 90 
	end

    local lockRotation = math.max(modifier / rotSpeed, 0.1)

    if leftKeyPressed ~= 0 or rightKeyPressed ~= 0 then
    	LockRotation = LockRotation - (rotSpeed * tonumber(leftKeyPressed))
    	LockRotation = LockRotation + (rotSpeed * tonumber(rightKeyPressed))
    	if (GetGameTimer() - Timer) > lockRotation then 
    		PlaySoundFrontend(0, "tumbler_turn", "SAFE_CRACK_SOUNDSET", false)
    		Timer = GetGameTimer() 
    	end
    end
end

function HandleMinigame(rewards)

	local lockRot 		 = math.random(385.00, 705.00)	

	local lockNumbers 	 = {}
	local correctGuesses = {}

	lockNumbers[1] = 1
	lockNumbers[2] = math.random(					 45.0, 					359.0)
	lockNumbers[3] = math.random(lockNumbers[2] -	719.0, lockNumbers[2] - 405.0)
	lockNumbers[4] = math.random(lockNumbers[3] +  	 45.0, lockNumbers[3] + 359.0)
	for i = 1,4 do
		print(math.floor((lockNumbers[i] % 360) / 3.60))
	end

	TriggerEvent('mythic_notify:client:SendAlert', { type = 'inform', text = 'Not defterinde kasanın şifrelerini buldun. (Bir tur sola) ' .. (math.floor((lockNumbers[1] % 360) / 3.60)) .. '. (Sağa) ' .. (math.floor((lockNumbers[2] % 360) / 3.60)) .. '. (Bir tur sola) ' .. (math.floor((lockNumbers[3] % 360) / 3.60)) .. '. (Sağa) ' .. (math.floor((lockNumbers[4] % 360) / 3.60)) .. '.', length = 85000})
	Citizen.Wait(10)
	TriggerEvent('mythic_notify:client:SendAlert', { type = 'inform', text = 'LeftShift tuşu ile hızlandırabilir, Z tuşu ile yavaşlatabilirsiniz. "G" tuşu ile kapatabilirsiniz.', length = 84990})
    local correctCount	= 1
    local hasRandomized	= false

    LockRotation = 0.0 + lockRot
								
	while MinigameOpen do	
		DrawSprite("JSCTextureDict", "1",  0.8,  0.5,  0.15,  0.26, -LockRotation, 255, 255, 255, 255)
		DrawSprite("JSCTextureDict", "2",  0.8,  0.5, 0.176, 0.306, -0.0, 255, 255, 255, 255)	

		hasRandomized = true

		local lockVal = math.floor(LockRotation)

		if correctCount > 1 and 	correctCount < 5 and lockVal + (Config.LockTolerance * 3.60) < lockNumbers[correctCount - 1] and lockNumbers[correctCount - 1] < lockNumbers[correctCount] then 
			EndMinigame(false)
			MinigameOpen = false
		elseif correctCount > 1 and 	correctCount < 5 and lockVal - (Config.LockTolerance * 3.60) > lockNumbers[correctCount - 1] and lockNumbers[correctCount - 1] > lockNumbers[correctCount] then 
			EndMinigame(false)
			MinigameOpen = false
		elseif correctCount > 4 then
			EndMinigame(true, rewards)
		end

		for k,v in pairs(lockNumbers) do
			  if not hasRandomized then 
				LockRotation = lockRot
			end
			if lockVal == v and correctCount == k then
				local canAdd = true
				for key,val in pairs(correctGuesses) do
					if val == lockVal and key == correctCount then
						canAdd = false
					end
				end

				if canAdd then 				
					PlaySoundFrontend(-1, "tumbler_pin_fall", "SAFE_CRACK_SOUNDSET", true)
					correctGuesses[correctCount] = lockVal
					correctCount = correctCount + 1; 
				end   				  			
			end
		end
		Citizen.Wait(0)
	end
end


function EndMinigame(won, rewards)
	MinigameOpen = false
	if won then
		PlaySoundFrontend(SoundID, "tumbler_pin_fall_final", "SAFE_CRACK_SOUNDSET", true)

		Citizen.Wait(100)

		PlaySoundFrontend(SoundID, "safe_door_open", "SAFE_CRACK_SOUNDSET", true)
		lockFinished(rewards)--
		TriggerEvent('mythic_notify:client:SendAlert', { type = 'inform', text = 'Kasa açıldı!'})
		
	else	
		PlaySoundFrontend(SoundID, "tumbler_reset", "SAFE_CRACK_SOUNDSET", true)
		TriggerEvent('mythic_notify:client:SendAlert', { type = 'error', text = 'Kasayı açamadın!'})
	end
	shopid = nil
	robstarted = false
	robx = nil
	roby = nil
	robz = nil
end

function OpenSafeDoor()
	local objs = ESX.Game.GetObjects()
	local doorHash = JUtils.GetHashKey("bkr_prop_biker_safedoor_01a")
	for k,v in pairs(objs) do
		if (GetEntityModel(v)%0x100000000) == doorHash then 

			local doorHeading = GetEntityPhysicsHeading(v)
			local doorPosition = GetEntityCoords(v)

			SetEntityCollision(v, false, false)
			FreezeEntityPosition(v, false)

			local targetHeading = doorHeading + 150

			while doorHeading + 150 > GetEntityHeading(v) do		
				SetEntityHeading(v, GetEntityHeading(v) + 0.3)
				SetEntityCoords(v, doorPosition, false, false, false, false)
				Citizen.Wait(0)
			end

			if not (GetEntityHeading(v) >= targetHeading) then 
				SetEntityHeading(v, targetHeading)
			end
		end
	end
end